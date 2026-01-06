# Workspace Organization

Complete guide to organizing Xano workspaces for maintainability and scalability.

---

## Table of Contents

- [Core Principles](#core-principles)
- [API Group Strategies](#api-group-strategies)
- [Naming Conventions](#naming-conventions)
- [Folder Structure Examples](#folder-structure-examples)
- [Documentation Practices](#documentation-practices)
- [Migration & Refactoring](#migration--refactoring)

---

## Core Principles

### 1. Organize by Business Domain

Group endpoints by the business concept they manage, not by technical characteristics.

**Good - Domain-Based:**
```
API Groups:
├── users/              All user management
├── authentication/     Auth endpoints
├── products/          Product catalog
├── orders/            Order processing
├── payments/          Payment handling
├── notifications/     Email/SMS/push
└── analytics/         Reporting & metrics
```

**Bad - Technical Grouping:**
```
API Groups:
├── get-endpoints/
├── post-endpoints/
├── functions/
└── utilities/
```

**Why:** Domain-based grouping makes it easy to find related functionality and understand the system's capabilities at a glance.

### 2. Keep Related Code Together

All endpoints and functions for a domain should live in the same API group.

**Example: Orders API Group**
```
orders/
├── Endpoints:
│   ├── POST   /checkout              (Create order)
│   ├── GET    /                      (List orders)
│   ├── GET    /{id}                  (Get order)
│   ├── PATCH  /{id}/status           (Update status)
│   └── POST   /{id}/refund           (Process refund)
│
└── Functions:
    ├── calculate_order_total()
    ├── validate_order_items()
    ├── check_inventory()
    └── generate_order_number()
```

### 3. Use Clear, Descriptive Names

Names should indicate purpose without needing to read the code.

**Good:**
- `send_welcome_email`
- `validate_credit_card`
- `calculate_shipping_cost`
- `process_stripe_webhook`

**Bad:**
- `helper1`
- `temp_function`
- `do_stuff`
- `api_endpoint`

---

## API Group Strategies

### Strategy 1: Resource-Based (REST)

Best for: CRUD applications, standard APIs

```
users/
├── GET    /users              List
├── POST   /users              Create
├── GET    /users/{id}         Read
├── PATCH  /users/{id}         Update
└── DELETE /users/{id}         Delete

products/
├── GET    /products
├── POST   /products
├── GET    /products/{id}
├── PATCH  /products/{id}
└── DELETE /products/{id}
```

**Benefits:**
- Predictable URL structure
- Standard HTTP methods
- Easy to document
- Familiar to developers

### Strategy 2: Action-Based

Best for: Complex workflows, non-CRUD operations

```
orders/
├── POST   /checkout              (Complete checkout)
├── POST   /{id}/cancel           (Cancel order)
├── POST   /{id}/ship             (Mark as shipped)
├── POST   /{id}/refund           (Process refund)
└── POST   /{id}/resend-receipt   (Resend email)
```

**Benefits:**
- Clear intent
- Better for complex operations
- Easier to add business logic

### Strategy 3: Hybrid (Recommended)

Combine both approaches based on context.

```
products/
├── GET    /products              REST: List
├── POST   /products              REST: Create
├── GET    /products/{id}         REST: Read
├── PATCH  /products/{id}         REST: Update
└── POST   /products/import       Action: Bulk import

orders/
├── GET    /orders                REST: List
├── GET    /orders/{id}           REST: Read
├── POST   /checkout              Action: Create order
├── POST   /{id}/cancel           Action: Cancel
└── POST   /{id}/refund           Action: Refund
```

---

## Naming Conventions

### API Group Names

**Pattern:** Lowercase, plural nouns

```
✅ users
✅ products
✅ orders
✅ notifications

❌ Users (capitalized)
❌ user (singular)
❌ User-Management (hyphens)
```

### Endpoint Names

**Pattern:** Lowercase, hyphens for multi-word

```
✅ /checkout
✅ /send-email
✅ /calculate-shipping

❌ /CheckOut (camelCase)
❌ /send_email (underscores)
```

### Function Names

**Pattern:** snake_case, verb_noun format

```
✅ calculate_order_total
✅ send_welcome_email
✅ validate_credit_card
✅ format_user_response

❌ calculateOrderTotal (camelCase in Xano)
❌ calc_total (unclear abbreviation)
❌ order_total (no verb)
```

### Background Task Names

**Pattern:** snake_case, descriptive of action

```
✅ process_order_fulfillment
✅ send_daily_digest_emails
✅ sync_inventory_with_warehouse
✅ cleanup_expired_sessions

❌ task1 (not descriptive)
❌ background_job (too generic)
```

---

## Folder Structure Examples

### Small Project (< 10 API Groups)

```
API Groups:
├── authentication/
│   ├── POST /login
│   ├── POST /register
│   ├── POST /logout
│   └── POST /refresh-token
│
├── users/
│   ├── GET    /me
│   ├── PATCH  /me
│   ├── POST   /me/change-password
│   └── Functions: validate_user_input()
│
├── content/
│   ├── GET    /posts
│   ├── POST   /posts
│   ├── GET    /posts/{id}
│   └── Functions: format_post_response()
│
└── notifications/
    ├── POST /send-email
    └── Background: send_welcome_email
```

### Medium Project (10-30 API Groups)

```
API Groups:
├── Core/
│   ├── authentication/
│   ├── users/
│   └── permissions/
│
├── E-Commerce/
│   ├── products/
│   ├── cart/
│   ├── orders/
│   ├── payments/
│   └── shipping/
│
├── Content/
│   ├── posts/
│   ├── comments/
│   └── media/
│
├── Communications/
│   ├── email/
│   ├── sms/
│   └── push-notifications/
│
└── Analytics/
    ├── events/
    └── reports/
```

**Note:** Xano doesn't have folders, but use naming prefixes:
- `core_authentication`
- `core_users`
- `ecommerce_products`
- `ecommerce_orders`

### Large Project (30+ API Groups)

For very large projects, use clear prefixing strategy:

```
API Groups (with prefixes):
├── v1_public_users/           (Public API v1)
├── v1_public_products/
├── v1_public_orders/
│
├── v1_admin_users/            (Admin API v1)
├── v1_admin_analytics/
│
├── v2_public_users/           (Public API v2)
├── v2_public_products/
│
├── internal_webhooks/         (Internal only)
├── internal_background_tasks/
│
└── shared_utilities/          (Shared functions)
```

---

## Documentation Practices

### 1. API Group Descriptions

Always add descriptions to API groups:

```
API Group: orders
Description: Order management including checkout, payment processing,
             order tracking, and refund handling. Integrates with
             Stripe for payments and SendGrid for notifications.
```

### 2. Endpoint Descriptions

Document each endpoint's purpose:

```
Endpoint: POST /checkout
Description: Complete checkout process. Validates cart, processes payment,
             creates order, and sends confirmation email.
Input: cart_items[], payment_method, shipping_address
Output: order object with confirmation details
```

### 3. Function Documentation

Document inputs, outputs, and purpose:

```
Function: calculate_order_total
Description: Calculates order total including items, tax, shipping, discounts
Input:
  - items (array): Cart items with quantity and price
  - shipping_method (string): Selected shipping option
  - discount_code (string, optional): Applied discount code
Output:
  - total (number): Final order total
  - breakdown (object): Itemized cost breakdown
```

### 4. Background Task Documentation

Explain trigger conditions and purpose:

```
Background Task: process_order_fulfillment
Trigger: Manual (called from checkout endpoint after payment success)
Purpose: Handles post-payment order processing asynchronously
Steps:
  1. Update inventory
  2. Send confirmation email
  3. Notify warehouse
  4. Create shipping label
Retry: 3 attempts with exponential backoff
```

---

## Migration & Refactoring

### When to Refactor

Refactor workspace organization when:
- API groups have > 15 endpoints
- Endpoints are hard to find
- Similar logic exists in multiple places
- Naming is inconsistent
- New team members get confused

### How to Refactor Safely

1. **Plan the new structure** - Document desired organization
2. **Create new API groups** - Don't delete old ones yet
3. **Copy (don't move) endpoints** - Duplicate first
4. **Test new endpoints** - Verify functionality
5. **Update frontend** - Point to new URLs
6. **Mark old endpoints deprecated** - Add warnings
7. **Monitor usage** - Track old endpoint calls
8. **Delete old endpoints** - After confirmed unused

### Example Refactoring

**Before:**
```
api/
├── get_user
├── update_user
├── get_product
├── create_product
├── get_order
└── create_order
```

**After:**
```
users/
├── GET    /users/{id}
└── PATCH  /users/{id}

products/
├── GET    /products/{id}
└── POST   /products

orders/
├── GET    /orders/{id}
└── POST   /orders
```

---

## Real-World Examples

### Example 1: SaaS Platform

```
API Groups:

authentication/
├── POST /login
├── POST /register
├── POST /logout
└── POST /forgot-password

workspaces/
├── GET    /workspaces
├── POST   /workspaces
├── GET    /workspaces/{id}
├── PATCH  /workspaces/{id}
└── POST   /workspaces/{id}/invite

projects/
├── GET    /projects
├── POST   /projects
├── GET    /projects/{id}
├── PATCH  /projects/{id}
└── DELETE /projects/{id}

tasks/
├── GET    /tasks
├── POST   /tasks
├── PATCH  /tasks/{id}
└── POST   /tasks/{id}/complete

billing/
├── GET    /subscription
├── POST   /subscribe
├── POST   /update-payment-method
└── POST   /cancel-subscription

webhooks/
├── POST /stripe
└── POST /slack
```

### Example 2: E-Commerce

```
API Groups:

customers/
├── POST   /register
├── GET    /me
├── PATCH  /me
└── GET    /orders

catalog/
├── GET    /products
├── GET    /products/{id}
├── GET    /categories
└── GET    /search

cart/
├── GET    /cart
├── POST   /cart/add
├── DELETE /cart/items/{id}
└── POST   /cart/apply-coupon

checkout/
├── POST   /checkout
├── POST   /calculate-shipping
└── POST   /validate-coupon

orders/
├── GET    /orders
├── GET    /orders/{id}
├── POST   /orders/{id}/cancel
└── POST   /orders/{id}/track

admin_products/
├── POST   /products
├── PATCH  /products/{id}
├── DELETE /products/{id}
└── POST   /products/import

admin_orders/
├── GET    /orders
├── PATCH  /orders/{id}/status
└── POST   /orders/{id}/refund
```

---

## Best Practices Checklist

- [ ] API groups organized by business domain
- [ ] Related endpoints grouped together
- [ ] Consistent naming conventions
- [ ] Clear, descriptive names (no `temp`, `test`, `old`)
- [ ] API group descriptions added
- [ ] Endpoint descriptions added
- [ ] Function documentation complete
- [ ] Background tasks documented
- [ ] Versioning strategy (if needed)
- [ ] Deprecation process defined
- [ ] New team member can navigate easily

---

**Back to:** [SKILL.md](SKILL.md)
