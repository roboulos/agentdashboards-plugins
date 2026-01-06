# SDK Core Methods

Essential SDK methods for endpoint/function creation, variable management, and response handling.

**⚠️ MANDATORY: Read workflow.md for complete building process**

**Core principle: BUILD → EXPOSE → TEST → LEARN → REPEAT**

## Table of Contents
- [Configuration & Metadata](#configuration--metadata)
- [Variables & Assignment](#variables--assignment)
- [Response & Output](#response--output)

---

## Configuration & Metadata

**11 core methods** for setting up endpoints, functions, and tasks.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `description(desc)` | desc:string | this | Set endpoint/function description |
| `setWorkspaceId(id)` | workspaceId:string\|number | this | Set workspace ID for validation |
| `requiresAuth(table?)` | table?:string | this | Mark endpoint as auth-required |
| `input(name,type,options?)` | name:string, type:string, options?:Partial<InputDef> | this | Define endpoint input parameter |
| `schedule(events)` | events:ScheduleEvent[]\|string | this | Schedule task execution |
| `active(isActive)` | isActive:boolean | this | Activate/deactivate function/task |
| `tags(tagList)` | tagList:string[] | this | Add tags to endpoint |
| `uuid(alias)` | alias:string | this | Generate UUID, store in alias |
| `apiLambda(code,timeout?,alias?)` | code:string, timeout?:number, alias?:string | this | Execute custom API lambda code |
| `precondition(cond,msg,code?,desc?)` | condition:string, errorMessage:string, statusCode?:number, desc?:string | this | Fail fast if condition not met |
| `preconditionAdvanced(cond,type,msg,payload?)` | condition:string, errorType:string, errorMessage:string, payload?:Record | this | Advanced precondition with error types |

**CRITICAL:** `.auth()` DOES NOT EXIST → Use `.requiresAuth()`

---

## Variables & Assignment

**31 methods** for creating, updating, and manipulating variables.

### Create & Update Variables

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `var(name,val,val2?,desc?)` | name:string, valueOrType:any, value?:any, desc?:string | this | Create variable (smart type detection) |
| `variable(name,value)` | name:string, value:any | this | Alias for `.var()` |
| `createVariable(name,value)` | name:string, value:any | this | Explicit variable creation |
| `varObject(name,obj)` | name:string, obj:Record<string,any> | this | Create object variable |
| `varArray(name,items)` | name:string, items:any[] | this | Create array variable |
| `varUpdate(name,value)` | name:string, value:any | this | Update existing variable |
| `updateVariable(name,value)` | name:string, value:any | this | Alias for `.varUpdate()` |
| `varPush(arrayVar,value)` | arrayVar:string, value:any | this | Push to array variable |

### Math Operations

✅ **ALL VERIFIED REAL** - These are in-place mutation methods, NOT expression operators.

| Method | Status | Params | Returns | Purpose |
|--------|--------|--------|---------|---------|
| `mathAdd(variable,value)` | ✅ REAL | variable:string, value:any | this | Add to numeric variable (in-place) |
| `mathSubtract(variable,value)` | ✅ REAL | variable:string, value:any | this | Subtract from numeric variable (in-place) |
| `mathMultiply(variable,value)` | ✅ REAL | variable:string, value:any | this | Multiply numeric variable (in-place) |
| `mathDivide(variable,value)` | ✅ REAL | variable:string, value:any | this | Divide numeric variable (in-place) |
| `mathModulus(variable,value)` | ✅ REAL | variable:string, value:any | this | Modulus operation (in-place) |
| `mathBitwiseAnd(variable,value)` | ✅ REAL | variable:string, value:any | this | Bitwise AND operation |
| `mathBitwiseOr(variable,value)` | ✅ REAL | variable:string, value:any | this | Bitwise OR operation |
| `mathBitwiseXor(variable,value)` | ✅ REAL | variable:string, value:any | this | Bitwise XOR operation |
| `mathRound(value,decimals?,alias?)` | ✅ REAL | value:string\|number, decimals?:number, alias?:string | this | Round numeric value |

**⚠️ IMPORTANT: Math methods vs operators:**
- **Math methods** (`mathAdd`, `mathSubtract`, etc.) modify variables IN PLACE
- **Operators** (`+`, `-`, `*`, `/`) create new values in expressions
- Don't confuse them - they serve different purposes!

**Example:**
```json
{
  "operations": [
    {"method": "var", "args": ["counter", 10]},
    {"method": "mathAdd", "args": ["counter", 5]},
    // counter is now 15 (mutated in place)

    {"method": "var", "args": ["sum", "$a + $b"]},
    // sum gets the result of a + b (expression)
  ]
}
```

### Filter & Transform

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `applyFilter(varName,filterChain)` | varName:string, filterChain:string | this | Apply single/multiple filters |
| `chainFilters(varName,filters)` | varName:string, filters:string[] | this | Chain array of filters |
| `filter(value)` | value:any | this | Create filter pipeline |
| `concat(...parts)` | ...parts:any[] | this | Concatenate strings/values |

**String concatenation:** Use `|concat:` (recommended) or `~` (works)

---

## Response & Output

**5 methods** for returning data from endpoints and functions.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `response(data,statusCode?)` | data:ResponseData, statusCode?:number | this | Return response (NEW - recommended) |
| `buildResponse(data,statusCode?)` | data:{flat?:Record,nested?:Record}, statusCode?:number | this | Build complex response (legacy) |
| `returnValue(value)` | value:any | this | Return single value |
| `returnStatement(value,statusCode?)` | value:any, statusCode?:number | this | Return with status code |
| `return(value)` | value:any | this | Alias for `.returnValue()` |

**CRITICAL:** Use `.response()` (new) not `.buildResponse()` (legacy)

---

## Common Patterns

### Creating an Endpoint

```json
{
  "operations": [
    {"method": "description", "args": ["Get user profile"]},
    {"method": "requiresAuth", "args": ["user"]},
    {"method": "input", "args": ["user_id", "number"]},
    {"method": "var", "args": ["result", {}]},
    {"method": "response", "args": [{"user": "$result"}]}
  ]
}
```

### Variable Creation Examples

```json
{
  "operations": [
    {"method": "var", "args": ["user_name", "John Doe"]},
    {"method": "varObject", "args": ["user", {"name": "John", "email": "john@example.com"}]},
    {"method": "varArray", "args": ["items", [1, 2, 3]]},
    {"method": "var", "args": ["counter", 0]},
    {"method": "mathAdd", "args": ["counter", 1]}
  ]
}
```

### Response Patterns

```json
{
  "operations": [
    {"method": "response", "args": [{"message": "Success"}]},
    {"method": "response", "args": [{"error": "Not found"}, 404]},
    {"method": "response", "args": [{"data": "$user", "meta": {"count": "$total_count"}}]}
  ]
}
```

---

**Total Methods in this File: 47**

For complete SDK workflow, see [workflow.md](workflow.md)
