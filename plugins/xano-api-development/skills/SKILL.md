---
name: xano-api-development
description: Xano API architecture and best practices for high-level design decisions. Use when organizing Xano workspaces, deciding between endpoints vs functions, designing background tasks, planning external API integrations, structuring databases, or implementing auth patterns. Covers workspace organization, architectural patterns, when to use each Xano feature, database design principles, and authentication strategies. Keywords: Xano architecture, Xano best practices, organize Xano, workspace organization, endpoint vs function, Xano design, database design, auth patterns, background tasks, API planning, Xano structure.
---

# Xano API Development - Architecture & Best Practices

High-level architectural guidance for designing and organizing Xano backends.

---

## Purpose

Provides architectural guidance and best practices for designing Xano backends. Focuses on high-level decisions: workspace organization, when to use endpoints vs functions, background task patterns, database design, and authentication strategies.

**Complements xano-sdk-builder:** This skill covers ARCHITECTURE and DESIGN decisions (WHEN and WHY). The xano-sdk-builder skill covers SDK implementation (HOW to write code).

## When to Use This Skill

Automatically activates when you're:
- Planning Xano workspace structure
- Deciding between endpoints vs functions
- Designing background task workflows
- Planning external API integrations
- Structuring database tables and relationships
- Implementing authentication patterns
- Organizing API groups and resources
- Making architectural decisions about Xano features

---

## Quick Start: Navigation Guide

This skill follows **progressive disclosure** - start with the summary, dive into details as needed.

| Topic | File | When to Read |
|-------|------|--------------|
| **Workspace Organization** | [workspace-organization.md](resources/workspace-organization.md) | Starting new project, reorganizing existing workspace |
| **Endpoints vs Functions** | [endpoints-vs-functions.md](resources/endpoints-vs-functions.md) | Deciding where to put logic, refactoring code |
| **Background Tasks** | [background-tasks.md](resources/background-tasks.md) | Long-running operations, async workflows, scheduled jobs |
| **External API Integration** | [external-api-integration.md](resources/external-api-integration.md) | Calling third-party APIs, handling timeouts, retry logic |
| **Database Design** | [database-design.md](resources/database-design.md) | Creating tables, relationships, query optimization |
| **Auth Patterns** | [auth-patterns.md](resources/auth-patterns.md) | User authentication, authorization, token management |

---

## Core Principles

### 1. Organize by Business Domain

**Good:**
```
API Groups:
├── users/           (User management)
├── products/        (Product catalog)
├── orders/          (Order processing)
└── notifications/   (Messaging)
```

**Bad:**
```
API Groups:
├── get-endpoints/
├── post-endpoints/
└── misc/
```

### 2. Endpoints for External Access, Functions for Reuse

**Endpoint:**
- Accessed from outside (frontend, mobile app)
- Has URL path and HTTP method
- Handles auth, input validation, response formatting
- Orchestrates logic

**Function:**
- Reusable logic called by multiple endpoints
- No URL, called internally
- Single responsibility
- Pure business logic

**Example:**
```
Endpoint: POST /orders
├── Validates input
├── Checks auth
├── Calls function: calculate_order_total()
├── Calls function: process_payment()
└── Returns formatted response

Function: calculate_order_total(items, discount_code)
├── Calculates subtotal
├── Applies discount
└── Returns total
```

### 3. Background Tasks for Long Operations

Use background tasks when:
- Operation takes > 30 seconds
- User doesn't need to wait
- Periodic/scheduled work needed
- Processing webhooks asynchronously

**Example:** Email campaign sending, report generation, data sync

### 4. Database Design for Performance

- Keep tables focused (single responsibility)
- Use proper relationships (one-to-many, many-to-many)
- Index frequently queried fields
- Denormalize sparingly for performance
- Use timestamps for audit trails

---

## Quick Reference: Decision Trees

### Should I Create an Endpoint or Function?

```
Will it be called from outside Xano? (frontend, mobile, webhook)
├─ YES → Create ENDPOINT
└─ NO → Will it be reused by multiple endpoints?
   ├─ YES → Create FUNCTION
   └─ NO → Put logic directly in endpoint
```

### Should I Use a Background Task?

```
Does the operation take > 30 seconds?
├─ YES → Use BACKGROUND TASK
└─ NO → Does user need immediate response?
   ├─ YES → Keep in endpoint
   └─ NO → Could use background task for better UX
```

### How Should I Structure My Database?

