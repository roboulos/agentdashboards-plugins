# Xano SDK Builder - Quick Reference Card

## 🚀 Before You Code: Quick Checklist

- [ ] Read WORKFLOW.md - understand BUILD → EXPOSE → TEST → LEARN → REPEAT
- [ ] Read WHAT_BREAKS.md - know the 9 critical limitations
- [ ] Complex endpoint (3+ API calls)? Read Section 9 of WHAT_BREAKS.md FIRST
- [ ] Check EXAMPLES.md for similar pattern

---

## ⚡ Most Common Patterns (Copy-Paste Ready)

### Pattern 1: Simple API Call with Error Handling

```json
{
  "operations": [
    {"method": "apiRequest", "args": ["$url", "POST", {
      "headers": {"Authorization": "Bearer $env.API_KEY"},
      "params": {"field": "$input.value"}
    }, "result"]},
    {"method": "var", "args": ["status", "$result.response.status"]},
    {"method": "var", "args": ["body", "$result.response.result"]},
    {"method": "conditional", "args": ["$status >= 400"]},
    {"method": "throw", "args": ["API_ERROR", "$body.error.message"]},
    {"method": "endConditional"},
    {"method": "response", "args": [{"success": true, "data": "$body"}]}
  ],
  "note": "MUST use 'params', NOT 'body' for request data"
}
```

### Pattern 2: Complex API Call with Timeout Protection (NEW - CRITICAL!)

```json
{
  "operations": [
    {"method": "apiRequest", "args": ["$url", "POST", "$options", "api_result"]},
    {"method": "var", "args": ["status", "$api_result.response.status"]},
    {"method": "var", "args": ["body", "$api_result.response.result"]},
    {"method": "conditional", "args": ["$body == false"]},
    {"method": "throw", "args": ["API_TIMEOUT", "API call timed out - check endpoint timeout setting (needs 30+ seconds for complex endpoints)"]},
    {"method": "endConditional"},
    {"method": "conditional", "args": ["$status >= 400"]},
    {"method": "throw", "args": ["API_ERROR", "$body.error.message"]},
    {"method": "endConditional"},
    {"method": "var", "args": ["data", "$body.data"]},
    {"method": "var", "args": ["items", "$data|first"]}
  ],
  "note": "For endpoints with 3+ API calls or slow external APIs - ALWAYS check for timeout first!"
}
```

### Pattern 3: Nested Response Extraction (The Right Way)

```json
{
  "wrong": {
    "operations": [
      {"method": "var", "args": ["content", "$api.response.result.choices|first|get:\"message\"|get:\"content\""]}
    ],
    "problem": "Direct path extraction - FAILS"
  },
  "correct": {
    "operations": [
      {"method": "var", "args": ["body", "$api_result.response.result"]},
      {"method": "var", "args": ["choices", "$body.choices"]},
      {"method": "var", "args": ["first_item", "$choices|first"]},
      {"method": "var", "args": ["message", "$first_item|get:\"message\""]},
      {"method": "var", "args": ["content", "$message|get:\"content\""]},
      {"method": "response", "args": [{"success": true, "text": "$content"}]}
    ],
    "note": "Step-by-step extraction - WORKS"
  }
}
```

### Pattern 4: Array Loop with State Management

```json
{
  "operations": [
    {"method": "var", "args": ["results", "[]"]},
    {"method": "forEach", "args": ["$items", "item", [
      {"method": "conditional", "args": ["($results|count) < 3 && $item.valid == true"]},
      {"method": "varUpdate", "args": ["results", "$results|push:{id:$item.id,name:$item.name}"]},
      {"method": "endConditional"}
    ]]},
    {"method": "response", "args": [{"success": true, "collected": "$results"}]}
  ]
}
```

### Pattern 5: Database Query with Pagination

```json
{
  "operations": [
    {"method": "dbQuery", "args": ["table_name", {
      "filters": {"user_id": "$input.user_id"},
      "limit": 10,
      "sort": [{"field": "created_at", "direction": "desc"}],
      "totals": true
    }, "query_result"]},
    {"method": "var", "args": ["count", "$query_result.itemsReceived"]},
    {"method": "var", "args": ["total", "$query_result.itemsTotal"]},
    {"method": "var", "args": ["items", "$query_result.items"]},
    {"method": "response", "args": [{
      "success": true,
      "items": "$items",
      "count": "$count",
      "total": "$total"
    }]}
  ],
  "note": "totals:true is IMPORTANT - needed for .itemsTotal"
}
```

### Pattern 6: Input Validation (Precondition + Conditional)

```json
{
  "operations": [
    {"method": "precondition", "args": ["$input.email != \"\"", "Email is required", 400]},
    {"method": "precondition", "args": ["$input.amount > 0", "Amount must be positive", 400]},
    {"method": "apiRequest", "args": ["$url", "POST", {}, "result"]},
    {"method": "var", "args": ["status", "$result.response.status"]},
    {"method": "conditional", "args": ["$status >= 400"]},
    {"method": "throw", "args": ["API_FAILED", "Payment processing failed"]},
    {"method": "endConditional"},
    {"method": "response", "args": [{"success": true}]}
  ],
  "note": "Validate input BEFORE making API calls, validate response AFTER"
}
```

