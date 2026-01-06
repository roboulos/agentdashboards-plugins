# Xano SDK Builder Workflow

## 🛑 CRITICAL: Read This Entire File Before Writing Any Code

**You WILL fail if you skip this workflow. This is NOT optional.**

**Also read**: [production-patterns.md](production-patterns.md) for authentication, error handling, RESTful naming, and verification patterns.

---

## The Golden Rule

**BUILD ONE THING → TEST IT → LEARN FROM RESULTS → UPDATE (not recreate) → REPEAT**

If you try to build everything at once, you WILL create multiple errors and waste time.

---

## Step-by-Step Process (FOLLOW EXACTLY)

### Step 1: CREATE Minimal Endpoint (First Time Only)

**What to include:**
- Input validation ONLY (preconditions)
- ONE simple operation (or just return hardcoded response)
- Basic response

**What NOT to include:**
- ❌ Database queries
- ❌ API calls
- ❌ Complex logic
- ❌ Multiple features
- ❌ Everything you think you'll need

**Example - GOOD First Deployment:**

Use sdk_builder to generate:
```json
{
  "type": "endpoint",
  "name": "/validate_email",
  "method": "POST",
  "operations": [
    {"method": "input", "args": ["email", "text"]},
    {"method": "precondition", "args": ["$input.email != \"\"", "Email required", 400]},
    {"method": "response", "args": [{"success": true, "message": "Email validated"}]}
  ]
}
```

This generates XanoScript:
```
input email text
precondition $input.email != "" "Email required" 400
response {"success": true, "message": "Email validated"}
```

**Then:**
1. Deploy with `create_endpoint` (using generated XanoScript)
2. Test with curl immediately
3. Verify it works
4. STOP - Do not add more features yet

---

### Step 2: UPDATE to Add ONE Feature

**Based on Step 1 results, now add ONE thing:**
- Maybe add a database query
- Or maybe add an API call
- Or maybe add a conditional
- **PICK ONE - NOT ALL**

**Example - GOOD Second Deployment:**

Use sdk_builder with ONE new operation:
```json
{
  "type": "endpoint",
  "name": "/validate_email",
  "method": "POST",
  "operations": [
    {"method": "input", "args": ["email", "text"]},
    {"method": "precondition", "args": ["$input.email != \"\"", "Email required", 400]},
    {"method": "dbQuery", "args": ["users", {"filters": {"email": "$input.email"}}, "user"]},
    {"method": "response", "args": [{"success": true, "user": "$user"}]}
  ]
}
```

This generates XanoScript:
```
input email text
precondition $input.email != "" "Email required" 400
var user users|query:{"filters":{"email":"$input.email"}}
response {"success": true, "user": "$user"}
```

**Then:**
1. **UPDATE** (not create new) with `update_endpoint` (using generated XanoScript)
2. Test with curl
3. Read actual response structure
4. STOP - Do not add more yet

---

### Step 3: REPEAT - Keep Adding ONE Feature at a Time

Each iteration:
1. Look at previous test results
2. Add ONE new feature
3. **UPDATE** the same endpoint
4. Test with curl
5. Learn from results
6. Repeat

**Example - GOOD Third Deployment:**

Use sdk_builder with ONE more operation (conditional):
```json
{
  "type": "endpoint",
  "name": "/validate_email",
  "method": "POST",
  "operations": [
    {"method": "input", "args": ["email", "text"]},
    {"method": "precondition", "args": ["$input.email != \"\"", "Email required", 400]},
    {"method": "dbQuery", "args": ["users", {"filters": {"email": "$input.email"}}, "user"]},
    {"method": "conditional", "args": ["$user == []"]},
    {"method": "then", "args": [
      [{"method": "throw", "args": ["USER_NOT_FOUND", "User not found", 404]}]
    ]},
    {"method": "endConditional", "args": []},
    {"method": "response", "args": [{"success": true, "user": "$user"}]}
  ]
}
```

Continue this pattern until the endpoint is complete.

---

## Why This Works