```
Is this a new entity/concept?
├─ YES → Create NEW TABLE
└─ NO → Is this a property of existing entity?
   ├─ YES → Add FIELD to existing table
   └─ NO → Is this a relationship?
      ├─ One-to-Many → Foreign key field
      ├─ Many-to-Many → Junction table
      └─ Embedded data → JSON field (use sparingly)
```

---

## Common Patterns

### Pattern 1: CRUD API Structure

**Organize endpoints by resource:**

```
API Group: users/
├── GET    /users          (List users)
├── POST   /users          (Create user)
├── GET    /users/{id}     (Get single user)
├── PATCH  /users/{id}     (Update user)
└── DELETE /users/{id}     (Delete user)

Shared Functions:
├── validate_user_input()
├── check_user_permissions()
└── format_user_response()
```

### Pattern 2: Webhook Processing

**Immediate acknowledgment + async processing:**

```
Endpoint: POST /webhooks/stripe
├── Validate webhook signature
├── Return 200 OK immediately
└── Trigger background task: process_stripe_webhook(payload)

Background Task: process_stripe_webhook
├── Parse event data
├── Update database
├── Send notifications
└── Log completion
```

### Pattern 3: External API Integration

**Centralize API calls in functions:**

```
Function: call_stripe_api(endpoint, method, data)
├── Build request
├── Handle authentication
├── Make API call
├── Handle errors
├── Extract response
└── Return standardized format

Endpoints use function:
├── POST /payments → call_stripe_api('/charges', 'POST', data)
├── POST /refunds  → call_stripe_api('/refunds', 'POST', data)
└── GET  /balance  → call_stripe_api('/balance', 'GET', null)
```

### Pattern 4: Multi-Step Workflows

**Use functions to break down complexity:**

```
Endpoint: POST /orders/checkout
├── Function: validate_cart(cart_items)
├── Function: calculate_totals(cart_items, coupon)
├── Function: process_payment(total, payment_method)
├── Function: create_order_record(order_data)
├── Function: send_confirmation_email(order_id)
└── Return order confirmation

Each function is testable and reusable
```

---

## Best Practices Summary

### Workspace Organization
✅ Group by business domain, not by HTTP method
✅ Use clear, descriptive names
✅ Keep related endpoints in same API group
✅ Document API groups with descriptions

### Endpoints
✅ One endpoint = one responsibility
✅ Handle auth at endpoint level
✅ Validate all inputs
✅ Return consistent response format
✅ Use proper HTTP status codes

### Functions
✅ Pure business logic only
✅ Clear input/output contracts
✅ Single responsibility
✅ Reusable across endpoints
✅ Easy to test

### Background Tasks
✅ Use for long operations (> 30s)
✅ Use for scheduled work
✅ Handle failures gracefully
✅ Log progress and errors
✅ Provide status checking endpoints

### Database
✅ Normalize to 3rd normal form by default
✅ Add indexes for frequently queried fields
✅ Use proper relationships
✅ Include created_at, updated_at timestamps
✅ Plan for soft deletes if needed

### Authentication
✅ Use Xano's built-in auth when possible
✅ Store tokens securely
✅ Implement proper RBAC (role-based access control)
✅ Validate permissions at endpoint level
✅ Use auth functions for consistency

---

## Anti-Patterns to Avoid

❌ **God Endpoints** - One endpoint does everything
- Split into focused endpoints by responsibility

❌ **Duplicate Logic** - Same code in multiple endpoints
- Extract to shared function

❌ **Poor Naming** - `endpoint1`, `test_api`, `temp`
- Use descriptive names that indicate purpose

❌ **No Error Handling** - Assume everything works
- Validate inputs, handle API failures, return meaningful errors

❌ **Mixing Concerns** - Auth + business logic + data formatting in one place
- Separate concerns into layers

❌ **Over-Normalized Database** - 10 joins for simple query
- Denormalize strategically for performance

❌ **Under-Normalized Database** - Duplicate data everywhere
- Use proper relationships and foreign keys

---

## Workflow: Planning a New Feature

### Step 1: Define the Requirement
- What does the user need?
- What data is required?
- What's the expected response?

### Step 2: Design the Database
- What tables/fields are needed?
- What relationships exist?
- What queries will be run?
- See [database-design.md](resources/database-design.md)

### Step 3: Plan the API
- What endpoints are needed?
- What HTTP methods?
- What's the URL structure?
- See [endpoints-vs-functions.md](resources/endpoints-vs-functions.md)

### Step 4: Identify Reusable Logic
- What logic can be shared?
- What should be functions?
- What integrations are needed?
- See [external-api-integration.md](resources/external-api-integration.md)

