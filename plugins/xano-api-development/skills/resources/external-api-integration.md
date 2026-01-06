# External API Integration

Strategies and patterns for integrating third-party APIs in Xano.

---

## Table of Contents

- [Integration Architecture](#integration-architecture)
- [API Client Patterns](#api-client-patterns)
- [Timeout Handling](#timeout-handling)
- [Rate Limiting](#rate-limiting)
- [Response Caching](#response-caching)
- [Error Recovery](#error-recovery)

---

## Integration Architecture

### Centralized API Client Pattern (Recommended)

Create reusable functions for each external service.

**Structure:**
```
Functions:
├── stripe_api_call(endpoint, method, data)
├── sendgrid_api_call(endpoint, method, data)
├── openai_api_call(endpoint, method, data)
└── shopify_api_call(endpoint, method, data)

Each handles:
- Authentication
- Request formatting
- Error handling
- Response extraction
- Timeout handling
```

**Benefits:**
- Single source of truth for API calls
- Consistent error handling
- Easy to add logging/monitoring
- Simple to update API versions

### Example: Stripe API Client

```javascript
// Function: stripe_api_call
function_endpoint
  .input('endpoint', 'text')       // e.g., '/charges'
  .input('method', 'text')         // GET, POST, etc.
  .input('data', 'object')         // Request body

  // Build full URL
  .var('base_url', 'https://api.stripe.com/v1')
  .var('url', '$base_url + $endpoint')

  // Get API key from env
  .var('api_key', process.env.STRIPE_SECRET_KEY)

  // Make API call
  .api(
    '$url',
    '$method',
    {
      headers: {
        'Authorization': 'Bearer $api_key',
        'Content-Type': 'application/json'
      },
      body: '$data',
      timeout: 30000  // 30 second timeout
    }
  )

  // Extract response
  .var('status', '$result.response.status')
  .var('body', '$result.response.result')

  // Handle errors
  .conditional('$status >= 400')
    .then((e) => {
      e.throw('STRIPE_ERROR', {
        status: '$status',
        error: '$body.error',
        endpoint: '$endpoint'
      })
    })
  .endConditional()

  // Return successful response
  .return({
    data: '$body',
    status: '$status'
  });
```

**Usage in Endpoints:**

```javascript
// Endpoint: POST /payments/charge
endpoint
  .input('amount', 'number')
  .input('payment_method', 'text')

  // Call Stripe via centralized function
  .call('stripe_api_call', {
    endpoint: '/charges',
    method: 'POST',
    data: {
      amount: '$amount',
      currency: 'usd',
      payment_method: '$payment_method'
    }
  })

  // Use response
  .var('charge', '$result.data')
  .respond({charge: '$charge'});
```

---

## API Client Patterns

### Pattern 1: Simple Wrapper

For straightforward APIs:

```javascript
// Function: call_weather_api
function_endpoint
  .input('city', 'text')

  .var('api_key', process.env.WEATHER_API_KEY)
  .var('url', 'https://api.weatherapi.com/v1/current.json?key=$api_key&q=$city')

  .api('$url', 'GET', {timeout: 10000})

  .return({
    temperature: '$result.response.result.current.temp_f',
    condition: '$result.response.result.current.condition.text'
  });
```

### Pattern 2: Authenticated Client

For APIs requiring auth tokens:

```javascript
// Function: call_shopify_api
function_endpoint
  .input('endpoint', 'text')
  .input('method', 'text')
  .input('data', 'object')

  // Get credentials
  .var('shop', process.env.SHOPIFY_SHOP)
  .var('token', process.env.SHOPIFY_ACCESS_TOKEN)
  .var('url', 'https://$shop.myshopify.com/admin/api/2024-01$endpoint')

  .api(
    '$url',
    '$method',
    {
      headers: {
        'X-Shopify-Access-Token': '$token',
        'Content-Type': 'application/json'
      },
      body: '$data',
      timeout: 30000
    }
  )

  .var('status', '$result.response.status')
  .var('body', '$result.response.result')

  .conditional('$status >= 400')
    .then((e) => {
      e.throw('SHOPIFY_ERROR', '$body.errors')
    })
  .endConditional()

  .return({data: '$body', status: '$status'});
```

### Pattern 3: OAuth Client

For APIs using OAuth:

```javascript
// Function: call_google_api
function_endpoint
  .input('endpoint', 'text')
  .input('user_id', 'number')

  // Get user's OAuth token
  .queryOne('oauth_tokens', {user_id: '$user_id', provider: 'google'})

  // Check if token expired
  .conditional('$oauth_token.expires_at < $now')
    .then((e) => {
      // Refresh token
      e.call('refresh_google_token', {user_id: '$user_id'})
      e.var('access_token', '$result.access_token')
    })
  .else((e) => {
    e.var('access_token', '$oauth_token.access_token')
  })
  .endConditional()

  // Make API call
  .api(
    'https://www.googleapis.com$endpoint',
    'GET',
    {
      headers: {
        'Authorization': 'Bearer $access_token'
      },
      timeout: 15000
    }
  )

  .return({data: '$result.response.result'});
```

---

## Timeout Handling

### Problem: Xano Background Tasks Timeout

Xano background tasks have a **60-second execution limit**. Long API calls can timeout.

### Solution 1: Batch Processing

Break work into chunks:

```javascript
// Background Task: sync_products
task
  // Get all products needing sync
  .query('products', {needs_sync: true})

  // Process in batches of 10
  .var('batch_size', 10)
  .var('processed', 0)

  .while('$processed < $products.length')
    .do((e) => {
      // Get batch
      e.var('batch', '$products.slice($processed, $processed + $batch_size)')

      // Process batch
      e.forEach('$batch', (e, product) => {
        e.call('sync_single_product', {product_id: '$product.id'})
      })

      // Update counter
      e.var('processed', '$processed + $batch_size')

      // Small delay to prevent rate limiting
      e.sleep(1)
    })
  .endWhile()

  .return({processed: '$processed'});
```

### Solution 2: Chain Tasks

Trigger next task before timeout:

```javascript
// Background Task: process_large_dataset
task
  .input('offset', 'number', {default: 0})
  .input('batch_size', 'number', {default: 100})

  // Get batch
  .query('items', {}, {offset: '$offset', limit: '$batch_size'})

  // Process batch
  .forEach('$items', (e, item) => {
    e.call('process_item', {item_id: '$item.id'})
  })

  // Check if more items exist
  .conditional('$items.length == $batch_size')
    .then((e) => {
      // More items to process, trigger next batch
      e.runBackgroundTask('process_large_dataset', {
        offset: '$offset + $batch_size',
        batch_size: '$batch_size'
      })
    })
  .endConditional()

  .return({processed: '$items.length', offset: '$offset'});
```

### Solution 3: Async + Polling

For very long operations:

```javascript
// Endpoint: POST /reports/generate
endpoint
  .input('report_type', 'text')

  // Trigger external API (async)
  .call('trigger_report_generation', {type: '$report_type'})

  // Save job ID
  .create('report_jobs', {
    external_job_id: '$result.job_id',
    status: 'pending',
    user_id: '$auth.user.id'
  })

  .respond({job_id: '$job.id', status: 'pending'});

// Background Task: poll_report_status (scheduled every 5 min)
task
  // Get pending jobs
  .query('report_jobs', {status: 'pending'})

  .forEach('$jobs', (e, job) => {
    // Check status with external API
    e.call('check_report_status', {job_id: '$job.external_job_id'})

    // Update if complete
    e.conditional('$result.status == "completed"')
      .then((e) => {
        e.update('report_jobs', '$job.id', {
          status: 'completed',
          result_url: '$result.download_url',
          completed_at: '$now'
        })
      })
    .endConditional()
  })

  .return({checked: '$jobs.length'});
```

---

## Rate Limiting

### Pattern: Respect API Rate Limits

Many APIs have rate limits (e.g., 100 requests/minute).

**Strategy 1: Add Delays**

```javascript
// Background Task: sync_customers
task
  .query('customers', {needs_sync: true})

  .forEach('$customers', (e, customer) => {
    // Sync customer
    e.call('sync_customer_to_crm', {customer_id: '$customer.id'})

    // Wait 600ms between calls (max 100/min)
    e.sleep(0.6)
  })

  .return({synced: '$customers.length'});
```

**Strategy 2: Track Rate Limits**

```javascript
// Function: rate_limited_api_call
function_endpoint
  .input('api_name', 'text')
  .input('endpoint', 'text')

  // Check current rate limit usage
  .queryOne('rate_limit_tracking', {api: '$api_name'})

  // If at limit, wait
  .conditional('$tracking.calls_this_minute >= $tracking.limit')
    .then((e) => {
      // Wait until next minute
      e.var('wait_seconds', 60 - ('$now - $tracking.minute_started'))
      e.sleep('$wait_seconds')

      // Reset counter
      e.update('rate_limit_tracking', '$tracking.id', {
        calls_this_minute: 0,
        minute_started: '$now'
      })
    })
  .endConditional()

  // Make API call
  .call('external_api_call', {endpoint: '$endpoint'})

  // Increment counter
  .update('rate_limit_tracking', '$tracking.id', {
    calls_this_minute: '$tracking.calls_this_minute + 1'
  })

  .return({data: '$result'});
```

---

## Response Caching

### Pattern: Cache API Responses

Reduce API calls and costs:

```javascript
// Function: get_exchange_rates (cached)
function_endpoint
  .input('base_currency', 'text')

  // Check cache (valid for 1 hour)
  .queryOne('api_cache', {
    key: 'exchange_rates_$base_currency',
    expires_at: {$gt: '$now'}
  })

  .conditional('$cache == null')
    .then((e) => {
      // Cache miss, call API
      e.call('external_api_call', {
        endpoint: '/latest?base=$base_currency'
      })

      // Store in cache
      e.create('api_cache', {
        key: 'exchange_rates_$base_currency',
        value: '$result.data',
        expires_at: '$now + 3600'  // 1 hour
      })

      e.var('rates', '$result.data')
    })
  .else((e) => {
    // Cache hit
    e.var('rates', '$cache.value')
  })
  .endConditional()

  .return({rates: '$rates', cached: '$cache != null'});
```

---

## Error Recovery

### Pattern: Graceful Degradation

Handle API failures without breaking user experience:

```javascript
// Endpoint: GET /products/{id}
endpoint
  .input('id', 'number')

  // Get product from database
  .queryOne('products', {id: '$id'})

  // Try to enrich with live inventory from external API
  .conditional('true')
    .then((e) => {
      e.call('get_live_inventory', {sku: '$product.sku'})
      e.var('inventory', '$result.quantity')
    })
    .catch((e) => {
      // API failed, use cached inventory
      e.var('inventory', '$product.cached_inventory')
      e.var('inventory_stale', true)
    })
  .endConditional()

  .respond({
    product: '$product',
    inventory: '$inventory',
    inventory_stale: '$inventory_stale || false'
  });
```

### Pattern: Retry with Exponential Backoff

```javascript
// Function: resilient_api_call
function_endpoint
  .input('endpoint', 'text')
  .input('max_retries', 'number', {default: 3})

  .var('attempt', 0)
  .var('success', false)
  .var('result', null)

  .while('$attempt < $max_retries && !$success')
    .do((e) => {
      e.var('attempt', '$attempt + 1')

      e.conditional('true')
        .then((e) => {
          e.call('external_api_call', {endpoint: '$endpoint'})
          e.var('result', '$result')
          e.var('success', true)
        })
        .catch((e) => {
          // Wait before retry (exponential backoff)
          e.conditional('$attempt < $max_retries')
            .then((e) => {
              e.var('wait', 'Math.pow(2, $attempt)')  // 2s, 4s, 8s
              e.sleep('$wait')
            })
          .endConditional()
        })
      .endConditional()
    })
  .endWhile()

  .conditional('!$success')
    .then((e) => {
      e.throw('API_FAILED', 'Max retries exceeded')
    })
  .endConditional()

  .return({data: '$result'});
```

---

## Best Practices

### Do's:
✅ Centralize API clients in functions
✅ Handle timeouts gracefully
✅ Implement retry logic for transient failures
✅ Cache responses when appropriate
✅ Respect rate limits
✅ Log API errors for debugging
✅ Use environment variables for credentials
✅ Validate API responses

### Don'ts:
❌ Don't hardcode API keys
❌ Don't ignore timeout errors
❌ Don't make unbounded API calls in loops
❌ Don't skip error handling
❌ Don't assume API is always available
❌ Don't cache sensitive data indefinitely
❌ Don't exceed rate limits

---

**Back to:** [SKILL.md](SKILL.md)
