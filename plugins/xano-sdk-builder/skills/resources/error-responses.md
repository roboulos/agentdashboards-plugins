# Error Response Format Reference

**When you deploy an endpoint or function using the SDK tools, the middleware returns rich error messages to help you debug.**

This guide explains the error response structure and how to interpret each field.

---

## Error Response Structure

All error responses from the middleware have this format:

```json
{
  "success": false,
  "error_message": "A human-readable error description",
  "error_type": "refinement_needed",
  "code": "TABLE_VALIDATION_FAILED",
  "hint": "Did you mean...?",
  "available_options": [],
  "xano_response": {}
}
```

**Notes:**
- `error_type`: "refinement_needed", "server_error", "validation_error", etc.
- `hint`: Optional troubleshooting suggestion
- `available_options`: Optional list of valid options for mismatched names
- `xano_response`: Optional raw Xano API response for debugging

---

## Understanding Each Field

### `success` (boolean)
- Always `false` for error responses
- Always `true` for successful deployments
- Check this first to determine if deployment succeeded

### `error_message` (string)
- Plain English description of what went wrong
- Usually explains the problem and what to fix
- Example: "Table 'users' not found in your workspace"

### `error_type` (string)
The category of error. Common values:

| error_type | Meaning | What to Do |
|-----------|---------|-----------|
| `refinement_needed` | Your SDK code has a logic error | Review your XanoScript syntax |
| `validation_error` | Your parameters don't match schema | Check parameter names and types |
| `resource_not_found` | Table/function/field doesn't exist | Check workspace; see `available_options` |
| `server_error` | Xano API or infrastructure error | Try again; check Xano status if persistent |
| `timeout_error` | Operation took too long | Simplify endpoint or increase timeout |
| `authentication_error` | API key or credentials invalid | Verify environment variables |
| `syntax_error` | XanoScript syntax is invalid | Check semicolons, parentheses, filter names |

### `code` (string)
Machine-readable error code for automation. Examples:

```
TABLE_VALIDATION_FAILED
FUNCTION_NOT_FOUND
SDK_EXECUTION_FAILED
XANO_API_ERROR
INVALID_PARAMETER_TYPE
TIMEOUT_EXCEEDED
```

### `hint` (string, optional)
Helpful troubleshooting suggestion. Examples:

```
"Did you mean table 'users_v2' instead of 'users'?"
"Function 'calculate_discount' requires 2 parameters but got 1"
"This usually happens when endpoint timeout is too short. Try 30+ seconds for complex endpoints."
```

### `available_options` (array, optional)
Only present in `resource_not_found` errors. Lists valid options you could use instead.

Example when you use wrong table name:
```json
{
  "error_message": "Table 'user' not found",
  "available_options": ["users", "user_profiles", "user_data"]
}
```

### `xano_response` (object, optional)
Raw response from Xano API (only when error originates from Xano). Use this for debugging infrastructure issues.

---

## Error Examples With Solutions

### Example 1: Table Not Found

**Error Response:**
```json
{
  "success": false,
  "error_message": "Table 'user' not found in workspace 5",
  "error_type": "resource_not_found",
  "code": "TABLE_VALIDATION_FAILED",
  "hint": "Did you mean 'users'?",
  "available_options": ["users", "user_profiles"]
}
```

**What went wrong:** You referenced a table that doesn't exist.

**How to fix:**
1. Check the `available_options` array for correct table names
2. Update your SDK code to use the correct table name: `endpoint.dbQuery('users', ...)`
3. Redeploy

---

### Example 2: Wrong Parameter Type

**Error Response:**
```json
{
  "success": false,
  "error_message": "Field 'user_id' expects type 'int' but received 'text'",
  "error_type": "validation_error",
  "code": "INVALID_PARAMETER_TYPE",
  "hint": "Convert '$input.user_id' to integer using '|to_int' filter"
}
```

**What went wrong:** You passed a string where a number was expected.

**How to fix:**
1. In your SDK code, convert the type: `'$input.user_id|to_int'`
2. Or accept the correct type: `func.input('user_id', 'int', { required: true })`
3. Redeploy

---

### Example 3: SDK Syntax Error

**Error Response:**
```json
{
  "success": false,
  "error_message": "Invalid XanoScript: missing closing parenthesis at line 24",
  "error_type": "refinement_needed",
  "code": "SDK_EXECUTION_FAILED",
  "hint": "Check line 24 for unclosed parenthesis or bracket"
}
```

**What went wrong:** Your XanoScript has a syntax error.

**How to fix:**
1. Go to line 24 of your SDK code
2. Check for missing `)`, `]`, `}`, or `'`
3. Fix the syntax
4. Redeploy

---

### Example 4: Timeout Error

**Error Response:**
```json
{
  "success": false,
  "error_message": "Operation timed out after 10000 milliseconds",
  "error_type": "timeout_error",
  "code": "TIMEOUT_EXCEEDED",
  "hint": "Complex endpoints need 30+ seconds. Check your endpoint timeout setting in Xano UI."
}
```

**What went wrong:** Your endpoint is too slow for the default 10-second timeout.

**How to fix:**
1. In Xano UI, go to endpoint settings
2. Click "Advanced" tab
3. Increase "Request Timeout" to 30+ seconds
4. If multiple API calls: add 10 seconds per call + 5 second buffer

---

### Example 5: Function Not Found

