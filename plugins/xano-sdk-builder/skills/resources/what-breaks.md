# What Breaks in XanoScript (Critical Limitations)

This document covers XanoScript limitations and workarounds discovered through production use. Read this BEFORE building endpoints to avoid common pitfalls.

---

## 1. JSON Parsing Errors with External API Calls

### The Problem
When building complex nested objects for external API calls, XanoScript's JSON serialization can fail with "Error parsing JSON: Syntax error" even with correct syntax.

### What Breaks
❌ Step-by-step variable building:
```xanoscript
var system_msg { value = {} }
var system_msg { value = $system_msg|set:"role":"system" }
var system_msg { value = $system_msg|set:"content":$text }
var messages { value = [] }
var messages { value = $messages|push:$system_msg }
```

### What Works
✅ Inline chaining in ONE statement:
```xanoscript
var request_body {
  value = {}
    |set:"model":"anthropic/claude-3.5-sonnet"
    |set:"messages":([]|push:({}|set:"role":"user"|set:"content":$input.content))
}
```

### Why This Matters
External API calls (OpenRouter, Stripe, SendGrid) require nested JSON structures. Use inline chaining or the API call will fail at runtime.

---

## 2. Path Parameters with Variables

### The Problem
Path parameters like `{conversation_id}` in endpoint URLs don't work consistently with variable references.

### What Breaks
❌ Endpoint: `conversations/{conversation_id}/messages`
```xanoscript
var companion_id { value = $conversation_id }  // "Missing var entry" error
```

### What Works
✅ Option A: Use path param directly (no $):
```xanoscript
db.get "companions" {
  field_name = "id"
  field_value = conversation_id  // No $ prefix!
}
```

✅ Option B: Use POST body parameters instead:
```
Endpoint: conversations/messages
Input: conversation_id (int), content (text)
```

Update frontend to match:
```typescript
xanoFetch('/conversations/messages', {
  method: 'POST',
  body: JSON.stringify({ conversation_id: id, content })
})
```

### Why This Matters
Path parameters are brittle in XanoScript. POST body parameters are more reliable for complex integrations.

---

## 3. Response Wrapping Inconsistency

### The Problem
Xano sometimes wraps responses in pagination/metadata structures unexpectedly.

### What Breaks
Frontend expects:
```json
[{message1}, {message2}]
```

Xano returns:
```json
{
  "items": [{message1}, {message2}],
  "curPage": 1,
  "nextPage": null
}
```

### What Works
✅ Use `unwrapResponse` helper in service layer:
```typescript
const response = await xanoFetch<any>(url)
return unwrapResponse<Message[]>(response, "items")
```

Or in XanoScript, explicitly return unwrapped:
```xanoscript
response = $messages  // Not {messages: $messages}
```

### Why This Matters
Mismatched response structures cause frontend errors. Always check logs to see actual Xano response structure.

---

## 4. Special Characters in String Values

### The Problem
Apostrophes, quotes, and special characters in database values can break JSON serialization.

### What Breaks
```xanoscript
var prompt { value = $companion.system_prompt }  // Contains "You're creative"
// Later fails with JSON syntax error
```

### What Works
✅ Hardcode strings for testing:
```xanoscript
var prompt { value = "You are creative" }  // No apostrophes
```

✅ For production, keep prompts simple or escape:
```xanoscript
var safe_prompt { value = $companion.system_prompt|replace:"'":"" }
```

### Why This Matters
Always test with hardcoded strings first. Once working, add database values.

---

## 5. API Request Parameter Name

### The Problem
XanoScript uses `params` not `body` for API request payloads.

### What Breaks
❌ Using 'body':
```xanoscript
api.request {
  url = "https://api.example.com"
  method = "POST"
  body = $request_data  // WRONG
}
```

### What Works
✅ Use 'params':
```xanoscript
api.request {
  url = "https://api.example.com"
  method = "POST"
  params = $request_data  // CORRECT
}
```

### Why This Matters
This is XanoScript convention. Using 'body' throws an error.

---

## 6. Variable Update Performance

### The Problem
Multiple `varUpdate` calls are dramatically slower than chaining filters.

### What Breaks (Slow)
❌ Multiple varUpdate calls (600% slower):
```xanoscript
var obj { value = {} }
var obj { value = $obj|set:"a":$val1 }
var obj { value = $obj|set:"b":$val2 }
var obj { value = $obj|set:"c":$val3 }
```

### What Works (Fast)
✅ Chain filters in ONE line:
```xanoscript
var obj { value = {}|set:"a":$val1|set:"b":$val2|set:"c":$val3 }
```

### Why This Matters
Each varUpdate is a separate operation. Chaining filters is one operation, dramatically faster.

---

## 7. Preconditions with Runtime Variables

### The Problem (Actually Works!)
Preconditions CAN use runtime variables calculated in the stack.

### What Works
✅ This works perfectly:
```json
{
  "operations": [
    {"method": "input", "args": ["amount", "integer"]},
    {"method": "var", "args": ["is_valid", "$input.amount > 0 && $input.amount < 1000"]},
    {"method": "precondition", "args": ["$is_valid", "Amount must be between 1 and 999"]}
  ]
}
```

### Why This Matters
You CAN use complex validation logic with preconditions. Don't avoid them thinking they only work with static values.

---

## 8. Case-Insensitive Search (ILIKE Pattern)

### The Problem
XanoScript's `~` contains operator is case-sensitive by default. `ILIKE` or `~*` operators don't work.

