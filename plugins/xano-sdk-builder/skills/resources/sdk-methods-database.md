# SDK Database Methods

Complete database operations for queries, CRUD, joins, aggregations, and transactions.

## Table of Contents
- [Data Source Selection](#data-source-selection) ⚠️ Critical for multi-tenancy
- [Basic CRUD](#basic-crud)
- [Bulk Operations](#bulk-operations)
- [Specialized Queries](#specialized-queries)
- [Advanced Queries](#advanced-queries)
- [Schema & Administration](#schema--administration)

---

## Data Source Selection

**CRITICAL: Understanding Data Sources**

Data sources in Xano are separate data sets that share the same schema but contain different records:
- `live` - Production data (default if not specified)
- `test` - Test/sandbox data (completely separate records)
- Custom data sources for multi-tenancy

### dbSetDatasource

**Forces ALL subsequent database operations to use a specific data source.**

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `dbSetDatasource(value)` | value:string | this | Force database datasource for all subsequent operations |

### 🚨 CRITICAL: Hardcode the Value

**ALWAYS hardcode the datasource value - NEVER pass it from user input!**

The purpose of `dbSetDatasource` is to **enforce** which data source is used. If you pass it from user input, users can manipulate which data they access - defeating the purpose entirely.

**XanoScript Output:**
```xanoscript
db.set_datasource {
  value = "test"
}
```

### ✅ CORRECT: Hardcoded Datasource

```json
{
  "operations": [
    {"method": "dbSetDatasource", "args": ["test"]},
    {"method": "input", "args": ["message", "text"]},
    {"method": "dbAdd", "args": ["logs", {"content": "$input.message"}, "record"]},
    {"method": "response", "args": [{"success": true, "record": "$record"}]}
  ]
}
```

This endpoint will ONLY write to the `test` datasource - user has no control.

### ❌ WRONG: User-Controlled Datasource

```json
{
  "operations": [
    {"method": "input", "args": ["datasource", "text"]},
    {"method": "dbSetDatasource", "args": ["$input.datasource"]},
    {"method": "dbQuery", "args": ["users", {}, "users"]}
  ]
}
```

**Never do this!** Users could pass `"live"` and access production data when they should only access test data.

### When to Use

- ✅ **Enforcing test data isolation** - Ensure endpoints only touch test data
- ✅ **Multi-tenant applications** - Each tenant's endpoints use their datasource
- ✅ **Staging environments** - Force all operations to staging data
- ✅ **Restricted access** - When slug specifies a datasource restriction

### How It Works

1. Place `dbSetDatasource` as the **FIRST operation** in your stack
2. ALL subsequent `dbQuery`, `dbAdd`, `dbEdit`, `dbDelete`, etc. use that datasource
3. Records are completely separate - ID 1 in `live` ≠ ID 1 in `test`

### Common Values

- `"live"` - Production data
- `"test"` - Test/sandbox data (recommended for development)

⚠️ **IMPORTANT:** `dbSetDatasource` affects ALL subsequent database operations in the current function stack. Place it at the very beginning, before any database operations.

---

## Basic CRUD

**8 core database methods** for standard CRUD operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `dbGet(table,filters,alias)` | table:string, filters:DatabaseFilter, alias:string | this | Get single record by filter |
| `dbGetByMultipleFields(table,filters,alias)` | table:string, filters:DatabaseFilter, alias:string | this | Get by multiple field conditions |
| `dbQuery(table,options?,alias?)` | table:string, options?:QueryOptions, alias?:string | this | Query with filters/sorting/paging/addons |
| `dbAdd(table,data,alias)` | table:string, data:Record\|string, alias:string | this | Add new record |
| `dbEdit(table,filters,data,alias)` | table:string, filters:DatabaseFilter, data:Record\|string, alias:string | this | Edit existing record |
| `dbInsert(table,data,alias)` | table:string, data:Record\|string, alias:string | this | Alias for `.dbAdd()` |
| `dbUpdate(table,filters,data,alias)` | table:string, filters:DatabaseFilter, data:Record\|string, alias:string | this | Alias for `.dbEdit()` |
| `dbDelete(table,filters,alias?)` | table:string, filters:DatabaseFilter, alias?:string | this | Delete record(s) |

### Examples

```json
{
  "operations": [
    {"method": "dbGet", "args": ["users", {"id": "$input.user_id"}, "user"]},

    {"method": "dbQuery", "args": ["users", {
      "filters": {"status": "$input.status"},
      "sort": [{"field": "created_at", "direction": "desc"}],
      "offset": 0,
      "limit": 20
    }, "users"]},

    {"method": "dbAdd", "args": ["users", {
      "name": "$input.name",
      "email": "$input.email"
    }, "new_user"]},

    {"method": "dbEdit", "args": ["users",
      {"id": "$input.user_id"},
      {"name": "$input.name"},
      "updated_user"
    ]},

    {"method": "dbDelete", "args": ["users", {"id": "$input.user_id"}]}
  ]
}
```

### dbQuery Options

The `dbQuery` method accepts a comprehensive options object with **95%+ feature completeness**:

```typescript
{
  // Filtering
  "filters": {"field": "value"},              // Object filters (auto-converts to where)
  "where": "$db.table.field == value",        // Direct where clause

  // ⚠️ Joins - SDK generates syntax but Xano rejects it at runtime
  // Use SEQUENTIAL QUERIES instead (see workaround below)

  // Computed Fields
  "eval": {
    "computed_field": "$db.table.field1 ~ $db.table.field2",
    "calculated": "$db.joined.value|filter"
  },

  // Sorting
  "sort": [{"field": "created_at", "direction": "desc"}],

  // Pagination (Multiple Options)
  "page": 1,                                  // Page number
  "per_page": 20,                             // Items per page
  "offset": 0,                                // Or use offset/limit
  "limit": 20,
  "totals": true,                             // Include totals
  "metadata": true,                           // Include pagination metadata

  // Field Selection
  "output": ["id", "name", "email"],          // Select specific fields

  // Related Data (Addons)
  "addon": [{
    "name": "addon_name",                     // Addon function name
    "input": {"user_id": "$output.id"},       // Input params (use $output for current record)
    "as": "items.result_field"                // Where to attach results
  }]
}
```

**Examples:**

```json
{
  "operations": [
    {"comment": "Basic query with filters and sorting"},
    {"method": "dbQuery", "args": ["users", {
      "filters": {"status": "active"},
      "sort": [{"field": "created_at", "direction": "desc"}],
      "limit": 10
    }, "active_users"]},

    {"comment": "⚠️ Joins via SDK don't work - use SEQUENTIAL QUERIES instead"},
    {"method": "dbQuery", "args": ["posts", {"limit": 10}, "posts"]},
    {"method": "var", "args": ["first_post", "$posts.items|first"]},
    {"method": "dbGet", "args": ["users", {"id": "$first_post.user_id"}, "author"]},
    {"comment": "Result: $first_post has the post, $author has the related user"},

    {"comment": "Query with computed fields (eval)"},
    {"method": "dbQuery", "args": ["users", {
      "eval": {
        "full_name": "$db.users.first_name ~ ' ' ~ $db.users.last_name",
        "age": "2025 - $db.users.birth_year"
      },
      "output": ["id", "full_name", "email", "age"]
    }, "users_computed"]},

    {"comment": "Query with addons (related data via addon functions)"},
    {"method": "dbQuery", "args": ["users", {
      "filters": {"id": "$input.user_id"},
      "addon": [{
        "name": "Get User Orders",
        "input": {"user_id": "$output.id"},
        "as": "items.orders"
      }]
    }, "user_with_orders"]},

    {"comment": "Case-insensitive search (ILIKE pattern)"},
    {"method": "dbQuery", "args": ["posts", {
      "where": "($db.posts.title|to_lower) ~ ($input.search|to_lower)"
    }, "search_results"]},

    {"comment": "Complete query with filters, sorting, and pagination"},
    {"method": "dbQuery", "args": ["users", {
      "where": "$db.users.status == \"active\"",
      "eval": {
        "full_name": "$db.users.first_name ~ ' ' ~ $db.users.last_name"
      },
      "output": ["id", "full_name", "email"],
      "sort": [{"field": "created_at", "order": "desc"}],
      "page": 1,
      "per_page": 20,
      "totals": true,
      "metadata": true
    }, "users_complete"]}
  ]
}
```

---

## Bulk Operations

**4 methods** for operating on multiple records at once.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `dbBulkAdd(table,items,options?,alias?)` | table:string, items:any[], options?:{allowIdField?:boolean}, alias?:string | this | Add multiple records |
| `dbBulkUpdate(table,items,alias?)` | table:string, items:any[], alias?:string | this | Update multiple records |
| `dbBulkPatch(table,items,alias?)` | table:string, items:any[], alias?:string | this | Patch multiple records |
| `dbBulkDelete(table,search,alias?)` | table:string, searchCondition:string\|DatabaseFilter, alias?:string | this | Delete multiple records |

### Examples

```json
{
  "operations": [
    {"method": "dbBulkAdd", "args": ["user", "$input.users", {}, "created_users"]},
    {"method": "dbBulkUpdate", "args": ["user", "$updated_users", "results"]},
    {"method": "dbBulkDelete", "args": ["user", "status == \"inactive\"", "deleted_count"]}
  ]
}
```

### XanoScript Syntax (Official)

```xanoscript
// Bulk Add - add multiple records at once
db.bulk.add user {
  items = [
    { name: "Alice", email: "alice@example.com" },
    { name: "Bob", email: "bob@example.com" }
  ]
} as $new_users

// Bulk Add from variable
db.bulk.add user { items = $user_list } as $created

// Bulk Update - update records matching search
db.bulk.update user {
  search = $db.user.status == "pending"
  data = { status: "active" }
} as $updated

// Bulk Delete - delete records matching search
db.bulk.delete user {
  search = $db.user.status == "inactive"
}
```

---

## Specialized Queries

**11 methods** for specific query operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `dbPatch(table,filters,data,alias)` | table:string, filters:DatabaseFilter, data:Record, alias:string | this | Partial update (only provided fields) |
| `dbAddOrEdit(table,filters,data,alias)` | table:string, filters:DatabaseFilter, data:Record, alias:string | this | Upsert operation |
| `dbHas(table,filters,alias)` | table:string, filters:DatabaseFilter, alias:string | this | Check if record exists |
| `dbCount(table,filters?,alias?)` | table:string, filters?:DatabaseFilter, alias?:string | this | Count matching records |
| `dbQueryCount(table,search?,alias?)` | table:string, searchOrOptions?:string\|any, alias?:string | this | Count with query options |
| `dbQueryExists(table,search,alias?)` | table:string, search:string, alias?:string | this | Check if query returns results |
| `dbQuerySum(table,options,alias?)` | table:string, options:any, alias?:string | this | Sum field values |
| `dbQueryAggregate(table,config,alias?)` | table:string, aggregateConfig:any, alias?:string | this | Aggregate query (min/max/avg) |
| `dbQuerySingle(table,search?,alias?)` | table:string, search?:string, alias?:string | this | Query single record |
| `dbQueryList(table,search?,alias?)` | table:string, search?:string, alias?:string | this | Query list of records |
| `dbQueryStream(table,search?,alias?)` | table:string, search?:string, alias?:string | this | Stream large result sets |

### Examples

```json
{
  "operations": [
    {"method": "dbPatch", "args": ["user", {"id": "$input.user_id"}, {"last_login": "$timestamp"}, "user"]},
    {"method": "dbAddOrEdit", "args": ["user", {"email": "$input.email"}, {"name": "$input.name", "email": "$input.email"}, "user"]},
    {"method": "dbHas", "args": ["user", {"email": "$input.email"}, "exists"]},
    {"method": "dbCount", "args": ["user", {"status": "active"}, "count"]},
    {"method": "dbQuerySum", "args": ["orders", {"field": "total", "filters": {"status": "completed"}}, "sum"]}
  ]
}
```

---

## Advanced Queries

**6 methods** for complex query operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `dbAdvancedQuery(options)` | options:AdvancedQueryOptions | this | Complex query with all options |
| `dbQueryWithJoins(table,search?,joins?,alias?)` | table:string, search?:string, joins?:JoinConfig, alias?:string | this | Query with table joins |
| `dbQueryWithSorting(table,search?,sorting?,returnType?,alias?)` | table:string, search?:string, sorting?:SortingConfig[], returnType?:'single'\|'list', alias?:string | this | Query with sorting |
| `dbQueryWithPaging(table,search?,paging?,alias?)` | table:string, search?:string, paging?:PagingConfig, alias?:string | this | Query with pagination |
| `dbQueryWithExternalPaging(table,search?,externalPaging?,alias?)` | table:string, search?:string, externalPaging?:ExternalPagingConfig, alias?:string | this | Query with external paging params |
| `dbQueryWithOutput(table,search?,output?,returnType?,alias?)` | table:string, search?:string, output?:string[], returnType?:'single'\|'list', alias?:string | this | Query specific fields only |

### Examples

```json
{
  "operations": [
    {"method": "dbQueryWithJoins", "args": ["user", "status == \"active\"", [{"table": "profile", "alias": "profile", "type": "left", "on": "user.id = profile.user_id"}], "users"]},
    {"method": "dbQueryWithSorting", "args": ["user", "", [{"field": "created_at", "direction": "desc"}], "list", "users"]},
    {"method": "dbQueryWithPaging", "args": ["user", "status == \"active\"", {"page": "$input.page", "per_page": 20}, "users"]},
    {"method": "dbQueryWithOutput", "args": ["user", "", ["id", "name", "email"], "list", "users"]}
  ]
}
```

---

## Schema & Administration

**3 methods** for schema management and administration.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `dbSchema(tableName,path?,alias?)` | tableName:string, path?:string, alias?:string | this | Get table schema |
| `dbTruncate(tableName,reset?)` | tableName:string, reset?:boolean | this | Clear table data |
| `dbTransaction(callback)` | callback:(builder:IFluentBuilder)=>void | this | Atomic transaction block |

### Examples

```json
{
  "operations": [
    {"method": "dbSchema", "args": ["user", "", "schema"]},
    {"method": "dbTruncate", "args": ["temp_table", true]},
    {"method": "dbTransaction", "args": [[
      {"method": "dbAdd", "args": ["order", {"user_id": 1, "total": 100}, "order"]},
      {"method": "dbEdit", "args": ["user", {"id": 1}, {"balance": "$user.balance - 100"}, "user"]}
    ]]}
  ]
}
```

### XanoScript Transaction Syntax (Official)

Transactions ensure atomic operations - if ANY operation fails, ALL are rolled back.

```xanoscript
// Wrap related operations in a transaction
db.transaction {
  stack {
    // Create order
    db.add order {
      data = { user_id: $auth.id, total: $input.amount }
    } as $order

    // Deduct from user balance
    db.edit user {
      field_name = "id"
      field_value = $auth.id
      data = { balance: $user.balance - $input.amount }
    } as $updated_user

    // Create order items
    db.add order_item {
      data = { order_id: $order.id, product_id: $input.product_id }
    } as $item
  }
}
```

**Key points:**
- Use `db.transaction { stack { ... } }` wrapper
- All operations inside `stack` are atomic
- If any operation fails, all previous operations are rolled back
- Transaction scope is limited to the stack block

---

## Common Patterns

### Basic Query Pattern

```json
{
  "operations": [
    {"method": "dbQuery", "args": ["user", {"search": "status == \"active\"", "page": 1, "per_page": 20}, "users"]},
    {"method": "response", "args": [{"users": "$users"}]}
  ]
}
```

### Create with Relationship

```json
{
  "operations": [
    {"method": "dbAdd", "args": ["user", {"name": "$input.name", "email": "$input.email"}, "user"]},
    {"method": "dbAdd", "args": ["profile", {"user_id": "$user.id", "bio": "$input.bio"}, "profile"]},
    {"method": "response", "args": [{"user": "$user", "profile": "$profile"}]}
  ]
}
```

### Conditional Update

```json
{
  "operations": [
    {"method": "dbGet", "args": ["user", {"id": "$input.user_id"}, "user"]},
    {"method": "conditional", "args": ["$user.status == \"active\""]},
    {"method": "dbEdit", "args": ["user", {"id": "$input.user_id"}, {"last_active": "$timestamp"}, "updated"]},
    {"method": "endConditional"},
    {"method": "response", "args": [{"user": "$updated"}]}
  ]
}
```

---

**Total Methods in this File: 33**

For workflow guidance, see [workflow.md](workflow.md)
For advanced patterns, see [examples.md](examples.md)
