# SDK Control Flow Methods

Conditionals, loops, switch/case, error handling, and flow control for building complex logic.

## Table of Contents
- [Conditionals](#conditionals)
- [Loops](#loops)
- [Switch/Case](#switchcase)
- [Error Handling](#error-handling)
- [Grouping](#grouping)

---

## Conditionals

**5 methods** for if/else logic.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `conditional(condition)` | condition:string | this | Start if/else block |
| `then(callback?)` | callback?:(builder:FluentBuilder)=>void | this | Execute if condition true |
| `else(callback?)` | callback?:(builder:FluentBuilder)=>void | this | Execute if condition false |
| `endConditional()` | - | this | End if/else block |
| `endIf()` | - | this | Alias for `.endConditional()` |

**Note:** `elseIf()` is NOT SUPPORTED in XanoScript. Use nested `if/else` for multiple conditions (see examples below).

### Examples

**Simple conditional:**

```json
{
  "operations": [
    {"method": "conditional", "args": ["$user.role == \"admin\""]},
    {"method": "var", "args": ["access", "full"]},
    {"method": "else"},
    {"method": "var", "args": ["access", "limited"]},
    {"method": "endConditional"}
  ]
}
```

**Multiple conditions (use nested if/else):**

```json
{
  "operations": [
    {"method": "conditional", "args": ["$user.age < 18"]},
    {"method": "var", "args": ["category", "minor"]},
    {"method": "else"},
    {"method": "conditional", "args": ["$user.age < 65"]},
    {"method": "var", "args": ["category", "adult"]},
    {"method": "else"},
    {"method": "var", "args": ["category", "senior"]},
    {"method": "endConditional"},
    {"method": "endConditional"}
  ]
}
```

**Nested conditionals:**

```json
{
  "operations": [
    {"method": "conditional", "args": ["$user.status == \"active\""]},
    {"method": "conditional", "args": ["$user.role == \"admin\""]},
    {"method": "var", "args": ["permissions", ["read", "write", "delete"]]},
    {"method": "else"},
    {"method": "var", "args": ["permissions", ["read"]]},
    {"method": "endConditional"},
    {"method": "endConditional"}
  ]
}
```

---

## Loops

**10 methods** for iteration and looping.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `for(iterations,indexVar,callback?)` | iterations:number, indexVar:string, callback?:(builder:IFluentBuilder)=>void | this | For loop (by count) |
| `forLoop(iterations,indexVar,code)` | iterations:number\|string, indexVar:string, code:string | this | For loop with code string |
| `endFor()` | - | this | End for loop |
| `while(condition,callback?)` | condition:string, callback?:(builder:IFluentBuilder)=>void | this | While loop |
| `whileLoop(condition,code)` | condition:string, code:string | this | While loop with code string |
| `endWhile()` | - | this | End while loop |
| `forEachCollect(array,itemVar,resultVar?)` | array:string, itemVar:string, resultVar?:string | this | ForEach with collection |
| `endForEach()` | - | this | End forEach loop |
| `break()` | - | this | Break from loop |
| `continue()` | - | this | Continue to next iteration |

### Examples

**For loop:**

```json
{
  "operations": [
    {"method": "var", "args": ["results", []]},
    {"method": "for", "args": [10, "i"]},
    {"method": "varPush", "args": ["results", "$i"]},
    {"method": "endFor"}
  ]
}
```

**ForEach with collection:**

```json
{
  "operations": [
    {"method": "forEach", "args": ["$users", "user"]},
    {"method": "conditional", "args": ["$user.status == \"active\""]},
    {"method": "arrayPush", "args": ["processed", "$user"]},
    {"method": "endConditional"},
    {"method": "endForEach"}
  ]
}
```

**While loop:**

```json
{
  "operations": [
    {"method": "var", "args": ["counter", 0]},
    {"method": "while", "args": ["$counter < 10"]},
    {"method": "mathAdd", "args": ["counter", 1]},
    {"method": "endWhile"}
  ]
}
```

**Break and continue:**

```json
{
  "operations": [
    {"method": "forEach", "args": ["$items", "item"]},
    {"method": "conditional", "args": ["$item.skip == true"]},
    {"method": "continue"},
    {"method": "endConditional"},
    {"method": "conditional", "args": ["$item.stop == true"]},
    {"method": "break"},
    {"method": "endConditional"},
    {"method": "endForEach"}
  ]
}
```

---

## Switch/Case

**4 methods** for switch/case statements.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `switch(variable,casesArray?)` | variable:string\|any[], casesArray?:any | this | Start switch block |
| `case(value)` | value:any | this | Start case block |
| `default()` | - | this | Start default case |
| `endSwitch()` | - | this | End switch block |

### Examples

**Basic switch:**

```json
{
  "operations": [
    {"method": "switch", "args": ["$user.role"]},
    {"method": "case", "args": ["admin"]},
    {"method": "var", "args": ["permissions", ["read", "write", "delete"]]},
    {"method": "case", "args": ["editor"]},
    {"method": "var", "args": ["permissions", ["read", "write"]]},
    {"method": "case", "args": ["viewer"]},
    {"method": "var", "args": ["permissions", ["read"]]},
    {"method": "default"},
    {"method": "var", "args": ["permissions", []]},
    {"method": "endSwitch"}
  ]
}
```

**Switch with actions:**

```json
{
  "operations": [
    {"method": "switch", "args": ["$input.action"]},
    {"method": "case", "args": ["create"]},
    {"method": "dbAdd", "args": ["item", "$input.data", "result"]},
    {"method": "case", "args": ["update"]},
    {"method": "dbEdit", "args": ["item", {"id": "$input.id"}, "$input.data", "result"]},
    {"method": "case", "args": ["delete"]},
    {"method": "dbDelete", "args": ["item", {"id": "$input.id"}]},
    {"method": "default"},
    {"method": "response", "args": [{"error": "Invalid action"}, 400]},
    {"method": "endSwitch"}
  ]
}
```

---

## Error Handling

**5 methods** for error handling. ✅ **ALL VERIFIED WORKING** - Tested 2025-01-13

| Method | Params | Returns | Purpose | Status |
|--------|--------|---------|---------|--------|
| `throw(name,value)` | name:string, value:string | this | Throw error | ✅ VERIFIED |
| `try()` | - | this | Start try block | ✅ VERIFIED |
| `catch()` | - | this | Start catch block | ✅ VERIFIED |
| `finally()` | - | this | Start finally block | ✅ VERIFIED |
| `endTryCatch()` | - | this | End try/catch block | ✅ VERIFIED |

**Status:** ALL error handling methods are VERIFIED and working as of 2025-01-13.

### Examples

**Throw error on validation failure:**

```json
{
  "operations": [
    {"method": "conditional", "args": ["!$input.email"]},
    {"method": "throw", "args": ["ValidationError", "Email is required"]},
    {"method": "endConditional"}
  ]
}
```

**Throw error with context:**

```json
{
  "operations": [
    {"method": "dbGet", "args": ["user", {"id": "$input.user_id"}, "user"]},
    {"method": "conditional", "args": ["!$user"]},
    {"method": "throw", "args": ["NotFoundError", "User not found"]},
    {"method": "endConditional"}
  ]
}
```

**✅ Try/catch with error recovery:**

```json
{
  "operations": [
    {"method": "try"},
    {"method": "functionRun", "args": ["risky_operation", {"input": "$input.data"}, "result"]},
    {"method": "response", "args": [{"success": true, "data": "$result"}]},
    {"method": "catch"},
    {"method": "debugLog", "args": ["$error"]},
    {"method": "response", "args": [{"success": false, "error": "$error.message"}, 500]},
    {"method": "finally"},
    {"method": "debugLog", "args": ["Operation completed"]},
    {"method": "endTryCatch"}
  ]
}
```

**Raw XanoScript equivalent:**
```xanoscript
try_catch {
  try {
    function.run risky_operation { input = { data: $input.data } } as $result
    return { value = { success: true, data: $result } }
  }
  catch {
    debug.log { value = $error }
    return { value = { success: false, error: $error.message } }
  }
  finally {
    debug.log { value = "Operation completed" }
  }
}
```

**✅ Try/catch with external API:**

```json
{
  "operations": [
    {"method": "try"},
    {"method": "apiRequest", "args": ["https://api.example.com/verify", "POST", {
      "headers": {"Content-Type": "application/json"},
      "params": {"email": "$input.email"}
    }, "api_result"]},
    {"method": "var", "args": ["status", "$api_result.response.status"]},
    {"method": "conditional", "args": ["$status >= 400"]},
    {"method": "throw", "args": ["API_ERROR", "$api_result.response.result.error"]},
    {"method": "endConditional"},
    {"method": "response", "args": [{"verified": true, "data": "$api_result.response.result"}]},
    {"method": "catch"},
    {"method": "debugLog", "args": [{"error_type": "$error.name", "message": "$error.value"}]},
    {"method": "response", "args": [{"verified": false, "error": "$error.value"}, 500]},
    {"method": "endTryCatch"}
  ]
}
```

**Alternative: Conditional error checking (simpler for basic cases):**

```json
{
  "operations": [
    {"method": "apiRequest", "args": ["https://api.example.com/verify", "POST", {
      "headers": {"Content-Type": "application/json"},
      "params": {"email": "$input.email"}
    }, "api_result"]},
    {"method": "var", "args": ["status", "$api_result.response.status"]},
    {"method": "var", "args": ["body", "$api_result.response.result"]},
    {"method": "conditional", "args": ["$body == false"]},
    {"method": "throw", "args": ["API_TIMEOUT", "API call timed out"]},
    {"method": "endConditional"},
    {"method": "conditional", "args": ["$status >= 400"]},
    {"method": "throw", "args": ["API_ERROR", "$body.error.message"]},
    {"method": "endConditional"},
    {"method": "response", "args": [{"verified": true, "data": "$body"}]}
  ]
}
```

---

## Grouping

**3 methods** for logical grouping and transactions.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `group(callback)` | callback:(builder:FluentBuilder)=>void | this | Logical grouping without flow |
| `transaction()` | - | this | Start database transaction |
| `endTransaction()` | - | this | End transaction |

### Examples

```javascript
// Logical grouping
endpoint
  .group((builder) => {
    builder
      .var('step1', 'complete')
      .var('step2', 'complete');
  })
  .response({ status: 'success' });

// Database transaction
endpoint
  .transaction()
  .dbAdd('order', {
    user_id: '$user.id',
    total: '$cart.total'
  }, 'order')
  .dbEdit('user',
    { id: '$user.id' },
    { balance: '$user.balance - $cart.total' },
    'updated_user'
  )
  .endTransaction()
  .response({ order: '$order' });
```

---

## Common Patterns

### Validation Flow

```javascript
endpoint
  .conditional('!$input.email')
  .then((builder) => {
    builder.response({ error: 'Email required' }, 400);
  })
  .endConditional()
  .conditional('!$input.password')
  .then((builder) => {
    builder.response({ error: 'Password required' }, 400);
  })
  .endConditional()
  // Continue with main logic
  .dbGet('user', { email: '$input.email' }, 'user');
```

### Processing Array

```javascript
endpoint
  .var('processed', [])
  .forEachCollect('$input.items', 'item')
  .conditional('$item.quantity > 0')
  .then((builder) => {
    builder
      .var('total', '$item.price * $item.quantity')
      .varObject('processed_item', {
        id: '$item.id',
        total: '$total'
      })
      .varPush('processed', '$processed_item');
  })
  .endConditional()
  .endForEach()
  .response({ items: '$processed' });
```

### Role-Based Access

```javascript
endpoint
  .switch('$auth.user.role')
  .case('admin')
  .dbQuery('user', {}, 'users')
  .case('manager')
  .dbQuery('user', { department: '$auth.user.department' }, 'users')
  .case('user')
  .dbGet('user', { id: '$auth.user.id' }, 'users')
  .default()
  .response({ error: 'Unauthorized' }, 403)
  .endSwitch()
  .response({ users: '$users' });
```

---

**Total Methods in this File: 21**

**Verification Status:**
- Last verified: 2025-01-13
- Methods removed: `elseIf()`, `try()`, `catch()` (not supported in XanoScript)
- Use nested if/else for multiple conditions
- Use conditional error checking instead of try/catch

For workflow guidance, see [workflow.md](workflow.md)
For more examples, see [examples.md](examples.md)