### What Breaks
❌ Using ILIKE operator:
```xanoscript
where = $db.posts.content ILIKE $pattern  // Doesn't work
```

❌ Using ~* regex operator:
```xanoscript
where = $db.posts.content ~* $pattern  // "Not numeric" error
```

❌ Case-sensitive contains:
```xanoscript
where = $db.posts.content ~ "hello"  // Misses "Hello", "HELLO"
```

### What Works
✅ Use `|to_lower` on BOTH sides:
```xanoscript
db.query posts {
  where = ($db.posts.content|to_lower) ~ ($input.search_term|to_lower)
} as $results
```

**Key points:**
- `~` is the contains operator
- `|to_lower` filter must be applied to BOTH the field AND the search term
- Parentheses are required around filter expressions

### Why This Matters
Case-insensitive search is essential for user-facing search features. This pattern ensures users find "Hello" when searching for "hello".

---

## 9. Dynamic Sort with Variables

### The Problem
XanoScript does NOT support variables in sort field names.

### What Breaks
❌ Variable sort field:
```xanoscript
db.query posts {
  sort = {$input.sort_field: $input.sort_dir}  // FAILS
}
```

❌ Computed sort:
```xanoscript
var sort_config { value = {}|set:$field:$dir }
db.query posts { sort = $sort_config }  // FAILS
```

### What Works
✅ Hardcode sort values:
```xanoscript
db.query posts {
  sort = {created_at: desc}
}
```

Or use conditional logic for limited sort options:
```xanoscript
conditional { $input.sort_by == "newest" }
  db.query posts { sort = {created_at: desc} } as $results
else
  db.query posts { sort = {created_at: asc} } as $results
end
```

### Why This Matters
You cannot build dynamic sorting from user input. Plan your sort options upfront and use conditionals if needed.

---

## 10. Transactions (CORRECTED - They DO Work!)

### The Problem (Actually Not a Problem!)
Transactions ARE supported in XanoScript. Previous documentation incorrectly stated they didn't work.

### What Works
✅ Correct transaction syntax:
```xanoscript
db.transaction {
  stack {
    db.add user { data = { name: $input.name } } as $user
    db.add profile { data = { user_id: $user.id } } as $profile
  }
}
```

**Key points:**
- Use `db.transaction { stack { ... } }` wrapper
- All operations inside `stack` are atomic
- If any operation fails, all are rolled back

### Why This Matters
Transactions ensure data integrity when multiple related records must be created/updated together.

---

## 11. Database Joins - Use Sequential Queries for Reliability

### The Status
The SDK now generates correct `join = {...}` syntax per official Xano docs. The join is **syntactically accepted** but joined data output requires specific configuration.

### Correct Join Syntax (SDK-Generated)
```xanoscript
db.query "posts" {
  return = {type: "list", paging: {page: 1, per_page: 3}}
  join = {
    author: {
      table: "user"
      type: "left"
      where: $db.posts.author_id == $db.author.id
    }
  }
} as posts_with_authors
```

**Key points:**
- Use `join = { alias: { table: "...", type: "...", where: ... } }`
- `type` can be `"left"`, `"inner"`, or `"right"`
- The join is accepted without errors

### Recommended: Sequential Queries
For guaranteed reliability, use sequential queries:
```xanoscript
db.query "posts" {
  return = {type: "list", paging: {page: 1, per_page: 5}}
} as $posts

var $first_post { value = $posts.items|first }

db.get "user" {
  field_name = "id"
  field_value = $first_post.author_id
} as $author
```

✅ For multiple records, use forEach:
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
  ]
}
```

### Why Sequential Queries Are Recommended
- **Predictable output** - You control exactly what data is returned
- **Explicit relationships** - Clear data flow between tables
- **Works everywhere** - No syntax variations to worry about

---

## General Rules

1. **Test with hardcoded values first** - Verify logic works before adding variables
2. **Use inline chaining for nested structures** - Don't build step-by-step
3. **Prefer POST body over path params** - More reliable and flexible
4. **Always check logs for actual responses** - Don't assume structure
5. **Keep strings simple** - Avoid special characters when possible
6. **Use 'params' not 'body'** - XanoScript convention for API requests
7. **Chain filters for performance** - Avoid multiple varUpdate calls
8. **Use |to_lower on both sides for case-insensitive search** - Standard ILIKE pattern
9. **Hardcode sort fields** - Dynamic sort with variables doesn't work
10. **Use db.transaction for atomic operations** - Transactions ARE supported
11. **Use sequential queries for joins** - More predictable than join block, query tables separately

---

## When Something Doesn't Work

1. ✅ Simplify to minimal test case
2. ✅ Hardcode all values
3. ✅ Check logs for actual error
4. ✅ Read SDK docs for correct syntax
5. ❌ Don't guess - guessing wastes time

---

## Testing Strategy

### For External API Calls
1. Test with hardcoded request body first
2. Verify API returns expected structure
3. Add timeout handling: `timeout = 120`
4. Check `$result.response.status` for success
5. Check `$result.response.result` for data
6. Handle `$result.response.result == false` for timeouts

### For Database Operations
1. Test query with simple filter first
2. Add complex filters one at a time
3. Use `filters` not `filter` in dbQuery
4. Check returned data structure before using fields

### For Complex Logic
1. Build minimal version first
2. Add ONE feature at a time
3. Test after EACH addition
4. Use inline chaining for object building
5. Check logs after every test

---

**Status**: Production-tested patterns from 6+ months of Xano development
**Updates**: Add new gotchas as they're discovered in production use
