# Endpoints vs Functions

Detailed decision framework for when to use endpoints vs functions in Xano.

---

## Table of Contents

- [Key Differences](#key-differences)
- [When to Use Each](#when-to-use-each)
- [Decision Framework](#decision-framework)
- [Code Organization Patterns](#code-organization-patterns)
- [Refactoring Strategies](#refactoring-strategies)
- [Performance Considerations](#performance-considerations)

---

## Key Differences

### Endpoints

**Characteristics:**
- Has a URL path (e.g., `/users/123`)
- Has HTTP method (GET, POST, PATCH, DELETE)
- Accessible from outside Xano
- Can be called by frontend, mobile apps, webhooks
- Returns HTTP response with status codes
- Handles authentication and authorization
- Validates external input

**Purpose:**
- External API interface
- Orchestration layer
- Request/response handling

### Functions

**Characteristics:**
- No URL (internal only)
- Called from endpoints or other functions
- Cannot be accessed externally
- Returns data directly (no HTTP wrapper)
- Reusable across multiple endpoints
- Pure business logic

**Purpose:**
- Reusable logic
- Business rules
- Data transformations
- Internal utilities

---

## When to Use Each

### Use an Endpoint When:

✅ **External access required**
```
Frontend needs to call it
Mobile app needs to call it
Webhook will trigger it
Third-party service will call it
```

✅ **Top-level orchestration**
```
Combines multiple functions
Handles auth + validation + logic + response
Entry point for a user action
```

✅ **HTTP-specific needs**
```
Needs specific status codes (404, 400, 500)
Different responses for different HTTP methods
RESTful API design
```

**Examples:**
- `POST /users` - Create user account
- `GET /orders/{id}` - Get order details
- `POST /webhooks/stripe` - Process Stripe webhook
- `POST /checkout` - Complete order

### Use a Function When:

✅ **Logic is reused**
```
Multiple endpoints need same calculation
Same validation used in different contexts
Common data transformation
```

✅ **Single responsibility**
```
Does one thing well
Pure business logic
Easy to test
No external dependencies
```

✅ **Internal utility**
```
Helper for data formatting
Calculation that's used repeatedly
Validation rule
Data transformation
```

**Examples:**
- `calculate_order_total(items, shipping, tax)` - Used by checkout, order update, admin
- `validate_email(email)` - Used by registration, profile update
- `format_user_response(user)` - Used by login, get profile, list users
- `generate_unique_code(length)` - Used by various endpoints

---

## Decision Framework

### Question 1: Will it be called from outside Xano?

```
YES → ENDPOINT
NO  → Continue to Question 2
```

### Question 2: Is the logic used by multiple endpoints?

```
YES → FUNCTION
NO  → Continue to Question 3
```

### Question 3: Is it complex enough to extract?

```
YES → Consider FUNCTION for readability
NO  → Keep in ENDPOINT
```

### Decision Tree Diagram

```
Need new logic?
│
├─ Called from outside? (frontend, mobile, webhook)
│  ├─ YES → CREATE ENDPOINT
│  └─ NO
│     │
│     └─ Used by multiple endpoints?
│        ├─ YES → CREATE FUNCTION
│        └─ NO
│           │
│           └─ Complex logic (>20 lines)?
│              ├─ YES → Consider FUNCTION for clarity
│              └─ NO → Put directly in ENDPOINT
```

---

## Code Organization Patterns

### Pattern 1: Thin Endpoints, Fat Functions

**Best for:** Complex business logic, reusable operations

**Endpoint:**
```javascript
// POST /orders/checkout
endpoint
  .input('cart_items', 'array')
  .input('payment_method', 'text')
  .input('shipping_address', 'object')

  // Validate input
  .precondition('$cart_items.length > 0', 'Cart is empty', 400)

  // Check auth
  .requireAuth()

  // Call functions for business logic
  .call('validate_cart', {cart: '$cart_items'})
  .call('calculate_total', {items: '$cart_items'})
  .call('process_payment', {amount: '$total', method: '$payment_method'})
  .call('create_order', {user_id: '$auth.user.id', items: '$cart_items'})
  .call('send_confirmation', {order_id: '$order.id'})

  // Return response
  .respond({order: '$order', total: '$total'});
```

**Functions:**
```javascript
// Function: validate_cart
function_endpoint
  .input('cart', 'array')
  // Validation logic
  .return({valid: true, items: '$validated_items'});

// Function: calculate_total
function_endpoint
  .input('items', 'array')
  // Calculation logic
  .return({total: '$total', breakdown: '$breakdown'});

// Function: process_payment
function_endpoint
  .input('amount', 'number')
  .input('method', 'text')
  // Payment processing
  .return({transaction_id: '$id', status: '$status'});
```

**Benefits:**
- Each function is testable independently
- Functions are reusable (admin can also create orders)
- Endpoint is easy to read (orchestration only)
- Easy to modify business logic without touching endpoint

### Pattern 2: Self-Contained Endpoints

**Best for:** Simple operations, endpoint-specific logic

**Endpoint:**
```javascript
// GET /users/{id}
endpoint
  .input('id', 'number')
  .requireAuth()
  .precondition('$id == $auth.user.id || $auth.user.role == "admin"', 'Unauthorized', 403)
  .query('users', {id: '$id'})
  .respond({user: '$result'});
```

**When to use:**
- Logic is simple (< 20 lines)
- Not reused anywhere else
- Endpoint-specific concerns

### Pattern 3: Hybrid Approach (Recommended)

Combine both patterns based on complexity:

```javascript
// POST /users/update-profile
endpoint
  .input('name', 'text')
  .input('email', 'email')
  .input('phone', 'text')

  .requireAuth()

  // Simple validation inline
  .precondition('$name.length > 0', 'Name required', 400)

  // Complex validation in function
  .call('validate_email', {email: '$email'})
  .call('check_email_availability', {email: '$email', user_id: '$auth.user.id'})

  // Simple update inline
  .update('users', '$auth.user.id', {
    name: '$name',
    email: '$email',
    phone: '$phone',
    updated_at: '$now'
  })

  // Complex formatting in function
  .call('format_user_response', {user: '$result'})

  .respond({user: '$formatted_user'});
```

---

## Refactoring Strategies

### When to Extract to Function

Extract logic to function when:
- Same code appears in 2+ endpoints
- Endpoint gets > 30 lines
- Logic has clear single responsibility
- You need to test logic independently

### Refactoring Example

**Before (Duplicated Logic):**

```javascript
// Endpoint 1: POST /orders/checkout
endpoint
  .var('subtotal', 0)
  .forEach('$cart_items', (e, item) => {
    e.var('subtotal', '$subtotal + ($item.price * $item.quantity)');
  })
  .var('tax', '$subtotal * 0.08')
  .var('shipping', '$subtotal > 50 ? 0 : 5.99')
  .var('total', '$subtotal + $tax + $shipping')
  // ... rest of checkout

// Endpoint 2: GET /cart/preview
endpoint
  .var('subtotal', 0)
  .forEach('$cart_items', (e, item) => {
    e.var('subtotal', '$subtotal + ($item.price * $item.quantity)');
  })
  .var('tax', '$subtotal * 0.08')
  .var('shipping', '$subtotal > 50 ? 0 : 5.99')
  .var('total', '$subtotal + $tax + $shipping')
  // ... show preview
```

**After (Extracted to Function):**

```javascript
// Function: calculate_order_total
function_endpoint
  .input('items', 'array')
  .var('subtotal', 0)
  .forEach('$items', (e, item) => {
    e.var('subtotal', '$subtotal + ($item.price * $item.quantity)');
  })
  .var('tax', '$subtotal * 0.08')
  .var('shipping', '$subtotal > 50 ? 0 : 5.99')
  .var('total', '$subtotal + $tax + $shipping')
  .return({
    subtotal: '$subtotal',
    tax: '$tax',
    shipping: '$shipping',
    total: '$total'
  });

// Endpoint 1: POST /orders/checkout
endpoint
  .call('calculate_order_total', {items: '$cart_items'})
  .var('total', '$result.total')
  // ... rest of checkout

// Endpoint 2: GET /cart/preview
endpoint
  .call('calculate_order_total', {items: '$cart_items'})
  .var('totals', '$result')
  // ... show preview
```

**Benefits:**
- Single source of truth for calculation
- Easy to modify (change in one place)
- Testable independently
- Can add discount logic in one place

---

## Performance Considerations

### Function Call Overhead

**Minimal:** Function calls in Xano are fast
- Calling a function adds ~1-5ms overhead
- Much better than duplicated code
- Premature optimization is the root of all evil

**When to inline:**
- Extremely simple logic (1-2 lines)
- Performance-critical hot path
- Logic is genuinely unique to one endpoint

### Example: When NOT to Extract

```javascript
// DON'T extract this to function (too simple)
endpoint
  .var('full_name', '$first_name + " " + $last_name')
  .respond({name: '$full_name'});

// This is fine inline
```

### Example: When TO Extract

```javascript
// DO extract this (complex, reusable)
function: calculate_shipping_cost
  .input('items', 'array')
  .input('destination', 'object')
  .var('weight', 0)
  .forEach('$items', (e, item) => {
    e.var('weight', '$weight + $item.weight');
  })
  .var('zone', /* complex zone calculation */)
  .var('base_rate', /* rate lookup */)
  .var('cost', '$base_rate * $weight')
  .return({cost: '$cost', zone: '$zone'});
```

---

## Common Patterns

### Pattern: CRUD Operations

**Structure:**
```
Endpoints (external interface):
├── POST   /users          → create_user_endpoint
├── GET    /users/{id}     → get_user_endpoint
├── PATCH  /users/{id}     → update_user_endpoint
└── DELETE /users/{id}     → delete_user_endpoint

Functions (shared logic):
├── validate_user_input()
├── format_user_response()
└── check_user_permissions()
```

### Pattern: Multi-Step Workflow

**Structure:**
```
Endpoint (orchestration):
POST /orders/checkout
├── validate_cart()           [function]
├── calculate_totals()        [function]
├── process_payment()         [function]
├── create_order_record()     [function]
└── send_confirmation()       [function]
```

### Pattern: Webhook Processing

**Structure:**
```
Endpoint (entry point):
POST /webhooks/stripe
├── validate_signature()      [function]
├── Trigger background task
└── Return 200 OK

Background Task (processing):
process_stripe_webhook
├── parse_event()             [function]
├── handle_payment_success()  [function]
└── update_order_status()     [function]
```

---

## Testing Approach

### Testing Endpoints

**Test via HTTP calls:**
```bash
# Test endpoint
curl -X POST https://x123.xano.io/api:v1/checkout \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"cart_items": [...], "payment_method": "card"}'
```

**What to test:**
- Auth works correctly
- Input validation
- HTTP status codes
- Response format

### Testing Functions

**Test by calling from test endpoint:**
```javascript
// Create test endpoint: POST /test/calculate-total
endpoint
  .input('items', 'array')
  .call('calculate_order_total', {items: '$items'})
  .respond({result: '$result'});
```

```bash
# Test function via test endpoint
curl -X POST https://x123.xano.io/api:v1/test/calculate-total \
  -d '{"items": [{"price": 10, "quantity": 2}]}'
```

**What to test:**
- Calculation accuracy
- Edge cases
- Error handling

---

## Best Practices Summary

### Endpoints Should:
✅ Handle external interface (URLs, HTTP methods)
✅ Manage authentication and authorization
✅ Validate input from untrusted sources
✅ Orchestrate functions
✅ Format responses
✅ Return proper HTTP status codes

### Functions Should:
✅ Contain reusable business logic
✅ Have clear input/output contracts
✅ Be pure (same inputs = same outputs)
✅ Have single responsibility
✅ Be easy to test
✅ Have descriptive names

### Anti-Patterns:
❌ Functions that handle auth (do in endpoint)
❌ Endpoints with duplicate logic (extract to function)
❌ Functions that return HTTP responses (use endpoints)
❌ Over-extracting (every 2 lines in a function)
❌ Under-extracting (500-line endpoint)

---

## Quick Reference

| Scenario | Use Endpoint | Use Function |
|----------|-------------|--------------|
| Frontend needs to call it | ✅ | ❌ |
| Logic used by 3+ endpoints | ❌ | ✅ |
| Handles authentication | ✅ | ❌ |
| Pure calculation | ❌ | ✅ |
| Returns HTTP status codes | ✅ | ❌ |
| Data transformation | ❌ | ✅ |
| Webhook receiver | ✅ | ❌ |
| Reusable validation | ❌ | ✅ |

---

**Back to:** [SKILL.md](SKILL.md)