### Building Everything at Once = Failure
```json
// This will create 5-10 errors at once
{
  "operations": [
    {"method": "input", ...},        // Error 1
    {"method": "precondition", ...}, // Maybe works
    {"method": "dbQuery", ...},      // Error 2
    {"method": "apiRequest", ...},   // Error 3, 4, 5
    {"method": "conditional", ...},  // Error 6
    {"method": "forEach", ...},      // Error 7
    {"method": "response", ...}      // Error 8
  ]
}
// Now you have to debug 8 errors instead of 1
```

### Building Incrementally = Success
```json
// Iteration 1: Just validation (0 errors)
{"operations": [
  {"method": "precondition", ...},
  {"method": "response", "args": [{"ok": true}]}
]}

// Iteration 2: Add query (maybe 1 error, easy to fix)
{"operations": [..., {"method": "dbQuery", ...}]}

// Iteration 3: Add conditional (maybe 1 error, easy to fix)
{"operations": [..., {"method": "conditional", ...}]}

// Iteration 4: Add API call (maybe 2 errors, easy to fix)
{"operations": [..., {"method": "apiRequest", ...}]}
```

**Result:** Fix 1 error at a time instead of 8 errors at once.

---

## MCP Tool Discovery Pattern

**ALWAYS use this pattern before executing tools:**

### 1. Search for Tool
```json
{
  "tool": "mcp__snappy-mcp__tool_search",
  "params": {
    "query": "sdk builder"
  }
}
```

Returns available tools matching "sdk builder"

### 2. Get Tool Parameters
```json
{
  "tool": "mcp__snappy-mcp__info",
  "params": {
    "tool_id": "sdk_builder"
  }
}
```

Shows EXACTLY what parameters are required/optional

### 3. Execute sdk_builder
```json
{
  "tool": "mcp__snappy-mcp__execute",
  "params": {
    "tool_id": "sdk_builder",
    "arguments": {
      "type": "endpoint",
      "name": "/user_lookup",
      "method": "POST",
      "operations": [
        {"method": "input", "args": ["email", "text"]},
        {"method": "response", "args": [{"success": true}]}
      ]
    }
  }
}
```

Returns XanoScript string

### 4. Deploy with create_endpoint
```json
{
  "tool": "mcp__snappy-mcp__execute",
  "params": {
    "tool_id": "create_endpoint",
    "arguments": {
      "instance_name": "xnwv-v1z6-dvnr.n7c.xano.io",
      "workspace_id": 5,
      "api_group_id": 1484,
      "name": "/user_lookup",
      "method": "POST",
      "xanoscript": "..."
    }
  }
}
```

**⚠️ NEVER skip the info step - you need to know the exact parameters!**

---

## Creating vs Updating Endpoints

### First Time: create_endpoint

```json
{
  "step1": "Generate XanoScript with sdk_builder",
  "operations": [
    {"method": "input", "args": ["email", "text"]},
    {"method": "response", "args": [{"success": true}]}
  ],
  "step2": "Deploy with create_endpoint",
  "params": {
    "instance_name": "full-domain.n7c.xano.io",
    "workspace_id": 5,
    "api_group_id": 1484,
    "name": "/test",
    "method": "POST",
    "xanoscript": "<generated from sdk_builder>"
  }
}
```

### Every Subsequent Change: update_endpoint

```json
{
  "step1": "Generate updated XanoScript with sdk_builder",
  "operations": [
    {"method": "input", "args": ["email", "text"]},
    {"method": "dbQuery", "args": ["users", {"filters": {"email": "$input.email"}}, "user"]},
    {"method": "response", "args": [{"user": "$user"}]}
  ],
  "step2": "Update with update_endpoint",
  "params": {
    "api_id": 12345,
    "xanoscript": "<updated XanoScript from sdk_builder>"
  }
}
```

**⚠️ NEVER create test-v2, test-v3 - Always UPDATE the same endpoint!**

---

## Testing Pattern

After EVERY deployment (create or update):

### 1. Get the endpoint URL
From the MCP tool response, note the endpoint URL

