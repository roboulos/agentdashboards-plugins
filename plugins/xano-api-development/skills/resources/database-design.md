# Database Design

Database design best practices for Xano applications.

---

## Table of Contents

- [Normalization Strategies](#normalization-strategies)
- [Relationship Patterns](#relationship-patterns)
- [Index Optimization](#index-optimization)
- [Query Performance](#query-performance)
- [Common Schemas](#common-schemas)

---

## Normalization Strategies

### Third Normal Form (3NF) - Default Standard

**Principle:** Each table represents one entity, no redundant data.

**Example: E-Commerce**

**Good (Normalized):**
```
users
├── id
├── email
├── password_hash
├── created_at
└── updated_at

addresses
├── id
├── user_id (FK → users.id)
├── street
├── city
├── state
├── zip
└── country

orders
├── id
├── user_id (FK → users.id)
├── shipping_address_id (FK → addresses.id)
├── billing_address_id (FK → addresses.id)
├── total
├── status
└── created_at

order_items
├── id
├── order_id (FK → orders.id)
├── product_id (FK → products.id)
├── quantity
└── price_at_time
```

**Bad (Denormalized):**
```
orders
├── id
├── user_email
├── user_name
├── shipping_street
├── shipping_city
├── shipping_state
├── shipping_zip
├── billing_street
├── billing_city
├── billing_state
├── billing_zip
├── product_1_name
├── product_1_price
├── product_1_quantity
├── product_2_name
└── ... (nightmare)
```

### When to Denormalize

**Strategic denormalization** for performance:

✅ **Read-heavy data**
```
Table: products
├── id
├── name
├── price
├── category_id (FK)
├── category_name (denormalized for fast display)
└── total_sales (denormalized count)
```

✅ **Avoid complex joins**
```
Table: order_summary
├── id
├── order_id
├── user_name (denormalized)
├── user_email (denormalized)
├── total_items (denormalized count)
└── created_at
```

❌ **Don't denormalize when:**
- Data changes frequently
- You need data consistency
- Storage cost is high

---

## Relationship Patterns

### One-to-Many

**Most common relationship**

**Example: Users → Orders**

```
users
├── id (PK)
├── email
└── name

orders
├── id (PK)
├── user_id (FK → users.id)
├── total
└── created_at
```

**Query:**
```javascript
// Get user with all orders
endpoint
  .queryOne('users', {id: '$user_id'})
  .query('orders', {user_id: '$user_id'})
  .respond({
    user: '$user',
    orders: '$orders'
  });
```

### Many-to-Many

**Requires junction table**

**Example: Products ↔ Categories**

```
products
├── id (PK)
├── name
└── price

categories
├── id (PK)
└── name

product_categories (junction table)
├── id (PK)
├── product_id (FK → products.id)
└── category_id (FK → categories.id)
```

**Query:**
```javascript
// Get product with all categories
endpoint
  .queryOne('products', {id: '$product_id'})
  .query('product_categories', {product_id: '$product_id'})
  .forEach('$product_categories', (e, pc) => {
    e.queryOne('categories', {id: '$pc.category_id'})
  })
  .respond({
    product: '$product',
    categories: '$categories_array'
  });
```

**Better: Use Xano's Many-to-Many**
Xano supports M2M natively, which generates junction table automatically.

### One-to-One

**Rare, used for separation of concerns**

**Example: User → UserProfile**

```
users
├── id (PK)
├── email
└── password_hash

user_profiles
├── id (PK)
├── user_id (FK → users.id, UNIQUE)
├── bio
├── avatar_url
└── preferences
```

**Why separate:**
- Profile data loaded less frequently
- Keeps users table small
- Optional data

---

## Index Optimization

### When to Add Indexes

✅ **Foreign keys** (always index)
```
orders.user_id
order_items.order_id
addresses.user_id
```

✅ **Frequently queried fields**
```
users.email (for login)
products.sku (for lookups)
orders.status (for filtering)
```

✅ **Sort fields**
```
orders.created_at (for sorting)
products.name (for alphabetical)
```

### When NOT to Index

❌ **Small tables** (< 1000 rows)
❌ **Fields that change frequently**
❌ **Low-cardinality fields** (e.g., boolean, status with 2-3 values)
❌ **Fields never used in WHERE/ORDER BY**

### Composite Indexes

For queries with multiple conditions:

**Example:**
```
Query: Find active orders for user, sorted by date
WHERE user_id = ? AND status = 'active' ORDER BY created_at DESC

Index: (user_id, status, created_at)
```

**Rule:** Index fields in order of:
1. Equality conditions (WHERE user_id = ?)
2. Range conditions (WHERE created_at > ?)
3. Sort fields (ORDER BY created_at)

---

## Query Performance

### N+1 Query Problem

**Problem:**
```javascript
// Bad: N+1 queries
endpoint
  .query('orders', {user_id: '$user_id'})  // 1 query
  .forEach('$orders', (e, order) => {
    e.query('order_items', {order_id: '$order.id'})  // N queries
  })
```

**Solution 1: Batch Query**
```javascript
// Good: 2 queries
endpoint
  .query('orders', {user_id: '$user_id'})
  .var('order_ids', '$orders.map(o => o.id)')
  .query('order_items', {order_id: {$in: '$order_ids'}})
  .respond({
    orders: '$orders',
    items: '$order_items'
  });
```

**Solution 2: Use Xano Relationships**
Xano can auto-populate relationships in single query.

### Pagination

**Always paginate large result sets:**

```javascript
// Endpoint: GET /products
endpoint
  .input('page', 'number', {default: 1})
  .input('per_page', 'number', {default: 20})

  // Calculate offset
  .var('offset', '($page - 1) * $per_page')

  // Get total count
  .queryCount('products', {})

  // Get page of results
  .query('products', {}, {
    offset: '$offset',
    limit: '$per_page',
    order: {created_at: 'desc'}
  })

  .respond({
    products: '$products',
    page: '$page',
    per_page: '$per_page',
    total: '$count',
    total_pages: 'Math.ceil($count / $per_page)'
  });
```

### Avoid SELECT *

**Query only needed fields:**

```javascript
// Bad: Get all fields
endpoint
  .query('users', {})
  .respond({users: '$users'});

// Good: Select specific fields
endpoint
  .query('users', {}, {
    fields: ['id', 'email', 'name', 'created_at']
  })
  .respond({users: '$users'});
```

---

## Common Schemas

### User Authentication

```
users
├── id (PK, auto-increment)
├── email (unique, indexed)
├── password_hash
├── name
├── role (enum: user, admin)
├── email_verified (boolean)
├── created_at (datetime)
└── updated_at (datetime)

auth_tokens
├── id (PK)
├── user_id (FK → users.id, indexed)
├── token (text, unique, indexed)
├── type (enum: access, refresh, reset)
├── expires_at (datetime, indexed)
└── created_at (datetime)

user_sessions
├── id (PK)
├── user_id (FK → users.id, indexed)
├── ip_address (text)
├── user_agent (text)
├── created_at (datetime)
└── last_active (datetime)
```

### E-Commerce

```
products
├── id (PK)
├── sku (unique, indexed)
├── name
├── description
├── price (decimal)
├── inventory (number)
├── active (boolean, indexed)
├── created_at
└── updated_at

categories
├── id (PK)
├── name
├── slug (unique, indexed)
└── parent_id (FK → categories.id, nullable)

product_categories (M2M junction)
├── product_id (FK → products.id)
└── category_id (FK → categories.id)

carts
├── id (PK)
├── user_id (FK → users.id, indexed)
├── created_at
└── updated_at

cart_items
├── id (PK)
├── cart_id (FK → carts.id, indexed)
├── product_id (FK → products.id)
├── quantity (number)
└── added_at

orders
├── id (PK)
├── user_id (FK → users.id, indexed)
├── status (enum: pending, paid, shipped, delivered, indexed)
├── subtotal (decimal)
├── tax (decimal)
├── shipping (decimal)
├── total (decimal)
├── created_at (indexed)
└── updated_at

order_items
├── id (PK)
├── order_id (FK → orders.id, indexed)
├── product_id (FK → products.id)
├── product_name (denormalized)
├── quantity (number)
├── price_at_time (decimal)
└── subtotal (decimal)
```

### SaaS / Multi-Tenant

```
organizations
├── id (PK)
├── name
├── slug (unique, indexed)
├── plan (enum: free, pro, enterprise)
├── created_at
└── updated_at

users
├── id (PK)
├── email (unique, indexed)
├── password_hash
├── name
├── created_at
└── updated_at

organization_members
├── id (PK)
├── organization_id (FK → organizations.id, indexed)
├── user_id (FK → users.id, indexed)
├── role (enum: owner, admin, member)
├── joined_at
└── UNIQUE(organization_id, user_id)

projects
├── id (PK)
├── organization_id (FK → organizations.id, indexed)
├── name
├── created_by (FK → users.id)
├── created_at
└── updated_at

tasks
├── id (PK)
├── project_id (FK → projects.id, indexed)
├── title
├── description
├── status (enum: todo, in_progress, done, indexed)
├── assigned_to (FK → users.id, indexed)
├── due_date (datetime, indexed)
├── created_at
└── updated_at
```

---

## Audit Trails

**Always include:**

```
created_at (datetime) - When record was created
updated_at (datetime) - When record was last modified
```

**For sensitive data, add:**

```
created_by (FK → users.id) - Who created it
updated_by (FK → users.id) - Who last modified it
deleted_at (datetime) - Soft delete timestamp
deleted_by (FK → users.id) - Who deleted it
```

**Soft Delete Pattern:**

```
users
├── id
├── email
├── deleted_at (nullable)
└── deleted_by (nullable)

Query active users:
WHERE deleted_at IS NULL

Query deleted users:
WHERE deleted_at IS NOT NULL
```

---

## Best Practices

### Do's:
✅ Normalize to 3NF by default
✅ Add indexes to foreign keys
✅ Add indexes to frequently queried fields
✅ Include created_at, updated_at timestamps
✅ Use proper data types (number, boolean, datetime)
✅ Add unique constraints where appropriate
✅ Plan for soft deletes on important data
✅ Use pagination for large result sets

### Don'ts:
❌ Don't store redundant data without reason
❌ Don't skip foreign key relationships
❌ Don't over-index (slows writes)
❌ Don't use TEXT for everything (use enums, numbers)
❌ Don't forget to validate data constraints
❌ Don't hard delete important records
❌ Don't return unlimited results

---

**Back to:** [SKILL.md](SKILL.md)
