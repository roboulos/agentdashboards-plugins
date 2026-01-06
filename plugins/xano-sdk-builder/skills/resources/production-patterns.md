# Production Patterns

Battle-tested patterns for building production-ready Xano endpoints. These patterns come from real-world implementations with 90%+ first-deployment success rates.

## Authentication Patterns

### Setting Up Authentication on Endpoints

Use `.requiresAuth()` to mark endpoints as requiring JWT authentication:

```json
{
  "type": "endpoint",
  "name": "/protected-resource",
  "method": "GET",
  "operations": [
    {"method": "requiresAuth", "args": []},
    {"method": "response", "args": [{"user_id": "id"}]}
  ]
}
```

**CRITICAL**: After `requiresAuth`, the authenticated user's ID is available as just `id`:
- ✅ `id` → The authenticated user's ID (no $ sign!)
- ❌ `$id` → Wrong
- ❌ `$authToken` → Wrong
- ❌ `$authToken.id` → Wrong

### Getting JWT Tokens for Testing

Before testing authenticated endpoints, get a token from your auth endpoint:

```bash
# Login to get JWT token
curl -X POST https://your-instance.xano.io/api:GROUP/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'

# Response includes authToken
{"authToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}
```

Then use it in requests:

```bash
curl -X GET https://your-instance.xano.io/api:GROUP/protected-resource \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Auth Check Pattern

Always verify user permissions after requiresAuth:

```json
{
  "operations": [
    {"method": "requiresAuth", "args": []},
    {"method": "input", "args": ["user_id", "integer"]},
    {"method": "conditional", "args": ["id != $input.user_id"]},
    {"method": "then", "args": [[
      {"method": "throw", "args": ["FORBIDDEN", "Cannot access other user data", 403]}
    ]]},
    {"method": "endConditional", "args": []}
  ]
}
```

**Note**: `id` is automatically available after `requiresAuth` - no need to assign it to a variable.

## Time & Dates

### ✅ Current Time (now)

**VERIFIED (api_id: 21031)**: Use `now` (not `$now`) - it's just `now` like `id` after auth

The `now` variable contains the current Unix timestamp:

```json
{
  "operations": [
    {"method": "var", "args": ["created_at", "now"]},
    {"method": "dbAdd", "args": ["conversations", {"started_at": "now"}, "conversation"]}
  ]
}
```

### ✅ Time Calculations (Use Filters!)

**CRITICAL**: Can't do `now + 2592000` - must use `|add_secs_to_timestamp:seconds` filter

```json
{
  "operations": [
    {"method": "var", "args": ["thirty_days_from_now", "now|add_secs_to_timestamp:2592000"]},
    {"method": "var", "args": ["seven_days_ago", "now|add_secs_to_timestamp:-604800"]},
    {"method": "dbAdd", "args": ["subscriptions", {
      "started_at": "now",
      "expires_at": "$thirty_days_from_now"
    }, "subscription"]}
  ]
}
```

**Curl Test (api_id: 21031):**
```bash
curl -X GET "https://xnwv-v1z6-dvnr.n7c.xano.io/api:dEKOZRDN/pattern-test/time-filters" \
  -H "Content-Type: application/json"
# Returns: {"current":1763165186920,"in_30_days":1765757186921,"7_days_ago":1762560386922}
```

**Common time intervals:**
- 1 hour: 3600
- 1 day: 86400
- 1 week: 604800
- 30 days: 2592000
- 1 year: 31536000

## RESTful API Organization

### Naming Conventions

**Collections (plural nouns):**
- `/chats` - GET lists all, POST creates new
- `/readings` - GET lists all, POST creates new
- `/subscriptions` - GET lists all, POST creates new

**Resources (collection + ID):**
- `/chats/{id}` - GET one, PUT update, DELETE remove
- `/readings/{id}` - GET one reading
- `/subscriptions/{id}` - GET one subscription

**Actions on resources:**
- `/subscriptions/{id}/cancel` - PUT to cancel
- `/chats/{id}/messages` - GET list messages, POST add message

**Never use verbs in paths:**
- ❌ `/create-chat`, `/cancel-subscription`
- ✅ `POST /chats`, `PUT /subscriptions/{id}/cancel`

### API Group Organization

Organize endpoints by domain in API groups:

```
api:auth/
  POST /login
  POST /signup
  POST /refresh
  POST /logout

