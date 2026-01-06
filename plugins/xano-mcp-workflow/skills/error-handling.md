# Error Handling Patterns

## The #1 Rule: Timeout Protection

**ALWAYS check for `$body == false` before accessing nested fields.**

API requests that timeout return `false` instead of an object. Accessing `$body.items` on `false` throws an error.

```xanoscript
var $body {
  value = $api_result.response.result
}

// ALWAYS check for timeout FIRST
conditional {
  if ($body == false) {
    throw {
      name = "API_TIMEOUT"
      value = "Meta API call timed out"
    }
  }
}

// NOW safe to access nested fields
var $items {
  value = $body.items
}
```

---

## Common Errors and Fixes

### "Unable to locate var: body.items"

**Cause:** API request timed out, `$body` is `false`

**Fix:** Add timeout check before accessing nested fields

```xanoscript
conditional {
  if ($body == false) {
    throw {
      name = "API_TIMEOUT"
      value = "Meta API call timed out"
    }
  }
}
```

---

### "Unable to locate var: item.fieldname"

**Cause:** The source table doesn't have that field

**Fix:** Use `inspect-v1-table` endpoint to check actual field names

```bash
curl -s -X POST 'https://instance.xano.io/api:GROUP/inspect-v1-table' \
  -H 'Content-Type: application/json' \
  -d '{"table_id": 109}'
```

---

### "Duplicate record detected"

**Cause:** Page already migrated (or re-running same page)

**Fix:** This is expected if re-running. Skip the page or clear table first.

---

### 502 Bad Gateway

**Cause:** Xano server overload or transient issue

**Fix:** Auto-recovers. If persistent, reduce concurrency or add delays.

```bash
# Add delay between batches
sleep 2
```

---

### "Invalid app" / ERROR_CODE_NOT_FOUND

**Cause:** Wrong instance name or endpoint doesn't exist

**Fix:**
1. Use full domain: `x2nu-xcjc-vhax.agentdashboards.xano.io`
2. Verify endpoint exists in that API group

---

### "Connection lost"

**Cause:** Long-running request disconnected

**Fix:** Transient - retry works. For persistent issues, add timeout setting:

```xanoscript
api.request {
  url = $url
  method = "GET"
  headers = $my_headers
  timeout = 120  // 2 minutes
} as $api_result
```

---

## Error Response Patterns in XanoScript

### Check HTTP Status

```xanoscript
var $status {
  value = $api_result.response.status
}

conditional {
  if ($status >= 400) {
    throw {
      name = "API_ERROR"
      value = "API returned status "|concat:$status
    }
  }
}
```

### Check for Error Object

```xanoscript
conditional {
  if ($body.error != null) {
    throw {
      name = "API_ERROR"
      value = $body.error.message
    }
  }
}
```

---

## Building Inspect Endpoint

Create this once for all migrations:

```xanoscript
query "inspect-v1-table" verb=POST {
  input {
    int table_id
  }

  stack {
    var $base_url {
      value = "https://xmpx-swi5-tlvy.n7c.xano.io/api:meta/workspace/1/table/"
    }

    var $meta_url {
      value = $base_url
        |concat:$input.table_id
        |concat:"/content?page=1&per_page=1"
    }

    var $auth_header {
      value = "Authorization: Bearer "|concat:$env.XANO_META_TOKEN_V1
    }

    var $my_headers {
      value = []|push:$auth_header
    }

    api.request {
      url = $meta_url
      method = "GET"
      headers = $my_headers
      timeout = 120
    } as $api_result

    var $body {
      value = $api_result.response.result
    }
  }

  response = {
    items: $body.items
    total_items: $body.itemsTotal
    total_pages: $body.pageTotal
  }
}
```

Usage:
```bash
curl -s -X POST 'https://instance.xano.io/api:GROUP/inspect-v1-table' \
  -H 'Content-Type: application/json' \
  -d '{"table_id": 109}'
```

Returns one record showing all field names.

---

## Debugging Workflow

1. **Error appears** → Check error message
2. **Field not found** → Use inspect endpoint to see actual fields
3. **Timeout** → Add timeout protection check
4. **Duplicate** → Page already done, skip it
5. **502/Connection lost** → Retry, reduce concurrency

---

## Precondition vs Conditional

**Precondition** - Use for INPUT validation (before processing):

```xanoscript
precondition {
  if ($input.page < 1) {
    throw {
      name = "INVALID_INPUT"
      value = "Page must be >= 1"
      code = 400
    }
  }
}
```

**Conditional** - Use for RUNTIME checks (during processing):

```xanoscript
conditional {
  if ($body == false) {
    throw {
      name = "API_TIMEOUT"
      value = "API timed out"
    }
  }
}
```
