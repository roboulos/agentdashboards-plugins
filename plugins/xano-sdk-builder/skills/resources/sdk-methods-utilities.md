# SDK Utility Methods

Debugging, logging, date/time, testing, tasks, streams, and helper utilities.

## Table of Contents
- [Debugging & Logging](#debugging--logging)
- [Date & Time Utilities](#date--time-utilities)
- [General Utilities](#general-utilities)
- [Testing Methods](#testing-methods)
- [Task Methods](#task-methods)

---

## Debugging & Logging

**6 methods** for debugging and logging.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `debugLog(value)` | value:any | this | Log for debugging |
| `log(value)` | value:any | this | Alias for `.debugLog()` |
| `debugStop(value?)` | value?:any | this | Stop execution with debug output |
| `debug(value)` | value:any | this | Alias for `.debugStop()` |
| `debugDescribe(value)` | value:string | this | Add debug description |
| `debugStack()` | - | this | Log call stack |

### Examples

```json
{
  "operations": [
    {"method": "debugLog", "args": ["$user"]},
    {"method": "debugStop", "args": [{"step": "validation", "data": "$input"}]},
    {"method": "debugDescribe", "args": ["Processing user data"]}
  ]
}
```

---

## Date & Time Utilities

**4 methods** for date/time operations.

| Method | Params | Returns | Purpose | Status |
|--------|--------|---------|---------|--------|
| `utilTime(alias?)` | alias?:string | this | Get current Unix timestamp (auto-converts to 'now') | ✅ WORKS |
| `utilDate(alias?)` | alias?:string | this | Get current date (auto-converts to 'today') | ❌ **BROKEN** - generates invalid 'today' keyword |
| `utilTimestamp(alias?)` | alias?:string | this | Get ISO timestamp (auto-converts to 'now') | ✅ WORKS |
| `utilFormatDate(timestamp,format,alias?)` | timestamp:string\|number, format:string, alias?:string | this | Format date | ✅ WORKS |

**⚠️ CRITICAL BUG:** `utilDate()` generates `value = today` which causes "Syntax error: unexpected 'today'" - **only `now` exists in XanoScript, not `today`**

**Examples (working methods only):**

```json
{
  "operations": [
    {"method": "utilTime", "args": ["current_time"]},
    {"method": "utilTimestamp", "args": ["timestamp"]}
  ]
}
```

**❌ DO NOT USE:**
```json
{
  "operations": [
    {"method": "utilDate", "args": ["today_date"]}
  ],
  "error": "Syntax error: unexpected 'today' - this method is BROKEN"
}
```

**Use XanoScript `now` directly (NOT `today` - it doesn't exist!):**

```json
{
  "operations": [
    {"method": "var", "args": ["current_time", "now"]},
    {"method": "var", "args": ["formatted", "$timestamp|transform_timestamp:\"Y-m-d H:i:s\""]},
    {"method": "var", "args": ["future", "$timestamp|add_secs_to_timestamp:3600"]}
  ]
}
```

**Note:** Only `now` exists in XanoScript. There is NO `today` keyword.

---

## Streaming

**2 methods** for data streaming ✅ **VERIFIED WORKING 2025-01-14**

| Method | Params | Returns | Purpose | Status |
|--------|--------|---------|---------|--------|
| `streamFromCsv(value,separator,enclosure,escapeChar,alias)` | value:string, separator?:string, enclosure?:string, escapeChar?:string, alias:string | this | Create stream from CSV | ✅ **WORKS** |
| `streamFromJsonl(value,alias)` | value:string, alias:string | this | Create stream from JSONL | ✅ **WORKS** |
| `forEachStream(streamVar,itemVar)` | streamVar:string, itemVar:string | this | Iterate over stream | ❌ **NOT IMPLEMENTED** |
| `endForEachStream()` | - | this | End stream iteration | ❌ **NOT IMPLEMENTED** |

**Status:**
- ✅ `streamFromCsv()` and `streamFromJsonl()` WORK - generate valid `stream.from_csv {}` and `stream.from_jsonl {}` XanoScript
- ❌ `forEachStream()` and `endForEachStream()` NOT IMPLEMENTED - use regular `forEach()` with stream variable
- **Tested 2025-01-14:** Both stream creation methods deploy successfully and return `{"stream":"@stream"}` responses

### Examples

**⚠️ PROPOSED: CSV Stream Processing:**

```json
{
  "operations": [
    {"method": "input", "args": ["csv_data", "text"]},
    {"method": "streamFromCsv", "args": ["$input.csv_data", ",", "\"", "\"", "csv_stream"]},
    {"method": "var", "args": ["processed", "[]"]},
    {"method": "forEachStream", "args": ["csv_stream", "row"]},
    {"method": "var", "args": ["email", "$row|get:\"email\""]},
    {"method": "var", "args": ["processed", "$processed|push:$email"]},
    {"method": "endForEachStream"},
    {"method": "response", "args": [{"emails": "$processed"}]}
  ]
}
```

**Raw XanoScript equivalent:**
```xanoscript
stream.from_csv {
  value = $input.csv_data
  separator = ","
  enclosure = '"'
  escape_char = '"'
} as csv_stream

var processed { value = [] }

for (csv_stream as $row) {
  var email { value = $row|get:"email" }
  var processed { value = $processed|push:$email }
}

response = {emails: $processed}
```

**⚠️ PROPOSED: JSONL Stream Processing:**

```json
{
  "operations": [
    {"method": "input", "args": ["jsonl_file", "text"]},
    {"method": "streamFromJsonl", "args": ["$input.jsonl_file", "jsonl_stream"]},
    {"method": "var", "args": ["user_count", 0]},
    {"method": "forEachStream", "args": ["jsonl_stream", "entry"]},
    {"method": "conditional", "args": ["$entry.status == \"active\""]},
    {"method": "varUpdate", "args": ["user_count", "$user_count|add:1"]},
    {"method": "endConditional"},
    {"method": "endForEachStream"},
    {"method": "response", "args": [{"active_users": "$user_count"}]}
  ]
}
```

**Raw XanoScript equivalent:**
```xanoscript
stream.from_jsonl {
  value = $input.jsonl_file
} as jsonl_stream

var user_count { value = 0 }

for (jsonl_stream as $entry) {
  conditional {
    if ($entry.status == "active") {
      var user_count { value = $user_count|add:1 }
    }
  }
}

response = {active_users: $user_count}
```

**Use cases for streams:**
- Processing large CSV files without loading into memory
- Line-by-line JSONL processing
- Efficient handling of big datasets
- Reducing memory footprint for batch operations

---

## General Utilities

**15 methods** for various utility operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `utilRandom(min?,max?,alias?)` | min?:number, max?:number, alias?:string | this | Generate random number |
| `utilSleep(seconds)` | seconds:number\|string | this | Delay execution |
| `utilGetEnv(varName,alias?)` | varName:string, alias?:string | this | Get environment variable |
| `utilSetHeader(name,value)` | name:string, value:string | this | Set HTTP header |
| `utilGetVars(alias)` | alias:string | this | Get all variables |
| `utilGetAllInput(alias)` | alias:string | this | Get all input |
| `utilGetInput(encoding,alias)` | encoding:'json'\|'raw'\|'text', alias:string | this | Get input with encoding |
| `getEnv(alias)` | alias:string | this | Get environment |
| `utilGeoDistance(lat1,lon1,lat2,lon2,alias)` | lat1:number\|string, lon1:number\|string, lat2:number\|string, lon2:number\|string, alias:string | this | Calculate geo distance |
| `utilIpLookup(ip,alias)` | ip:string, alias:string | this | Lookup IP geolocation |
| `utilTemplate(template,alias)` | template:string, alias:string | this | Render template |
| `template(template,alias)` | template:string, alias:string | this | Alias for `.utilTemplate()` |
| `utilTemplateEngine(template,alias?)` | template:string, alias?:string | this | Process template with variables | ✅ VERIFIED 2025-01-13 |
| `delay(milliseconds)` | milliseconds:number\|string | this | Delay (milliseconds) |
| `awaitOperations(ids,timeout,alias)` | ids:string[]\|string, timeout:number, alias:string | this | Await async operations |
| `postProcess()` | - | this | Start post-process block | ❌ **DOES NOT EXIST IN XANOSCRIPT** |
| `endPostProcess()` | - | this | End post-process block | ❌ **DOES NOT EXIST IN XANOSCRIPT** |

**Status:**
- ❌ `postProcess()` and `endPostProcess()` - XanoScript has NO `post_process` keyword (tested 2025-01-14, returns "Syntax error: unexpected 'post_process'")

### Template Engine ✅ VERIFIED 2025-01-13

#### `utilTemplateEngine(template, alias?)` - Process Template Strings

**Description:** Process template strings with variable substitution using `{{variable}}` syntax.

**Parameters:**
- `template` (string) - Template with `{{variable}}` placeholders
- `alias` (string, optional) - Variable to store result

**Example:**
```json
{
  "operations": [
    {"method": "var", "args": ["user", "{\"name\": \"John\", \"role\": \"admin\"}"]},
    {"method": "utilTemplateEngine", "args": [
      "Hello {{user.name}}, you are logged in as {{user.role}}",
      "message"
    ]},
    {"method": "response", "args": [{"message": "$message"}]}
  ]
}
```

**Generated XanoScript:**
```xanoscript
util.template_engine {
  template = "Hello {{user.name}}, you are logged in as {{user.role}}"
} as message
```

**Use Cases:**
- Email template generation
- Dynamic message creation
- Notification formatting
- Report generation with variable data
- Personalized content rendering

**Example - Email Template:**
```json
{
  "operations": [
    {"method": "dbGet", "args": ["users", "$input.user_id", "user"]},
    {"method": "dbGet", "args": ["orders", "$input.order_id", "order"]},
    {"method": "utilTemplateEngine", "args": [
      "Dear {{user.name}},\n\nYour order #{{order.id}} for ${{order.total}} has been confirmed.\n\nThank you!",
      "email_body"
    ]},
    {"method": "response", "args": [{"email": "$email_body"}]}
  ]
}
```

---

### Other Utility Examples

```json
{
  "operations": [
    {"method": "utilGetEnv", "args": ["API_KEY", "api_key"]},
    {"method": "utilSetHeader", "args": ["X-Custom-Header", "value"]},
    {"method": "utilSleep", "args": [2]},
    {"method": "utilGeoDistance", "args": [40.7128, -74.0060, 34.0522, -118.2437, "distance"]}
  ]
}
```

**❌ INVALID: Post-process does NOT exist in XanoScript**

The `post_process {}` block **DOES NOT EXIST** in XanoScript (tested 2025-01-14):
- SDK Builder generates `post_process { stack { ... } }` syntax
- Xano rejects with: **"Syntax error: unexpected 'post_process'"**
- This feature is documented but not implemented in XanoScript

**Workaround:** Use background tasks for async operations after response

---

## Testing Methods

**19 methods** for assertions and testing.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `expectToBeTrue(value,as?)` | value:any, as?:string | this | Assert value is true |
| `expectToBeFalse(value,as?)` | value:any, as?:string | this | Assert value is false |
| `expectToBeDefined(value,as?)` | value:any, as?:string | this | Assert value is defined |
| `expectToNotBeDefined(value,as?)` | value:any, as?:string | this | Assert value not defined |
| `expectToBeNull(value,as?)` | value:any, as?:string | this | Assert value is null |
| `expectToNotBeNull(value,as?)` | value:any, as?:string | this | Assert value not null |
| `expectToBeEmpty(value,as?)` | value:any, as?:string | this | Assert value is empty |
| `expectToBeInTheFuture(date,as?)` | date:any, as?:string | this | Assert date is future |
| `expectToBeInThePast(date,as?)` | date:any, as?:string | this | Assert date is past |
| `expectToStartWith(text,prefix,as?)` | text:string, prefix:string, as?:string | this | Assert string starts with |
| `expectToEndWith(text,suffix,as?)` | text:string, suffix:string, as?:string | this | Assert string ends with |
| `expectToMatch(text,pattern,as?)` | text:string, pattern:string, as?:string | this | Assert string matches regex |
| `expectToContain(text,search,as?)` | text:string, search:string, as?:string | this | Assert string contains |
| `expectToBeGreaterThan(value,than,as?)` | value:number, than:number, as?:string | this | Assert value > |
| `expectToBeLessThan(value,than,as?)` | value:number, than:number, as?:string | this | Assert value < |
| `expectToBeWithin(value,min,max,as?)` | value:number, min:number, max:number, as?:string | this | Assert value in range |
| `expectToEqual(value1,value2,as?)` | value1:any, value2:any, as?:string | this | Assert equality |
| `expectToNotEqual(value1,value2,as?)` | value1:any, value2:any, as?:string | this | Assert inequality |
| `expectToThrow(code,as?)` | code:any, as?:string | this | Assert error thrown |

### Examples

```json
{
  "operations": [
    {"method": "expectToBeTrue", "args": ["$result.success", "is_success"]},
    {"method": "expectToEqual", "args": ["$output", "$expected", "equals"]},
    {"method": "expectToBeGreaterThan", "args": ["$count", 0, "has_items"]}
  ]
}
```

---

## Task Methods

**6 methods** for task management.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `taskSchedule(taskId)` | taskId:string | this | Schedule task |
| `taskFreq(taskId)` | taskId:string | this | Get task frequency |
| `taskOnEvent(taskId)` | taskId:string | this | Task on event |
| `taskEvents(taskId)` | taskId:string | this | Get task events |
| `taskRun(functionId)` | functionId:string | this | Run task/function |
| `taskCancel(taskId)` | taskId:string | this | Cancel task |

### Examples

```json
{
  "operations": [
    {"method": "taskSchedule", "args": ["cleanup_task"]},
    {"method": "taskRun", "args": ["process_data"]}
  ]
}
```

---

**Total Methods in this File: 49**

**Breakdown:**
- Debugging & Logging: 6 methods
- Date & Time: 4 methods (all verified working)
- Streaming: 4 methods (proposed)
- General Utilities: 15 methods (including utilTemplateEngine ✅ verified 2025-01-13)
- Testing Methods: 19 methods
- Task Methods: 6 methods

**Verification Status:**
- Last verified: 2025-01-13
- Date/time methods confirmed working: `utilTime()`, `utilDate()`, `utilTimestamp()` all auto-convert properly
- ✅ `utilTemplateEngine()` verified working 2025-01-13

For workflow guidance, see [workflow.md](workflow.md)
For complete examples, see [examples.md](examples.md)