**Error Response:**
```json
{
  "success": false,
  "error_message": "Function 'normalize_vector_v2' not found in workspace 5",
  "error_type": "resource_not_found",
  "code": "FUNCTION_NOT_FOUND",
  "hint": "Available functions: normalize_vector, calculate_discount, sum_array",
  "available_options": ["normalize_vector", "calculate_discount", "sum_array"]
}
```

**What went wrong:** You're trying to call a function that doesn't exist.

**How to fix:**
1. Check the `available_options` for the correct function name
2. Update your SDK code: `endpoint.callFunction('normalize_vector', ...)`
3. Or create the function if it's a new one you need
4. Redeploy

---

### Example 6: Invalid Filter Name

**Error Response:**
```json
{
  "success": false,
  "error_message": "Invalid filter name: search (did you mean 'contains'?)",
  "error_type": "refinement_needed",
  "code": "SDK_EXECUTION_FAILED",
  "hint": "The '|search:' filter doesn't exist. Use '|contains:' instead to check if string contains a value."
}
```

**What went wrong:** You used a filter that doesn't exist in XanoScript.

**How to fix:**
1. Replace `|search:` with `|contains:`
2. Update your SDK code: `endpoint.var('found', '$str|contains:"needle"')`
3. Redeploy

---

### Example 7: Missing Required Parameter

**Error Response:**
```json
{
  "success": false,
  "error_message": "Missing required parameter: api_group_id",
  "error_type": "validation_error",
  "code": "INVALID_PARAMETER_TYPE",
  "hint": "api_group_id is required for this operation. Get it using 'browse_api_groups' tool."
}
```

**What went wrong:** You didn't provide a required parameter.

**How to fix:**
1. Add the missing parameter to your function call
2. If you need to find the value, use the tool mentioned in the hint
3. Retry with all required parameters

---

### Example 8: Xano API Error

**Error Response:**
```json
{
  "success": false,
  "error_message": "Xano API returned error: Invalid API key",
  "error_type": "server_error",
  "code": "XANO_API_ERROR",
  "xano_response": {
    "success": false,
    "message": "API authentication failed"
  }
}
```

**What went wrong:** The issue is with Xano's infrastructure or API.

**How to fix:**
1. Check your API key is set correctly in environment variables
2. Check Xano status page for any outages
3. Retry in a few minutes
4. If persistent, contact Xano support

---

### Example 9: SDK Auto-Correction Warning

**Error Response:**
```json
{
  "success": true,
  "warning_message": "Auto-corrected filter 'upper' → 'to_upper' on line 15. Consider updating your code.",
  "auto_corrections": [
    {"line": 15, "original": "|upper", "corrected": "|to_upper", "severity": "warning"}
  ]
}
```

**What went wrong:** Nothing! Your code works, but uses deprecated syntax.

**How to fix:**
1. Update your code to use the corrected filter names
2. This prevents future issues if auto-correction is removed
3. Redeploy with the updated syntax

---

### Example 10: Precondition Error

**Error Response:**
```json
{
  "success": false,
  "error_message": "Precondition failed: Email is required",
  "error_type": "validation_error",
  "code": "PRECONDITION_FAILED"
}
```

**What went wrong:** Your endpoint was called without required input.

**How to fix:**
1. The error message tells you what's missing: "Email is required"
2. When calling the endpoint, provide all required inputs
3. This is user error, not code error - fix your API caller, not your endpoint

---

## How to Debug Using Error Responses

**Step 1: Check `success` field**
- `false` → There's an error
- `true` → Deployment worked (might have warnings)

**Step 2: Read `error_message`**
- This usually explains the problem and solution

**Step 3: Check `error_type`**
- `refinement_needed` → Your code has a bug
- `resource_not_found` → Workspace is misconfigured
- `validation_error` → Your parameters are wrong
- `server_error` → Xano infrastructure issue

**Step 4: Use `hint` and `available_options`**
- `hint` gives you next steps
- `available_options` shows what you can use instead

**Step 5: If still stuck, check `xano_response`**
- Raw Xano API response for debugging deep issues
- Only present for infrastructure errors

---

## Common Error Patterns

### Pattern 1: "Not found" errors
- Usually resource misconfiguration
- Check `available_options` for correct names
- Verify table/function/field exists in workspace

### Pattern 2: "Timeout" errors
- Extend endpoint timeout to 30+ seconds
- Simplify endpoint (break into smaller calls)
- Add timeouts to slow API calls

### Pattern 3: "Syntax" errors
- Review error message line number
- Check for missing `)(]}` or `''`
- Verify filter names are correct

### Pattern 4: "Validation" errors
- Check parameter types match schema
- Ensure required parameters are provided
- Verify input values are correct type

### Pattern 5: "Server" errors
- Usually temporary Xano issues
- Try again in a few minutes
- Check Xano status page if persistent

---

## Related Documentation

- **[WHAT_BREAKS.md](WHAT_BREAKS.md)** - Known limitations and workarounds
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Copy-paste patterns that work
- **[SESSION_2025_11_07_IMPROVEMENTS.md](SESSION_2025_11_07_IMPROVEMENTS.md)** - Real deployment experiences
- **[STACK_INTEGRATION_ANALYSIS.md](STACK_INTEGRATION_ANALYSIS.md)** - Complete analysis of SDK/middleware/skill integration

---

**Last Updated:** November 7, 2025
**Version:** 1.0
