# SDK API & External Call Methods

HTTP requests, webhooks, external API integration, GraphQL, OAuth, and microservice calls.

## Table of Contents
- [HTTP Requests](#http-requests)
- [API Request Options](#api-request-options)
- [Special Protocols](#special-protocols)
- [Advanced Patterns](#advanced-patterns)
- [Task & Function Calls](#task--function-calls)

---

## HTTP Requests

**2 core HTTP methods** for making external API calls.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `apiRequest(url,method,options?,alias?)` | url:string, method:HttpMethod, options?:ApiRequestOptions, alias?:string | this | Generic API request (use for all HTTP methods) |
| `externalApi(url,method,options?,alias?)` | url:string, method:HttpMethod, options?:ApiRequestOptions, alias?:string | this | External API call (alias for apiRequest) |

**IMPORTANT:** Methods like `apiGet()`, `apiPost()`, `apiPut()`, `apiPatch()`, `apiDelete()` do NOT exist. Use `apiRequest()` with the appropriate HTTP method string instead.

**HTTP Method Examples:**
- GET: `apiRequest(url, "GET", options, alias)`
- POST: `apiRequest(url, "POST", options, alias)`
- PUT: `apiRequest(url, "PUT", options, alias)`
- PATCH: `apiRequest(url, "PATCH", options, alias)`
- DELETE: `apiRequest(url, "DELETE", options, alias)`

---

## API Request Options

**ApiRequestOptions object structure:**

```typescript
{
  headers?: Record<string, string>;     // HTTP headers
  body?: object | string;               // JSON body (POST/PUT/PATCH)
  params?: object;                      // Form-encoded data (URL-encoded body)
  query?: object;                       // URL query parameters (?key=value)
  timeout?: number;                     // Request timeout in milliseconds
  auth?: { username: string, password: string };  // Basic auth
  cookies?: Record<string, string>;     // Cookies to send
}
```

**Content-Type Behavior:**

| Use Case | Property | Content-Type | Example |
|----------|----------|--------------|---------|
| JSON API (REST, GraphQL) | `body` | `application/json` | GitHub API, OpenAI |
| Form-Encoded (Stripe, Twilio) | `params` | `application/x-www-form-urlencoded` | Stripe Checkout, SendGrid forms |
| Query Parameters | `query` | (appended to URL) | Search, filtering, pagination |

### JSON Request Example

**⚠️ SDK BUILDER LIMITATION:** The `sdk_builder` tool does NOT correctly process header concatenation. You must pre-build headers as a variable string.

**✅ VERIFIED WORKING PATTERN (Tested 2025-01-25):**

```json
{
  "operations": [
    {"method": "var", "args": ["headers", "[]|push:(\"Authorization: Bearer\"|concat:$env.API_KEY:\" \")|push:\"Content-Type: application/json\""]},
    {
      "method": "apiRequest",
      "args": [
        "https://api.example.com/users",
        "POST",
        {
          "headers": "$headers",
          "params": {"name": "$user_name", "email": "$user_email"}
        },
        "result"
      ]
    }
  ]
}
```

**This generates correct XanoScript:**

```xanoscript
var headers {
  value = []
    |push:("Authorization: Bearer"
      |concat:$env.API_KEY:" "
    )
    |push:"Content-Type: application/json"
}

api.request {
  url = "https://api.example.com/users"
  method = "POST"
  headers = $headers
  params = {}
    |set:"name":$user_name
    |set:"email":$user_email
  timeout = 60
} as result
```

**Key points:**
- Pre-build headers as a variable with the FULL filter chain
- `|concat:$env.API_KEY:" "` joins with space separator (space is the THIRD argument)
- Use `params` not `body` for the request payload
- Result: `Authorization: Bearer sk-xxx...`

**❌ DO NOT USE (SDK builder mangles this):**
```json
{
  "headers": [
    {"Authorization": "Bearer " + "$env.API_KEY"}
  ]
}
```

### Form-Encoded Request Example (Stripe)

**✅ VERIFIED WORKING PATTERN:**

```json
{
  "operations": [
    {"method": "var", "args": ["headers", "[]|push:(\"Authorization: Bearer\"|concat:$env.STRIPE_SECRET_KEY:\" \")|push:\"Content-Type: application/x-www-form-urlencoded\""]},
    {
      "method": "apiRequest",
      "args": [
        "https://api.stripe.com/v1/checkout/sessions",
        "POST",
        {
          "headers": "$headers",
          "params": {"mode": "payment", "success_url": "$success_url", "cancel_url": "$cancel_url"}
        },
        "result"
      ]
    }
  ]
}
```

### Query Parameters Example

```json
{
  "operations": [
    {"method": "apiRequest", "args": ["https://api.example.com/search", "GET", {"query": {"q": "$input.search", "page": 1, "limit": 10}}, "result"]}
  ]
}
```

Results in: `/search?q=value&page=1&limit=10`

### Response Structure

After calling `.apiRequest()`, the result variable contains:

```javascript
{
  response: {
    status: 200,           // ← HTTP status code
    headers: { ... },      // ← Response headers
    result: {              // ← Response body
      // ... API response data
    }
  }
}
```

### Accessing Response Data

```json
{
  "operations": [
    {"method": "var", "args": ["status", "$result.response.status"]},
    {"method": "var", "args": ["body", "$result.response.result"]},
    {"method": "var", "args": ["data", "$result.response.result.data"]},
    {"method": "var", "args": ["error", "$result.response.result.error.message"]}
  ]
}
```

**Common Status Codes:**
- `200-299`: Success
- `400`: Bad request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not found
- `429`: Rate limited
- `500-599`: Server error

---

## Special Protocols

**4 methods** for GraphQL, SOAP, Webhooks, and OAuth.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `apiGraphql(url,query,variables?,headers?,alias?)` | url:string, query:string, variables?:Record, headers?:Record, alias?:string | this | GraphQL query (note: lowercase 'ql') |
| `apiSoap(url,action,body,headers?,alias?)` | url:string, action:string, body:any, headers?:Record, alias?:string | this | SOAP request |
| `apiWebhook(config,alias?)` | config:{method?:string,path:string,verify?:any}, alias?:string | this | Webhook receiver |
| `apiOAuth(action,config,alias?)` | action:'authorize'\|'token'\|'refresh', config:any, alias?:string | this | OAuth flow |

**IMPORTANT:** The method is `apiGraphql()` with lowercase 'ql', not `apiGraphQL()`.

---

## Advanced Patterns

**3 methods** for retry logic, circuit breakers, and batch operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `apiRetry(operation,maxAttempts,delay,alias?)` | operation:string, maxAttempts:number, delay:number, alias?:string | this | Retry with backoff |
| `apiCircuitBreaker(operation,threshold,timeout,alias?)` | operation:string, threshold:number, timeout:number, alias?:string | this | Circuit breaker pattern |
| `apiBatch(operations,alias?)` | operations:Array<{method:string,url:string,body?:any}>, alias?:string | this | Batch API calls |

---

## Function Calls

**1 method** for executing custom functions.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `functionRun(functionName,input,alias)` | functionName:string, input:Record, alias:string | this | Execute custom function |

**Note:** Background tasks cannot be called programmatically - they only run on schedules defined in the `task` primitive.

### Example

```json
{
  "operations": [
    {"method": "input", "args": ["user_email", "email"]},
    {"method": "functionRun", "args": ["utilities/validate_email", {"email": "$input.user_email"}, "validation_result"]},
    {"method": "conditional", "args": ["$validation_result.is_valid == true"]},
    {"method": "response", "args": [{"success": true}]},
    {"method": "else"},
    {"method": "response", "args": [{"success": false, "error": "Invalid email"}, 400]},
    {"method": "endConditional"}
  ]
}
```

**Generated XanoScript:**
```xanoscript
function.run utilities/validate_email {
  input = {email: $input.user_email}
} as $validation_result

conditional {
  if ($validation_result.is_valid == true) {
    return { value = {success: true} }
  }
  else {
    return { value = {success: false, error: "Invalid email"}, status = 400 }
  }
}
```

**Use cases:**
- Reusable validation logic
- Shared business rules across multiple endpoints
- Complex calculations that need to be centralized
- Data transformation utilities

---

## Streaming & Real-time

**4 methods** for streaming and real-time communication (⚠️ PROPOSED).

| Method | Params | Returns | Purpose | Status |
|--------|--------|---------|---------|--------|
| `apiLambda(functionName,payload,alias?)` | functionName:string, payload:any, alias?:string | this | Execute Lambda function | ⚠️ PROPOSED |
| `streamFromRequest(url,method,options?,alias?)` | url:string, method:string, options?:ApiRequestOptions, alias?:string | this | Stream data from API response | ⚠️ PROPOSED |
| `apiStream(data?)` | data?:any | this | Stream response to client | ⚠️ PROPOSED |
| `realtimeEvent(eventName,data,alias?)` | eventName:string, data:any, alias?:string | this | Send realtime event to connected clients | ⚠️ PROPOSED |

**Status:** These methods would provide SDK wrappers for raw XanoScript streaming and Lambda execution functions.

### Examples

**⚠️ PROPOSED: Lambda Execution:**

```json
{
  "operations": [
    {"method": "input", "args": ["user_data", "json"]},
    {"method": "apiLambda", "args": ["process_user_data", {"user": "$input.user_data"}, "lambda_result"]},
    {"method": "conditional", "args": ["$lambda_result.statusCode == 200"]},
    {"method": "response", "args": [{"success": true, "data": "$lambda_result.body"}]},
    {"method": "else"},
    {"method": "response", "args": [{"success": false, "error": "$lambda_result.errorMessage"}, 500]},
    {"method": "endConditional"}
  ]
}
```

**Raw XanoScript equivalent:**
```xanoscript
api.lambda {
  function_name = "process_user_data"
  payload = {user: $input.user_data}
} as lambda_result

conditional {
  if ($lambda_result.statusCode == 200) {
    return { value = {success: true, data: $lambda_result.body} }
  }
  else {
    return { value = {success: false, error: $lambda_result.errorMessage}, status = 500 }
  }
}
```

**⚠️ PROPOSED: Streaming API Request:**

```json
{
  "operations": [
    {"method": "input", "args": ["search_query", "text"]},
    {"method": "var", "args": ["headers", "[]|push:(\"Authorization: Bearer\"|concat:$env.API_KEY:\" \")|push:\"Content-Type: application/json\""]},
    {"method": "streamFromRequest", "args": ["https://api.example.com/stream", "POST", {
      "headers": "$headers",
      "params": {"query": "$input.search_query"}
    }, "stream"]},
    {"method": "var", "args": ["results", "[]"]},
    {"method": "forEach", "args": ["$stream", "chunk"]},
    {"method": "var", "args": ["results", "$results|push:$chunk"]},
    {"method": "endForEach"},
    {"method": "response", "args": [{"data": "$results"}]}
  ]
}
```

**Raw XanoScript equivalent:**

```xanoscript
stream.from_request {
  url = "https://api.example.com/stream"
  method = "POST"
  headers = []
    |push:("Authorization: Bearer"
      |concat:$env.API_KEY:" "
    )
    |push:"Content-Type: application/json"
  body = {query: $input.search_query}
} as stream

var results { value = [] }

for (stream as $chunk) {
  var results { value = $results|push:$chunk }
}

response = {data: $results}
```

**⚠️ PROPOSED: Streaming Response:**

```json
{
  "operations": [
    {"method": "input", "args": ["data_array", "json"]},
    {"method": "forEach", "args": ["$input.data_array", "item"]},
    {"method": "apiStream", "args": ["$item"]},
    {"method": "utilSleep", "args": [0.1]},
    {"method": "endForEach"}
  ]
}
```

**Raw XanoScript equivalent:**
```xanoscript
for ($input.data_array as $item) {
  api.stream { value = $item }
  util.sleep { seconds = 0.1 }
}
```

**⚠️ PROPOSED: Realtime Event:**

```json
{
  "operations": [
    {"method": "input", "args": ["notification", "json"]},
    {"method": "dbAdd", "args": ["notifications", "$input.notification", "notification"]},
    {"method": "realtimeEvent", "args": ["notification_created", {"id": "$notification.id", "message": "$notification.message"}, "event_result"]},
    {"method": "response", "args": [{"success": true, "notification": "$notification"}]}
  ]
}
```

**Raw XanoScript equivalent:**
```xanoscript
db.add {
  table = "notifications"
  data = $input.notification
} as notification

api.realtime_event {
  event = "notification_created"
  data = {id: $notification.id, message: $notification.message}
} as event_result

response = {success: true, notification: $notification}
```

**Use cases for streaming & realtime:**
- Lambda/serverless function execution
- Processing large API responses without memory issues
- Streaming AI completions to client
- Real-time notifications to connected clients
- Progressive data loading

---

## ✅ Production-Verified Complete Example

**RAG Embedding Endpoint (Tested 2025-01-25)**

This endpoint was tested and verified working with OpenRouter API:

**SDK JSON:**

```json
{
  "type": "endpoint",
  "name": "/rag/generate-embedding",
  "method": "POST",
  "operations": [
    {"method": "input", "args": ["content", "text"]},
    {"method": "var", "args": ["headers", "[]|push:(\"Authorization: Bearer\"|concat:$env.openrouter_api_key:\" \")|push:\"Content-Type: application/json\""]},
    {
      "method": "apiRequest",
      "args": [
        "https://openrouter.ai/api/v1/embeddings",
        "POST",
        {
          "headers": "$headers",
          "params": {"model": "openai/text-embedding-3-small", "input": "$input.content"},
          "timeout": 60
        },
        "api_response"
      ]
    },
    {"method": "response", "args": [{"success": true, "embedding": "$api_response.response.result.data[0].embedding", "model": "$api_response.response.result.model", "usage": "$api_response.response.result.usage"}]}
  ]
}
```

**Generated XanoScript (verified working):**

```xanoscript
query "rag-generate-embedding" verb=POST {
  input {
    text content
  }

  stack {
    var headers {
      value = []
        |push:("Authorization: Bearer"
          |concat:$env.openrouter_api_key:" "
        )
        |push:"Content-Type: application/json"
    }

    api.request {
      url = "https://openrouter.ai/api/v1/embeddings"
      method = "POST"
      headers = $headers
      params = {}
        |set:"model":"openai/text-embedding-3-small"
        |set:"input":$input.content
      timeout = 60
    } as $api_response
  }

  response = {
    success: true
    embedding: $api_response.response.result.data[0].embedding
    model: $api_response.response.result.model
    usage: $api_response.response.result.usage
  }
}
```

**Test result:**

```bash
curl -X POST "https://xnwv-v1z6-dvnr.n7c.xano.io/api:0clkHGr3/rag-generate-embedding" \
  -H "Content-Type: application/json" \
  -d '{"content": "Hello world test"}'

# Response:
# {
#   "success": true,
#   "embedding": [-0.012954721, -0.0481297, ...],  # 1536 dimensions
#   "model": "text-embedding-3-small",
#   "usage": {"prompt_tokens": 3, "total_tokens": 3}
# }
```

---

**Total Methods in this File: 13**

- 2 core HTTP methods (apiRequest, externalApi)
- 4 special protocols (apiGraphql, apiSoap, apiWebhook, apiOAuth)
- 3 advanced patterns (apiRetry, apiCircuitBreaker, apiBatch)
- 1 function call (functionRun)
- 4 streaming & real-time methods (⚠️ PROPOSED: apiLambda, streamFromRequest, apiStream, realtimeEvent) - not yet in SDK

**Verification Status:**

- Last verified: 2025-01-25
- Header syntax verified with production endpoint
- Methods removed: `callTask()`, `callFunction()`, `apiCall()`, `microservice()` (fake/incorrect)
- Methods removed: `apiGet()`, `apiPost()`, `apiPut()`, `apiPatch()`, `apiDelete()` (not supported)
- Method corrected: `callFunction()` → `functionRun()` (verified working)
- Use `apiRequest(url, "METHOD", options, alias)` for all HTTP methods
- Case sensitivity note: `apiGraphql()` with lowercase 'ql'

For workflow guidance, see [workflow.md](workflow.md)
For complete examples, see [examples.md](examples.md)