---

## 🔴 Critical "Don'ts" (These Will Fail)

```json
{
  "dont_use_body_parameter": {
    "wrong": {"method": "apiRequest", "args": ["$url", "POST", {"body": {"field": "$value"}}, "result"]},
    "correct": {"method": "apiRequest", "args": ["$url", "POST", {"params": {"field": "$value"}}, "result"]},
    "note": "Use 'params' NOT 'body'"
  },
  "dont_assume_direct_paths": {
    "wrong": {"method": "var", "args": ["x", "$api.response.result.data[0].nested.field"]},
    "correct": [
      {"method": "var", "args": ["data", "$api.response.result"]},
      {"method": "var", "args": ["item", "$data|first"]},
      {"method": "var", "args": ["x", "$item|get:\"nested\"|get:\"field\""]}
    ],
    "note": "Step-by-step extraction required"
  },
  "dont_skip_failure_checks": {
    "wrong": {"method": "var", "args": ["choices", "$openai_result.response.result.choices"]},
    "correct": [
      {"method": "var", "args": ["body", "$openai_result.response.result"]},
      {"method": "conditional", "args": ["$body == false"]},
      {"method": "throw", "args": ["TIMEOUT", "API failed"]},
      {"method": "endConditional"},
      {"method": "var", "args": ["choices", "$body.choices"]}
    ],
    "note": "Check for failure BEFORE extracting nested data"
  },
  "dont_use_case_sensitive_search": {
    "wrong": {"method": "dbQuery", "args": ["posts", {"where": "$db.posts.title ~ $input.search"}, "results"]},
    "correct": {"method": "dbQuery", "args": ["posts", {"where": "($db.posts.title|to_lower) ~ ($input.search|to_lower)"}, "results"]},
    "note": "Use |to_lower on BOTH sides for case-insensitive search"
  },
  "dont_use_dynamic_sort_fields": {
    "wrong": {"method": "dbQuery", "args": ["posts", {"sort": {"$input.sort_field": "$input.sort_dir"}}, "results"]},
    "correct": {"method": "dbQuery", "args": ["posts", {"sort": {"created_at": "desc"}}, "results"]},
    "note": "Sort field names must be hardcoded - variables don't work"
  },
  "dont_build_objects_with_multiple_updates": {
    "wrong": [
      {"method": "var", "args": ["obj", "{}"]},
      {"method": "varUpdate", "args": ["obj", "$obj|set:\"a\":1"]},
      {"method": "varUpdate", "args": ["obj", "$obj|set:\"b\":2"]}
    ],
    "correct": {"method": "var", "args": ["obj", "{}|set:\"a\":1|set:\"b\":2"]},
    "note": "Chain filters in one line"
  }
}
```

---

## 🎯 Timeout Configuration (CRITICAL for Complex Endpoints)

### Rule of Thumb
- 1 API call: 10 seconds default (often tight)
- 2-3 API calls: Set to 30 seconds
- 3+ API calls: Set to 60 seconds
- Each external API: +10 seconds
- Buffer: +5 seconds

### How to Configure in Xano UI
1. Open endpoint settings
2. Click "Advanced" tab
3. Find "Request Timeout" field
4. Set to 30+ seconds for complex endpoints
5. Save

### How to Test with curl
```bash
# Add extended timeout for testing
curl --max-time 120 -X POST "https://instance.xano.io/api:slug/endpoint" \
  -H "Content-Type: application/json" \
  -d '{"data":"value"}'
```

---

## 📊 Success Checklist Before Submitting

- [ ] All API calls have timeout + HTTP error checks
- [ ] All nested data extracted step-by-step (not direct paths)
- [ ] All loops have proper state management (varUpdate)
- [ ] All objects built with chained filters
- [ ] All database queries checked for valid responses
- [ ] All input validation done with precondition
- [ ] All response validation done with conditional + throw
- [ ] Tested with curl with extended timeout (--max-time 120)
- [ ] Response structure inspected and understood
- [ ] No assumptions made about response paths

---

## 🆘 Common Error Messages & Fixes

### "Unable to locate var: field"
**Cause:** Response returned false (timeout/failure) or path doesn't exist
**Fix:** Check if response is false first:
```json
{
  "operations": [
    {"method": "conditional", "args": ["$body == false"]},
    {"method": "throw", "args": ["TIMEOUT", "API failed"]},
    {"method": "endConditional"}
  ]
}
```

### "Invalid filter name: [name]"
**Cause:** Using non-existent filter (e.g., `|search:`, `|type`, `|length`)
**Fix:** Use correct filter names:
- `|search:` → use `|contains:`
- `|length` → use `|strlen`
- `|size` → use `|count`

