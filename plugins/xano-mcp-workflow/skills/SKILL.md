---
name: xano-mcp-workflow
description: Battle-tested patterns for using the Xano MCP tool effectively. Covers tool discovery, curl testing, endpoint creation, XanoScript syntax, batch migrations, and error handling. Keywords - xano-mcp, curl testing, xanoscript, endpoint creation, migration, batch processing, mcp tools, xano api, create endpoint, update endpoint, inspect table, parallel curl.
---

# Xano MCP Workflow

## Purpose

Capture proven patterns for working with the Xano MCP tool effectively. These patterns have been battle-tested through real migrations of 1.3+ million records and countless endpoint iterations.

## When to Use This Skill

Automatically activates when:
- Using xano-mcp MCP tool
- Creating or updating Xano endpoints via MCP
- Testing Xano endpoints with curl
- Running batch migrations
- Debugging XanoScript syntax errors
- Working with Xano Meta API

---

## Quick Start: The MCP Tool Flow

**ALWAYS follow this pattern:**

```
1. tool_search → Find the right tool
2. info → Get exact parameters
3. execute → Run with correct params
4. curl test → Verify it works
```

**Example:**
```javascript
// Step 1: Search
mcp__xano-mcp__tool_search({ query: "create endpoint" })
// Returns: tool_id: "create_endpoint"

// Step 2: Get info
mcp__xano-mcp__info({ tool_id: "create_endpoint" })
// Returns: required params, examples

// Step 3: Execute
mcp__xano-mcp__execute({
  tool_id: "create_endpoint",
  arguments: {
    instance_name: "x2nu-xcjc-vhax.agentdashboards.xano.io",
    api_group_id: 650,
    name: "my-endpoint",
    script: "..."
  }
})

// Step 4: Curl test immediately
curl -s -X POST 'https://x2nu-xcjc-vhax.agentdashboards.xano.io/api:GROUP_ID/my-endpoint' \
  -H 'Content-Type: application/json' \
  -d '{"param": "value"}'
```

---

## Critical Rules

### 1. Instance Names - Use Full Domain

```
WRONG: "x2nu-xcjc-vhax"
RIGHT: "x2nu-xcjc-vhax.agentdashboards.xano.io"
```

### 2. Never Create Duplicates

```
FIRST TIME: use create_endpoint
AFTER THAT: use update_endpoint with api_id

NEVER create my-endpoint-v2, my-endpoint-v3, etc.
```

### 3. Test After Every Change

Deploy → Curl test → Verify → Then add next feature

---

## Navigation Guide

| Need to... | Read this |
|------------|-----------|
| Curl test endpoints | [curl-testing.md](curl-testing.md) |
| Write XanoScript | [xanoscript-syntax.md](xanoscript-syntax.md) |
| Create/update endpoints | [endpoint-workflow.md](endpoint-workflow.md) |
| Run batch migrations | [batch-migrations.md](batch-migrations.md) |
| Debug errors | [error-handling.md](error-handling.md) |

---

## Quick Reference

### Curl Test Template

```bash
# POST with JSON - USE SINGLE QUOTES
curl -s -X POST 'https://INSTANCE.xano.io/api:GROUP_ID/endpoint' \
  -H 'Content-Type: application/json' \
  -d '{"field": "value"}'
```

### XanoScript Variable Syntax

```xanoscript
// Variables use $ prefix in stack
var $my_var {
  value = "something"
}

// Reference with $
var $combined {
  value = $my_var|concat:" more"
}
```

### API Request Pattern

```xanoscript
var $auth_header {
  value = "Authorization: Bearer "|concat:$env.API_KEY
}

var $my_headers {
  value = []|push:$auth_header
}

api.request {
  url = $url
  method = "POST"
  headers = $my_headers  // Pass variable directly
  params = $request_body // NOT "body", use "params"
  timeout = 120
} as $api_result
```

### Timeout Protection

```xanoscript
var $body {
  value = $api_result.response.result
}

// ALWAYS check for timeout BEFORE accessing nested fields
conditional {
  if ($body == false) {
    throw {
      name = "API_TIMEOUT"
      value = "API call timed out"
    }
  }
}

// Now safe to access
var $items {
  value = $body.items
}
```

### Endpoint Response (Not Return)

```xanoscript
// Use response = {} for endpoints
response = {
  success: true
  data: $result
  count: $items|count
}

// NOT: return { ... }
```

---

## Common Gotchas

| Wrong | Right |
|-------|-------|
| `if`/`endif` | `conditional`/`endConditional` |
| `foreach`/`endforeach` | `forEach`/`endForEach` |
| `return { }` | `response = { }` |
| `body: $data` in api.request | `params: $data` |
| `var name` | `var $name` |
| Short instance name | Full domain with `.xano.io` |

---

## Resource Files

### [curl-testing.md](curl-testing.md)
Complete curl patterns for GET, POST, authenticated requests, and avoiding shell escaping issues.

### [xanoscript-syntax.md](xanoscript-syntax.md)
XanoScript syntax reference: variables, conditionals, loops, api.request, db operations.

### [endpoint-workflow.md](endpoint-workflow.md)
Step-by-step guide for creating and updating endpoints with xanoscript_builder.

### [batch-migrations.md](batch-migrations.md)
Patterns for running parallel migrations: 20 concurrent is safe, how to monitor, retry failed pages.

### [error-handling.md](error-handling.md)
Common errors and fixes: timeout protection, 502 handling, missing field errors.

---

## Related Skills

- **xano-sdk-builder** - Deep XanoScript patterns and BUILD→TEST→UPDATE workflow
- **xano-api-development** - High-level Xano architecture decisions
- **xano-frontend-integration** - Variable scoping bugs with db.edit

---

**Skill Status**: COMPLETE
**Battle-Tested**: 1.3M+ records migrated
**Patterns From**: Real production migrations