### 2. Test with curl
```bash
curl -X POST https://xnwv-v1z6-dvnr.n7c.xano.io/api:xNXqMlqb/user_lookup \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

### 3. Read the ACTUAL response
Don't assume what the response looks like - READ IT:
```json
{
  "success": true,
  "user": {
    "id": 123,
    "email": "test@example.com",
    "created_at": 1234567890
  }
}
```

### 4. Learn from the response
- Is the structure what you expected?
- Are there errors?
- What does the SDK error message say?
- What's the actual path to access data?

### 5. UPDATE based on reality
Don't guess - use what you learned from the actual response

---

## Common Mistakes (AVOID THESE)

### ❌ Mistake 1: Building Everything First
```json
{
  "problem": "Don't do this on first deployment!",
  "operations": [
    {"method": "input", "args": ["..."]},
    {"method": "precondition", "args": ["..."]},
    {"method": "dbQuery", "args": ["..."]},
    {"method": "apiRequest", "args": ["..."]},
    {"method": "conditional", "args": ["..."]},
    {"method": "response", "args": ["..."]}
  ],
  "result": "Multiple errors at once"
}
```

### ❌ Mistake 2: Creating Multiple Versions
```json
{
  "bad_pattern": [
    {"action": "create_endpoint", "name": "/test"},
    {"action": "create_endpoint", "name": "/test-v2"},
    {"action": "create_endpoint", "name": "/test-v3"}
  ],
  "good_pattern": [
    {"action": "create_endpoint", "name": "/test"},
    {"action": "update_endpoint", "api_id": 12345},
    {"action": "update_endpoint", "api_id": 12345}
  ]
}
```

### ❌ Mistake 3: Not Testing Between Changes
```json
{
  "bad_workflow": [
    "1. Create endpoint",
    "2. Add 5 features in one update",
    "3. Test once",
    "4. Have 10 errors"
  ],
  "good_workflow": [
    "1. Create endpoint → Test",
    "2. Add 1 feature → Update → Test",
    "3. Add 1 feature → Update → Test",
    "4. Repeat until complete"
  ]
}
```

### ❌ Mistake 4: Assuming Response Structures
```json
{
  "bad_approach": {
    "operations": [
      {"method": "var", "args": ["status", "$api_result.status"]}
    ],
    "problem": "Assumed wrong path"
  },
  "good_approach": {
    "step1": {"method": "var", "args": ["debug", "$api_result"]},
    "step2": "Test and read actual response",
    "step3": {"method": "var", "args": ["status", "$api_result.response.status"]}
  }
}
```

---

## The Right Way (Summary)

1. **Start minimal** - Input validation + hardcoded response
2. **Generate** - Use sdk_builder with minimal operations
3. **Deploy** - Use create_endpoint with generated XanoScript
4. **Test** - curl immediately
5. **Verify** - Read actual response
6. **Add ONE feature** - Database OR API OR conditional (pick one)
7. **Generate** - Use sdk_builder again with added operation
8. **Update** - Use update_endpoint (not create!) with new XanoScript
9. **Test** - curl after update
10. **Learn** - Read actual response structure
11. **Repeat** - Add next feature
12. **Continue** - Until endpoint is complete

---

## For Complete SDK Method Reference

When you need to know the exact syntax for SDK methods:

- [sdk-methods-core.md](sdk-methods-core.md) - Variables, inputs, responses
- [sdk-methods-database.md](sdk-methods-database.md) - Database queries, CRUD
- [sdk-methods-api.md](sdk-methods-api.md) - External API calls, webhooks
- [sdk-methods-control-flow.md](sdk-methods-control-flow.md) - Conditionals, loops
- [sdk-methods-security.md](sdk-methods-security.md) - Auth, JWT, sessions
- [sdk-methods-data-structures.md](sdk-methods-data-structures.md) - Arrays, objects
- [sdk-methods-text.md](sdk-methods-text.md) - String operations
- [sdk-methods-redis.md](sdk-methods-redis.md) - Redis caching
- [sdk-methods-storage.md](sdk-methods-storage.md) - File uploads
- [sdk-methods-utilities.md](sdk-methods-utilities.md) - Utilities, logging, testing

See [SKILL.md](../SKILL.md) for complete navigation guide.

---

**Remember: The workflow is EVERYTHING. Use sdk_builder to generate XanoScript, deploy incrementally, and test after every change.**