### "Nested objects not supported in response"
**Cause:** Trying to nest objects directly in `.response()`
**Fix:** Build object first, then reference:
```json
{
  "operations": [
    {"method": "var", "args": ["obj", "{}|set:\"nested\":{}|set:\"nested.field\":$value"]},
    {"method": "response", "args": ["$obj"]}
  ]
}
```

### "Operation timed out after X milliseconds"
**Cause:** Endpoint timeout too short for API calls
**Fix:**
1. Increase timeout in Xano UI settings
2. Use `curl --max-time 120` for testing
3. Consider breaking into smaller endpoints

---

## 📚 Where to Find More Info

| Need | File | Section |
|------|------|---------|
| How to build | WORKFLOW.md | All |
| What breaks | WHAT_BREAKS.md | Section 9 (timeouts) |
| Syntax help | SYNTAX.md | All methods |
| Working code | EXAMPLES.md | Stripe, SendGrid, RAG, etc. |
| Learnings | SESSION_2025_11_07_IMPROVEMENTS.md | All |
| MCP tools | SKILL.md | Core MCP Tools |

---

## 🚀 Quick Start (Copy This Template)

```json
{
  "type": "endpoint",
  "name": "/endpoint-name",
  "method": "POST",
  "operations": [
    {"method": "precondition", "args": ["$input.field != \"\"", "Field required", 400]},
    {"method": "apiRequest", "args": ["$url", "POST", {
      "headers": {"Authorization": "Bearer $env.API_KEY"},
      "params": {}
    }, "result"]},
    {"method": "var", "args": ["status", "$result.response.status"]},
    {"method": "var", "args": ["body", "$result.response.result"]},
    {"method": "conditional", "args": ["$body == false"]},
    {"method": "throw", "args": ["API_TIMEOUT", "Request timed out"]},
    {"method": "endConditional"},
    {"method": "conditional", "args": ["$status >= 400"]},
    {"method": "throw", "args": ["API_ERROR", "$body.error"]},
    {"method": "endConditional"},
    {"method": "var", "args": ["data", "$body.data"]},
    {"method": "response", "args": [{"success": true, "data": "$data"}]}
  ]
}
```

**Delete this file and start from WORKFLOW.md → WHAT_BREAKS.md → SYNTAX.md**

---

### Pattern 7: Case-Insensitive Search (ILIKE)

```json
{
  "operations": [
    {"method": "dbQuery", "args": ["posts", {
      "where": "($db.posts.title|to_lower) ~ ($input.search|to_lower)"
    }, "results"]},
    {"method": "response", "args": [{"posts": "$results"}]}
  ],
  "note": "Apply |to_lower to BOTH field AND search term"
}
```

### Pattern 8: Webhook Signature Validation (HMAC)

```json
{
  "operations": [
    {"method": "var", "args": ["expected_sig", "$input.raw_body|hmac_sha256:$env.WEBHOOK_SECRET"]},
    {"method": "precondition", "args": ["$expected_sig == $input.signature", "Invalid signature", 401]},
    {"method": "var", "args": ["payload", "$input.raw_body|from_json"]},
    {"method": "response", "args": [{"success": true, "data": "$payload"}]}
  ],
  "note": "Use |hmac_sha256:$secret for webhook validation"
}
```

### Pattern 9: Transactions (Atomic Operations)

```json
{
  "operations": [
    {"method": "dbTransaction", "args": [[
      {"method": "dbAdd", "args": ["orders", {"user_id": "$auth.id", "total": "$input.amount"}, "order"]},
      {"method": "dbEdit", "args": ["users", {"id": "$auth.id"}, {"balance": "$user.balance - $input.amount"}, "user"]}
    ]]}
  ],
  "note": "All operations inside transaction are atomic - if any fails, all rollback"
}
```

### Pattern 10: Related Data (Sequential Queries)

```json
{
  "operations": [
    {"comment": "⚠️ Joins via SDK don't work at runtime - use sequential queries"},
    {"method": "dbQuery", "args": ["posts", {"limit": 5}, "posts"]},
    {"method": "var", "args": ["first_post", "$posts.items|first"]},
    {"method": "dbGet", "args": ["users", {"id": "$first_post.user_id"}, "author"]},
    {"method": "response", "args": [{"post": "$first_post", "author": "$author"}]}
  ],
  "note": "Query main table, then query related tables separately. Works reliably."
}
```

### Pattern 11: Loop for Multiple Related Records

```json
{
  "operations": [
    {"method": "dbQuery", "args": ["posts", {"limit": 3}, "posts"]},
    {"method": "var", "args": ["results", "[]"]},
    {"method": "forEach", "args": ["$posts.items", "post", [
      {"method": "dbGet", "args": ["users", {"id": "$post.user_id"}, "author"]},
      {"method": "varUpdate", "args": ["results", "$results|push:{post:$post,author:$author}"]}
    ]]},
    {"method": "response", "args": [{"posts_with_authors": "$results"}]}
  ],
  "note": "Loop through results and fetch related data for each. More queries but reliable."
}
```

---

**Last Updated:** January 1, 2026
**Version:** 3.1 (with ILIKE, HMAC, transactions, joins, addons)
