# Background Tasks

Comprehensive guide to background task patterns in Xano for long-running and scheduled operations.

---

## Table of Contents

- [What Are Background Tasks](#what-are-background-tasks)
- [When to Use Background Tasks](#when-to-use-background-tasks)
- [Task Patterns](#task-patterns)
- [Error Handling & Retries](#error-handling--retries)
- [Status Tracking](#status-tracking)
- [Scheduling Strategies](#scheduling-strategies)

---

## What Are Background Tasks

Background tasks are special Xano functions that run asynchronously, separate from endpoint execution.

**Key Characteristics:**
- Run independently from API requests
- Can be triggered manually or scheduled
- Don't block endpoint responses
- Can run for extended periods
- Support retry logic
- Can be monitored for status

**Differences from Regular Functions:**
- Functions: Synchronous, return immediately, blocking
- Background Tasks: Asynchronous, non-blocking, can take minutes/hours

---

## When to Use Background Tasks

### Use Background Tasks When:

✅ **Operation takes > 30 seconds**
```
Examples:
- Sending bulk emails
- Generating reports
- Processing large files
- Syncing external data
```

✅ **User doesn't need to wait**
```
Examples:
- Welcome email after registration
- Order confirmation email
- Invoice generation
- Data export
```

✅ **Periodic/scheduled work**
```
Examples:
- Daily report generation
- Hourly inventory sync
- Weekly cleanup tasks
- Monthly billing
```

✅ **Webhook processing**
```
Examples:
- Stripe webhook events
- SendGrid delivery notifications
- Payment confirmations
```

### DON'T Use Background Tasks When:

❌ **User needs immediate response**
```
Bad: Login validation
Bad: Form submission that shows results
Bad: Search queries
```

❌ **Operation is fast (< 5 seconds)**
```
Unnecessary overhead for quick operations
Just use regular endpoint logic
```

❌ **Real-time updates required**
```
Use WebSockets or polling instead
Background tasks are for async work
```

---

## Task Patterns

### Pattern 1: Post-Action Processing

**Use Case:** Process work after endpoint returns success

**Example: Order Confirmation**

```javascript
// Endpoint: POST /checkout
endpoint
  .input('cart_items', 'array')
  .input('payment_method', 'text')

  // Process payment
  .call('process_payment', {items: '$cart_items', method: '$payment_method'})

  // Create order
  .create('orders', {
    user_id: '$auth.user.id',
    items: '$cart_items',
    total: '$payment.amount',
    status: 'pending'
  })

  // Trigger background task (non-blocking)
  .runBackgroundTask('process_order_fulfillment', {order_id: '$order.id'})

  // Return immediately (don't wait for background task)
  .respond({order: '$order', message: 'Order created'});

// Background Task: process_order_fulfillment
task
  .input('order_id', 'number')

  // Update inventory
  .call('update_inventory', {order_id: '$order_id'})

  // Send confirmation email
  .call('send_order_confirmation', {order_id: '$order_id'})

  // Notify warehouse
  .call('notify_warehouse', {order_id: '$order_id'})

  // Update order status
  .update('orders', '$order_id', {status: 'processing', processed_at: '$now'})

  .return({success: true});
```

**Benefits:**
- User gets instant response
- Heavy work happens in background
- Order is created fast, processing happens async

### Pattern 2: Scheduled Jobs

**Use Case:** Regular maintenance, periodic sync, scheduled reports

**Example: Daily Inventory Sync**

```javascript
// Background Task: sync_inventory (scheduled hourly)
task
  // Get products needing sync
  .query('products', {last_synced: {$lt: '$now - 1 hour'}})

  // For each product
  .forEach('$products', (e, product) => {
    // Call external API
    e.call('get_warehouse_inventory', {sku: '$product.sku'})

    // Update product
    e.update('products', '$product.id', {
      inventory: '$result.quantity',
      last_synced: '$now'
    })
  })

  // Log completion
  .create('sync_logs', {
    type: 'inventory',
    products_updated: '$products.length',
    completed_at: '$now'
  })

  .return({synced: '$products.length'});
```

**Scheduling:**
- Set up in Xano dashboard
- Cron-like schedule (hourly, daily, weekly)
- Manual trigger available

### Pattern 3: Bulk Operations

**Use Case:** Process large datasets, batch operations

**Example: Bulk Email Campaign**

```javascript
// Endpoint: POST /campaigns/{id}/send
endpoint
  .input('id', 'number')

  // Get campaign
  .queryOne('campaigns', {id: '$id'})

  // Trigger background task
  .runBackgroundTask('send_campaign_emails', {campaign_id: '$id'})

  // Return immediately
  .respond({message: 'Campaign sending started', campaign: '$campaign'});

// Background Task: send_campaign_emails
task
  .input('campaign_id', 'number')

  // Get campaign
  .queryOne('campaigns', {id: '$campaign_id'})

  // Get recipients (could be thousands)
  .query('campaign_recipients', {campaign_id: '$campaign_id', status: 'pending'})

  // Process in batches of 100
  .var('batch_size', 100)
  .var('total', '$recipients.length')
  .var('sent', 0)

  .forEach('$recipients', (e, recipient) => {
    // Send email
    e.call('send_email_via_sendgrid', {
      to: '$recipient.email',
      template: '$campaign.template_id',
      data: '$recipient.merge_data'
    })

    // Update recipient status
    e.update('campaign_recipients', '$recipient.id', {
      status: 'sent',
      sent_at: '$now'
    })

    // Update counter
    e.var('sent', '$sent + 1')

    // Update campaign progress every 100
    e.conditional('$sent % 100 == 0')
      .then((e) => {
        e.update('campaigns', '$campaign_id', {
          progress: '$sent / $total',
          updated_at: '$now'
        })
      })
      .endConditional()
  })

  // Mark campaign complete
  .update('campaigns', '$campaign_id', {
    status: 'completed',
    completed_at: '$now',
    total_sent: '$sent'
  })

  .return({sent: '$sent'});
```

### Pattern 4: Webhook Processing

**Use Case:** Process external webhooks asynchronously

**Example: Stripe Webhook Handler**

```javascript
// Endpoint: POST /webhooks/stripe
endpoint
  .input('event', 'object')

  // Validate webhook signature (synchronous)
  .call('validate_stripe_signature', {event: '$event'})

  // Immediately respond 200 OK (Stripe requires fast response)
  .respond({received: true})

  // Process in background (after response sent)
  .runBackgroundTask('process_stripe_event', {event: '$event'});

// Background Task: process_stripe_event
task
  .input('event', 'object')

  // Parse event type
  .var('event_type', '$event.type')

  // Route to appropriate handler
  .conditional('$event_type == "payment_intent.succeeded"')
    .then((e) => {
      e.call('handle_payment_success', {payment: '$event.data.object'})
    })
  .elseConditional('$event_type == "payment_intent.failed"')
    .then((e) => {
      e.call('handle_payment_failure', {payment: '$event.data.object'})
    })
  .elseConditional('$event_type == "customer.subscription.deleted"')
    .then((e) => {
      e.call('handle_subscription_canceled', {subscription: '$event.data.object'})
    })
  .endConditional()

  // Log event processing
  .create('webhook_logs', {
    provider: 'stripe',
    event_type: '$event_type',
    processed_at: '$now',
    success: true
  })

  .return({processed: true});
```

**Why Background Task:**
- Webhook endpoints must respond quickly (< 5s)
- Processing may involve multiple API calls
- Prevents timeout issues

---

## Error Handling & Retries

### Basic Error Handling

```javascript
// Background Task: send_notification
task
  .input('user_id', 'number')
  .input('message', 'text')

  // Try to send email
  .var('email_sent', false)
  .conditional('$user.email != null')
    .then((e) => {
      e.call('send_email', {to: '$user.email', message: '$message'})
      e.var('email_sent', true)
    })
    .catch((e) => {
      // Log error
      e.create('error_logs', {
        task: 'send_notification',
        error: '$error.message',
        user_id: '$user_id'
      })
      e.var('email_sent', false)
    })
  .endConditional()

  // Fallback to SMS if email failed
  .conditional('!$email_sent && $user.phone != null')
    .then((e) => {
      e.call('send_sms', {to: '$user.phone', message: '$message'})
    })
  .endConditional()

  .return({success: true});
```

### Retry Logic Pattern

```javascript
// Background Task: sync_with_external_api
task
  .input('resource_id', 'number')

  .var('max_attempts', 3)
  .var('attempt', 0)
  .var('success', false)

  // Retry loop
  .while('$attempt < $max_attempts && !$success')
    .do((e) => {
      e.var('attempt', '$attempt + 1')

      // Try API call
      e.conditional('true')
        .then((e) => {
          e.call('call_external_api', {id: '$resource_id'})
          e.var('success', true)
        })
        .catch((e) => {
          // Log attempt
          e.create('retry_logs', {
            task: 'sync_with_external_api',
            attempt: '$attempt',
            error: '$error.message'
          })

          // Wait before retry (exponential backoff)
          e.conditional('$attempt < $max_attempts')
            .then((e) => {
              e.var('wait_seconds', '$attempt * 5')  // 5s, 10s, 15s
              e.sleep('$wait_seconds')
            })
          .endConditional()
        })
      .endConditional()
    })
  .endWhile()

  // Check final result
  .conditional('!$success')
    .then((e) => {
      e.create('failed_tasks', {
        task: 'sync_with_external_api',
        resource_id: '$resource_id',
        attempts: '$attempt',
        failed_at: '$now'
      })
    })
  .endConditional()

  .return({success: '$success', attempts: '$attempt'});
```

---

## Status Tracking

### Pattern: Task Status Table

**Database Schema:**
```
Table: background_task_status
├── id (auto-increment)
├── task_name (text)
├── task_id (text, unique)
├── status (enum: pending, running, completed, failed)
├── progress (number, 0-100)
├── started_at (datetime)
├── completed_at (datetime)
├── error (text)
└── result (json)
```

**Endpoint: Trigger Task**
```javascript
// POST /reports/generate
endpoint
  .input('report_type', 'text')

  // Create status record
  .create('background_task_status', {
    task_name: 'generate_report',
    task_id: '$uuid',
    status: 'pending',
    started_at: '$now'
  })

  // Trigger background task
  .runBackgroundTask('generate_report', {
    task_id: '$task_status.task_id',
    report_type: '$report_type'
  })

  // Return task ID for status checking
  .respond({task_id: '$task_status.task_id', status: 'pending'});
```

**Background Task: Update Status**
```javascript
// Background Task: generate_report
task
  .input('task_id', 'text')
  .input('report_type', 'text')

  // Update to running
  .update('background_task_status', {task_id: '$task_id'}, {
    status: 'running',
    progress: 0
  })

  // Generate report (with progress updates)
  .var('total_steps', 5)
  .var('current_step', 0)

  // Step 1: Fetch data
  .query('orders', {created_at: {$gte: '$last_month'}})
  .var('current_step', 1)
  .update('background_task_status', {task_id: '$task_id'}, {
    progress: '$current_step / $total_steps * 100'
  })

  // Step 2: Calculate metrics
  .call('calculate_report_metrics', {data: '$orders'})
  .var('current_step', 2)
  .update('background_task_status', {task_id: '$task_id'}, {
    progress: '$current_step / $total_steps * 100'
  })

  // ... more steps ...

  // Mark complete
  .update('background_task_status', {task_id: '$task_id'}, {
    status: 'completed',
    progress: 100,
    completed_at: '$now',
    result: '$report_data'
  })

  .return({success: true});
```

**Endpoint: Check Status**
```javascript
// GET /tasks/{id}/status
endpoint
  .input('id', 'text')
  .queryOne('background_task_status', {task_id: '$id'})
  .respond({
    status: '$result.status',
    progress: '$result.progress',
    started_at: '$result.started_at',
    completed_at: '$result.completed_at'
  });
```

---

## Scheduling Strategies

### Manual Trigger (Most Common)

Triggered by endpoint, runs immediately:

```javascript
endpoint
  .runBackgroundTask('my_task', {param: 'value'})
  .respond({started: true});
```

### Scheduled (Cron-like)

Set in Xano dashboard:
- Hourly: `0 * * * *`
- Daily at 2am: `0 2 * * *`
- Weekly Monday 9am: `0 9 * * 1`
- Monthly 1st at midnight: `0 0 1 * *`

### Conditional Scheduling

Run task only when conditions met:

```javascript
// Background Task: daily_cleanup (scheduled daily)
task
  // Only run if needed
  .query('temp_files', {created_at: {$lt: '$now - 7 days'}})

  .conditional('$temp_files.length > 0')
    .then((e) => {
      // Perform cleanup
      e.forEach('$temp_files', (e, file) => {
        e.delete('temp_files', '$file.id')
      })
    })
  .else((e) => {
    // Skip, nothing to clean
    e.return({skipped: true})
  })
  .endConditional()

  .return({cleaned: '$temp_files.length'});
```

---

## Best Practices

### Do's:
✅ Keep tasks focused (single responsibility)
✅ Update status/progress for long tasks
✅ Log errors for debugging
✅ Implement retry logic for external APIs
✅ Return immediately from trigger endpoint
✅ Use background tasks for > 30s operations

### Don'ts:
❌ Don't make users wait for background tasks
❌ Don't skip error handling
❌ Don't process webhooks synchronously
❌ Don't run infinite loops
❌ Don't forget to log completion

---

**Back to:** [SKILL.md](SKILL.md)