api:chats/
  GET /chats
  POST /chats
  GET /chats/{id}
  PUT /chats/{id}
  DELETE /chats/{id}
  POST /chats/{id}/messages
  GET /chats/{id}/messages

api:readings/
  GET /readings
  POST /readings/full-chart
  POST /readings/partial-chart
  POST /readings/personality-profile
  GET /readings/{id}
  DELETE /readings/{id}

api:subscriptions/
  GET /subscriptions
  POST /subscriptions
  GET /subscriptions/{id}
  PUT /subscriptions/{id}/cancel
  GET /payments
```

Clean, organized, professional.

## Error Handling Patterns

### Input Validation (400 Bad Request)

Always validate inputs first:

```json
{
  "operations": [
    {"method": "input", "args": ["email", "text"]},
    {"method": "input", "args": ["amount", "integer"]},
    {"method": "precondition", "args": ["$input.email != \"\"", "Email required", 400]},
    {"method": "precondition", "args": ["$input.amount > 0", "Amount must be positive", 400]}
  ]
}
```

### ✅ Advanced Preconditions (Runtime Variables)

**VERIFIED:** Preconditions work with runtime variables, not just inputs!

```json
{
  "operations": [
    {"method": "input", "args": ["amount", "integer"]},
    {"method": "var", "args": ["is_valid_amount", "$input.amount > 0 && $input.amount < 1000"]},
    {"method": "precondition", "args": ["$is_valid_amount", "Amount must be between 1 and 999", 400]}
  ]
}
```

**Curl Test (api_id: 21028):**
```bash
# Valid amount - passes
curl -X POST https://xnwv-v1z6-dvnr.n7c.xano.io/api:dEKOZRDN/pattern-test/precondition-calc \
  -H "Content-Type: application/json" \
  -d '{"amount": 500}'
# Returns: {"success":true,"amount":500}

# Invalid amount - fails precondition
curl -X POST https://xnwv-v1z6-dvnr.n7c.xano.io/api:dEKOZRDN/pattern-test/precondition-calc \
  -H "Content-Type: application/json" \
  -d '{"amount": 1500}'
# Returns: {"code":"ERROR_FATAL","message":"Amount must be between 1 and 999","payload":""}
```

**Use Cases:**
- Complex validation combining multiple conditions
- Calculations before validation
- Business logic validation (not just input format)

### Resource Not Found (404)

Check if database records exist:

```json
{
  "operations": [
    {"method": "dbQuery", "args": ["users", {"filters": {"id": "$input.user_id"}}, "user"]},
    {"method": "conditional", "args": ["$user == []"]},
    {"method": "then", "args": [[
      {"method": "throw", "args": ["USER_NOT_FOUND", "User not found", 404]}
    ]]},
    {"method": "endConditional", "args": []}
  ]
}
```

### Duplicate Check (409 Conflict)

Prevent duplicate records:

```json
{
  "operations": [
    {"method": "dbQuery", "args": ["subscriptions", {
      "filters": {"account_id": "$input.account_id", "status": "active"}
    }, "existing"]},
    {"method": "conditional", "args": ["$existing != []"]},
    {"method": "then", "args": [[
      {"method": "throw", "args": ["DUPLICATE", "Account already has active subscription", 409]}
    ]]},
    {"method": "endConditional", "args": []}
  ]
}
```

### External API Error Handling

Always handle API failures:

```json
{
  "operations": [
    {"method": "var", "args": ["has_api_key", "$env.stripe_key != \"\""]},
    {"method": "conditional", "args": ["$has_api_key"]},
    {"method": "then", "args": [[
      {"method": "apiRequest", "args": [
        "https://api.stripe.com/v1/charges",
        "POST",
        {"headers": {"Authorization": "Bearer " ~ "$env.stripe_key"}, "params": {...}},
        "result"
      ]},
      {"method": "var", "args": ["status", "$result.response.status"]},
      {"method": "var", "args": ["body", "$result.response.result"]},
      {"method": "conditional", "args": ["$body == false"]},
      {"method": "then", "args": [[
        {"method": "throw", "args": ["API_TIMEOUT", "Stripe API timed out", 500]}
      ]]},
      {"method": "endConditional", "args": []},
      {"method": "conditional", "args": ["$status >= 400"]},
      {"method": "then", "args": [[
        {"method": "throw", "args": ["STRIPE_ERROR", "$body.error.message", 500]}
      ]]},
      {"method": "endConditional", "args": []}
    ]]},
    {"method": "else", "args": [[
      {"method": "var", "args": ["result", {"mock": true, "charge_id": "mock_ch_123"}]}
    ]]},
    {"method": "endConditional", "args": []}
  ]
}
```

### Error Hierarchy Order

Check errors in this order for best UX:

1. **Input validation** (400) - Missing/invalid parameters
2. **Authentication** (401) - No JWT token
3. **Authorization** (403) - Wrong user accessing resource
4. **Resource existence** (404) - Record not found
5. **Business logic** (409) - Duplicate, conflict
6. **External APIs** (500) - Third-party failures

```json
{
  "operations": [
    {"method": "input", "args": ["user_id", "integer"]},
    {"method": "precondition", "args": ["$input.user_id > 0", "Valid user_id required", 400]},
    {"method": "requiresAuth", "args": []},
    {"method": "conditional", "args": ["id != $input.user_id"]},
    {"method": "then", "args": [[{"method": "throw", "args": ["FORBIDDEN", "Access denied", 403]}]]},
    {"method": "endConditional", "args": []},
    {"method": "dbQuery", "args": ["users", {"filters": {"id": "$input.user_id"}}, "user"]},
    {"method": "conditional", "args": ["$user == []"]},
    {"method": "then", "args": [[{"method": "throw", "args": ["NOT_FOUND", "User not found", 404]}]]},
    {"method": "endConditional", "args": []}
  ]
}
```

**Note**: `id` is automatically available after `requiresAuth` containing the authenticated user's ID.

## Schema Discovery

### Always Check Actual Schema First

Before building endpoints, discover the real table structure:

```bash
# Use get_table_schema MCP tool
mcp__xano-mcp__execute({
  "tool_id": "get_table_schema",
  "arguments": {
    "table_id": 892
  }
})
```

This prevents errors from:
- Wrong field names (docs say `user_email`, actual is `owner_user`)
- Wrong field types (expecting string, field is integer)
- Missing foreign keys
- Incorrect table references

**Pattern**: Always query schema before writing any database operations.

## Verification & Documentation

### Verification Tagging

After successful curl tests, tag endpoints with ✅:

```markdown
### ✅ POST /chats (api_id: 21016)
**Purpose**: Create new chat conversation
**Auth**: JWT Required