### Step 5: Consider Async Needs
- Are there long-running operations?
- Should anything be scheduled?
- Are background tasks needed?
- See [background-tasks.md](resources/background-tasks.md)

### Step 6: Plan Authentication
- Who can access this?
- What permissions are needed?
- How is auth validated?
- See [auth-patterns.md](resources/auth-patterns.md)

### Step 7: Build Iteratively
- Start with simplest version
- Test frequently
- Add features incrementally
- Use xano-sdk-builder skill for implementation

---

## Resource Files

For detailed guidance on specific topics:

### [workspace-organization.md](resources/workspace-organization.md)
Complete guide to organizing Xano workspaces:
- API group structure strategies
- Naming conventions
- Folder organization
- Documentation practices
- Real-world examples from production systems

**For SDK implementation, see xano-sdk-builder skill**

### [endpoints-vs-functions.md](resources/endpoints-vs-functions.md)
Detailed decision framework:
- When to use endpoints vs functions
- Code organization patterns
- Refactoring strategies
- Performance considerations
- Testing approaches

**For SDK implementation, see xano-sdk-builder skill**

### [background-tasks.md](resources/background-tasks.md)
Comprehensive background task patterns:
- Use cases and examples
- Task scheduling strategies
- Error handling and retries
- Status tracking patterns
- Webhook processing

**For SDK implementation, see xano-sdk-builder skill**

### [external-api-integration.md](resources/external-api-integration.md)
External API integration strategies:
- API client patterns
- Timeout handling
- Rate limiting
- Response caching
- Error recovery

**For SDK syntax, see xano-sdk-builder → resources/sdk-methods-api.md**

### [database-design.md](resources/database-design.md)
Database design best practices:
- Normalization strategies
- Relationship patterns
- Index optimization
- Query performance
- Migration planning

**For SDK syntax, see xano-sdk-builder → resources/sdk-methods-database.md**

### [auth-patterns.md](resources/auth-patterns.md)
Authentication and authorization:
- Xano auth system usage
- Custom auth patterns
- RBAC implementation
- Token management
- Security best practices

**For SDK syntax, see xano-sdk-builder → resources/sdk-methods-security.md**

---

## Related Skills

- **xano-sdk-builder** - SDK-level implementation (HOW to write code)
- **backend-dev-guidelines** - General backend patterns (Node.js/Express)
- **error-tracking** - Error handling and monitoring

---

## Example: Complete Feature Planning

**Requirement:** Build an e-commerce order system

**Step 1: Database Design**
```
Tables:
├── users (id, email, password_hash, created_at)
├── products (id, name, price, inventory, created_at)
├── orders (id, user_id, total, status, created_at)
└── order_items (id, order_id, product_id, quantity, price)

Relationships:
├── orders.user_id → users.id (one-to-many)
├── order_items.order_id → orders.id (one-to-many)
└── order_items.product_id → products.id (many-to-one)
```

**Step 2: API Structure**
```
API Group: orders/
├── POST   /orders/checkout           (Create order)
├── GET    /orders                    (List user's orders)
├── GET    /orders/{id}               (Get order details)
└── POST   /orders/{id}/cancel        (Cancel order)

API Group: products/
├── GET    /products                  (List products)
└── GET    /products/{id}             (Get product details)

Shared Functions:
├── calculate_order_total(items, shipping, tax)
├── validate_inventory(product_id, quantity)
├── process_payment(amount, payment_method)
└── send_order_confirmation(order_id)
```

**Step 3: Background Tasks**
```
Background Task: process_order_fulfillment
├── Triggered after successful payment
├── Updates inventory
├── Sends confirmation email
├── Notifies warehouse
└── Updates order status

Background Task: sync_inventory (scheduled)
├── Runs every hour
├── Syncs with warehouse system
└── Updates product availability
```

**Step 4: Implementation**
1. Create database tables
2. Create shared functions (use xano-sdk-builder)
3. Create endpoints (use xano-sdk-builder)
4. Create background tasks (use xano-sdk-builder)
5. Test iteratively
6. Deploy

---

**Skill Status**: ACTIVE ✅
**Line Count**: < 500 (following 500-line rule) ✅
**Progressive Disclosure**: Reference files for detailed information ✅
**Complements**: xano-sdk-builder (focuses on architecture, not SDK implementation) ✅

**When to Use**: Planning Xano features, organizing workspaces, making architectural decisions
**When NOT to Use**: Writing actual XanoScript code (use xano-sdk-builder instead)
