# Endpoint Creation Workflow

## The Incremental Pattern

**NEVER build complete solution first. Build incrementally:**

```
1. Create MINIMAL endpoint
2. Deploy with create_endpoint
3. Test with curl
4. Add ONE feature
5. Update with update_endpoint (NOT create new)
6. Test with curl
7. Repeat steps 4-6
```

---

## Step 1: Create Minimal Endpoint

```javascript
// Use xanoscript_builder first
mcp__xano-mcp__execute({
  tool_id: "xanoscript_builder",
  arguments: {
    instance_name: "x2nu-xcjc-vhax.agentdashboards.xano.io",
    type: "endpoint",
    name: "my-endpoint",
    method: "POST",
    operations: [
      {"method": "input", "args": ["page", "int"]},
      {"method": "response", "args": [{"success": true, "page": "$input.page"}]}
    ]
  }
})
```

This generates the XanoScript.

---

## Step 2: Deploy with create_endpoint

```javascript
mcp__xano-mcp__execute({
  tool_id: "create_endpoint",
  arguments: {
    instance_name: "x2nu-xcjc-vhax.agentdashboards.xano.io",
    api_group_id: 650,  // Get from list_api_groups
    name: "my-endpoint",
    script: "..." // XanoScript from xanoscript_builder
  }
})
```

**Save the returned api_id!** You'll need it for updates.

---

## Step 3: Test Immediately

```bash
curl -s -X POST 'https://x2nu-xcjc-vhax.agentdashboards.xano.io/api:GROUP_ID/my-endpoint' \
  -H 'Content-Type: application/json' \
  -d '{"page": 1}'
```

Verify response before continuing.

---

## Step 4: Add Features with update_endpoint

```javascript
mcp__xano-mcp__execute({
  tool_id: "update_endpoint",
  arguments: {
    instance_name: "x2nu-xcjc-vhax.agentdashboards.xano.io",
    api_group_id: 650,
    api_id: 17259,  // ID from create_endpoint response
    script: "..." // Updated XanoScript with new features
  }
})
```

**CRITICAL:** Use `update_endpoint` with the `api_id`, NOT `create_endpoint` again!

---

## Writing XanoScript Directly (Advanced)

For simple endpoints, you can write XanoScript directly:

```xanoscript
query "migrate-data-page" verb=POST {
  input {
    int page
  }

  stack {
    var $per_page {
      value = 500
    }

    var $base_url {
      value = "https://source.xano.io/api:meta/workspace/1/table/39/content"
    }

    var $meta_url {
      value = $base_url
        |concat:"?page="
        |concat:$input.page
        |concat:"&per_page="
        |concat:$per_page
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

    conditional {
      if ($body == false) {
        throw {
          name = "API_TIMEOUT"
          value = "Meta API call timed out"
        }
      }
    }

    var $items {
      value = $body.items
    }

    var $inserted_count {
      value = 0
    }

    foreach ($items) {
      each as $item {
        db.add target_table {
          data = {
            id: $item.id
            name: $item.name
            email: $item.email
          }
        } as $new_record

        var.update $inserted_count {
          value = $inserted_count|add:1
        }
      }
    }
  }

  response = {
    success: true
    page: $input.page
    inserted: $inserted_count
    total_pages: $body.pageTotal
    total_items: $body.itemsTotal
  }
}
```

---

## Finding API Group ID

```javascript
mcp__xano-mcp__execute({
  tool_id: "list_api_groups",
  arguments: {
    instance_name: "x2nu-xcjc-vhax.agentdashboards.xano.io"
  }
})
```

Look for your group name and use its ID.

---

## Getting Endpoint Details

```javascript
mcp__xano-mcp__execute({
  tool_id: "get_endpoint",
  arguments: {
    instance_name: "x2nu-xcjc-vhax.agentdashboards.xano.io",
    api_group_id: 650,
    api_id: 17184
  }
})
```

Returns the full XanoScript - useful for copying working patterns!

---

## Anti-Patterns

| Wrong | Right |
|-------|-------|
| Create my-endpoint-v2 | Update original endpoint |
| Build complete solution first | Start minimal, add incrementally |
| Skip curl testing | Test after every change |
| Use xanoscript_builder output directly | Review and adjust before deploying |
| Guess MCP tool parameters | Always use `info` first |