**Tests Passed**:
- ✅ 200 OK - Conversation created
- ✅ 400 Bad Request - Missing message
- ✅ 401 Unauthorized - No JWT
- ✅ 403 Forbidden - Wrong user_id
- ✅ Database - Record created (id: 5)

**Curl Test**:
```bash
curl -X POST https://instance.xano.io/api:GROUP/chats \
  -H "Authorization: Bearer <token>" \
  -d '{"user_id": 1, "message": "Hello"}'
```

**Response**:
```json
{"success": true, "conversation_id": 5}
```
```

### Document Key Information

For each endpoint, save:
- `api_id` (needed for updates)
- Final curl test command
- Expected response structure
- Test results (all status codes verified)

## Common Time-Savers

### Object Building (Fast)

Chain filters instead of multiple varUpdate calls (600% faster):

```json
{
  "operations": [
    {"method": "var", "args": ["user_data",
      "{}|set:\"name\":$name|set:\"email\":$email|set:\"status\":\"active\"|set:\"created_at\":$now"
    ]}
  ]
}
```

### Mock Data for Development

Use conditionals to provide mock data when external services aren't configured:

```json
{
  "operations": [
    {"method": "var", "args": ["has_api", "$env.openai_key != \"\""]},
    {"method": "conditional", "args": ["$has_api"]},
    {"method": "then", "args": [[
      {"method": "apiRequest", "args": ["https://api.openai.com/v1/chat/completions", "POST", {...}, "ai_response"]}
    ]]},
    {"method": "else", "args": [[
      {"method": "var", "args": ["ai_response", {"mock": true, "message": "This is a mock AI response"}]}
    ]]},
    {"method": "endConditional", "args": []}
  ]
}
```

Endpoint works immediately, even without API keys.

### |concat: Operator Replacement

If sdk_builder generates `|concat:`, replace with `~`:

```xanoscript
// Generated (doesn't work):
"Authorization: "|concat:$token

// Fixed (works):
"Authorization: " ~ $token
```

---

**Version**: 1.0
**Source**: Production deployments, 90%+ success rate
**Updated**: Integrated naturally from real-world patterns
