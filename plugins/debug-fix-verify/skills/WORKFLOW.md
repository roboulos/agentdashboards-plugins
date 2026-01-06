# Debug-Fix-Verify Complete Workflow

Complete step-by-step workflow with real examples from production bug fixes.

---

## Table of Contents

1. [Overview](#overview)
2. [Step 1: Add Debug Logs](#step-1-add-debug-logs)
3. [Step 2: Build & Deploy](#step-2-build--deploy)
4. [Step 3: Test with Real Data](#step-3-test-with-real-data)
5. [Step 4: Check Logs](#step-4-check-logs)
6. [Step 5: Implement Fix](#step-5-implement-fix)
7. [Step 6: Verify Fix](#step-6-verify-fix)
8. [Step 7: Clean & Commit](#step-7-clean--commit)
9. [Real Example: Filter Validation Bug](#real-example-filter-validation-bug)

---

## Overview

The debug-fix-verify cycle is a systematic approach that ensures:
- You understand what code is actually doing
- Fixes are based on evidence, not guesses
- Solutions are verified before deployment
- Knowledge is documented for future reference

**Key Principle:** Add logs first, understand behavior, then fix.

---

## Step 1: Add Debug Logs

### Goal
Understand exactly what the code is doing at runtime by logging key decision points, data transformations, and execution paths.

### Where to Add Logs

1. **Function Entry**
   ```typescript
   export async function handler(params: any, context: any) {
     console.log('[HandlerName] Called with params:', JSON.stringify(params, null, 2));
     console.log('[HandlerName] Context authenticated:', context.authenticated);
   ```

2. **Before Conditions**
   ```typescript
   console.log('[HandlerName] Checking if filters provided:', {
     hasFilters: !!params.filters,
     filtersType: typeof params.filters,
     filtersValue: params.filters
   });
   ```

3. **Inside Conditions** (Both branches!)
   ```typescript
   if (params.filters) {
     console.log('[HandlerName] FILTERS PROVIDED - Processing filters');
     // filter logic
   } else {
     console.log('[HandlerName] NO FILTERS - Skipping filter processing');
   }
   ```

4. **Data Transformations**
   ```typescript
   console.log('[HandlerName] Raw input:', rawData);
   const transformed = transformData(rawData);
   console.log('[HandlerName] Transformed output:', transformed);
   ```

5. **Before External Calls**
   ```typescript
   console.log('[HandlerName] About to call Xano API with:', {
     endpoint: url,
     method: 'POST',
     body: requestBody
   });
   ```

6. **After External Calls**
   ```typescript
   const response = await fetch(url, options);
   console.log('[HandlerName] Xano API response:', {
     status: response.status,
     data: await response.json()
   });
   ```

7. **Error Conditions**
   ```typescript
   if (error) {
     console.log('[HandlerName] ERROR occurred:', {
       message: error.message,
       stack: error.stack,
       context: { params, state }
     });
   }
   ```

8. **Function Exit**
   ```typescript
   console.log('[HandlerName] Returning result:', result);
   return result;
   ```

### Logging Best Practices

- **Use structured logging:** Log objects with context
- **Prefix with function name:** `[FunctionName]` for filtering
- **Log both paths:** If/else branches both need logs
- **Don't assume:** Log values before using them
- **JSON.stringify for objects:** Makes complex data readable
- **Number your logs:** For complex flows: `[Step 1]`, `[Step 2]`, etc.

### How Many Logs?

**Minimum:** 10+ logs for any bug investigation
**Typical:** 15-20 logs for medium complexity
**Complex:** 30+ logs for intricate logic

**Rule of Thumb:** When in doubt, add more logs. You can always remove them later.

---

## Step 2: Build & Deploy

### Commands

```bash
npm run build && npm run deploy
```

### What Happens

1. **Build Process**
   - TypeScript compilation
   - Tool discovery and registration
   - Bundling documentation
   - Typically 5-10 seconds

2. **Deploy Process**
   - Upload to Cloudflare Workers
   - Activate new version
   - Propagate to edge locations
   - Typically 10-20 seconds

### Wait for Success

Don't proceed until you see:
```
✓ Built successfully
✓ Deployed to production
```

### Troubleshooting Build Failures

If build fails:
1. Check TypeScript errors: `npm run typecheck`
2. Check for syntax errors in debug logs
3. Ensure all imports are correct
4. Verify no circular dependencies

---

## Step 3: Test with Real Data

### Use MCP Execute Tool

```typescript
mcp__xano-mcp__execute({
  tool_id: "the_tool_name",
  arguments: {
    // Actual parameters that reproduce the bug
    workspace: 5,
    instance: 10,
    table_name: "users",
    filters: {
      field: "email",
      operator: "=",
      value: "test@example.com"
    }
  }
})
```

### Key Principles

1. **Use Real Parameters** - Not mock data, actual values
2. **Reproduce the Bug** - Test case should show the problem
3. **Simple Test Case** - Minimum params to reproduce issue
4. **Document Test Case** - Save for verification later

### Creating Good Test Cases

**Bad Test Case:**
```typescript
// Too many parameters, hard to isolate issue
{ workspace: 5, instance: 10, table: "x", filters: {...}, sort: {...}, limit: 10 }
```

**Good Test Case:**
```typescript
// Minimal parameters that reproduce bug
{ workspace: 5, instance: 10, table: "users", filters: { field: "email" } }
```

### Alternative Testing Methods

- **API Calls:** Direct curl/fetch to endpoints
- **Integration Tests:** Automated test suites
- **Manual Testing:** UI interactions if frontend

But for MCP tools, `mcp__xano-mcp__execute` is most direct.

---

## Step 4: Check Logs

### Command

```bash
wrangler tail
```

### What You'll See

```
[HandlerName] Called with params: { workspace: 5, instance: 10, ... }
[HandlerName] Context authenticated: true
[HandlerName] Checking if filters provided: { hasFilters: true, ... }
[HandlerName] FILTERS PROVIDED - Processing filters
[HandlerName] Validating filter: { field: "email", operator: "=" }
[HandlerName] Validation FAILED - Invalid operator
[HandlerName] Returning error: Invalid filter operator
```

### How to Analyze Logs

1. **Follow Execution Path**
   - Which branches were taken?
   - Which conditions were true/false?
   - What values did variables have?

2. **Find the Problem**
   - Where does behavior diverge from expected?
   - What value is incorrect?
   - Which condition failed unexpectedly?

3. **Identify Root Cause**
   - Not just where error occurs
   - Why it occurs
   - What assumption was wrong

### Log Analysis Example

**Symptom:** Filter validation fails unexpectedly

**Logs show:**
```
[ValidateFilter] Received operator: "="
[ValidateFilter] Valid operators: ["eq", "ne", "gt", "lt"]
[ValidateFilter] Operator "=" NOT in valid list - FAIL
```

**Root Cause:** User provides "=" but code expects "eq"
**Solution:** Either accept "=" as alias or document expected format

### Filtering Logs

```bash
# Filter by function name
wrangler tail | grep "\[FunctionName\]"

# Filter by level
wrangler tail | grep "ERROR"

# Save logs to file
wrangler tail > debug-session.log
```

---

## Step 5: Implement Fix

### Based on Log Findings

Don't guess - implement the fix that logs revealed is needed.

### Keep Debug Logs Initially

```typescript
// Keep these during fix implementation
console.log('[Handler] Processing with fix applied');
console.log('[Handler] New logic result:', result);

// Your fix here
if (operator === "=" || operator === "eq") {
  // Handle both formats
}
```

### Focus on Root Cause

**Don't just fix symptoms:**
```typescript
// Bad: Catches error but doesn't fix cause
try {
  validateOperator(op);
} catch (e) {
  // Ignore error
}
```

**Fix root cause:**
```typescript
// Good: Accept both formats
const normalizedOperator = operator === "=" ? "eq" : operator;
validateOperator(normalizedOperator);
```

### Make Minimal Changes

Change only what's necessary:
- Don't refactor during bug fix
- Don't add new features
- Don't change unrelated code
- Focus on the specific issue

### Document Your Fix

Add comments explaining why:
```typescript
// Bug fix: Accept both "=" and "eq" as equality operator
// Users may provide SQL-style operators, normalize to Xano format
const normalizedOperator = operator === "=" ? "eq" : operator;
```

---

## Step 6: Verify Fix

### Build & Deploy Again

```bash
npm run build && npm run deploy
```

### Test with SAME Test Case

```typescript
// Use identical test case from Step 3
mcp__xano-mcp__execute({
  tool_id: "the_tool_name",
  arguments: {
    // Same parameters as before
  }
})
```

### Check Logs Again

```bash
wrangler tail
```

**What to verify:**
- Bug no longer occurs
- Expected behavior happens
- No new errors introduced
- Performance is acceptable

### Regression Testing

Test related functionality:
- Does fix break anything else?
- Do similar use cases still work?
- Are edge cases handled?

### Example Verification

**Before Fix:**
```
[ValidateFilter] Operator "=" NOT in valid list - FAIL
Result: Error thrown
```

**After Fix:**
```
[ValidateFilter] Received operator: "="
[ValidateFilter] Normalized to: "eq"
[ValidateFilter] Operator "eq" in valid list - PASS
Result: Success
```

---

## Step 7: Clean & Commit

### Remove Debug Logs

```typescript
// Remove all console.log statements added for debugging
// BEFORE:
console.log('[Handler] Called with params:', params);
console.log('[Handler] Checking condition:', value);
if (condition) {
  console.log('[Handler] Taking TRUE path');
  // logic
}

// AFTER:
if (condition) {
  // logic
}
```

### Keep Critical Logs

Permanent logs for production monitoring:
```typescript
// Keep error logs
console.error('[Handler] Critical error:', error);

// Keep important state changes
console.info('[Handler] Database record created:', recordId);
```

### Final Build & Deploy

```bash
npm run build && npm run deploy
```

### Final Verification

Run test one more time to ensure:
- Clean code still works
- No debug logs in production
- Performance is good

### Commit with Detailed Message

```bash
git add .
git commit -m "fix(tool-name): accept both '=' and 'eq' operators

Bug: Filter validation was rejecting '=' operator
Found: Debug logs showed code only accepted 'eq', 'ne', 'gt', 'lt'
Fix: Normalize '=' to 'eq' before validation
Test: Verified both operators now work correctly

Before: ValidationError: Invalid operator '='
After: Successfully processes both '=' and 'eq'
"
```

### Commit Message Template

```
fix(component): brief description

Bug: What was broken
Found: What debug logs revealed
Fix: How it was fixed
Test: Verification results

Before: [error or incorrect behavior]
After: [correct behavior]
```

---

## Real Example: Filter Validation Bug

### Initial Report

User reported: "Filter validation failing with '=' operator"

### Step 1: Add Debug Logs (15 logs)

```typescript
export async function validateFilter(filter: any) {
  console.log('[ValidateFilter] Input:', JSON.stringify(filter, null, 2));

  const { field, operator, value } = filter;
  console.log('[ValidateFilter] Extracted:', { field, operator, value });

  console.log('[ValidateFilter] Checking operator validity');
  const validOps = ['eq', 'ne', 'gt', 'lt', 'gte', 'lte'];
  console.log('[ValidateFilter] Valid operators:', validOps);
  console.log('[ValidateFilter] Received operator:', operator);
  console.log('[ValidateFilter] Operator in list?', validOps.includes(operator));

  if (!validOps.includes(operator)) {
    console.log('[ValidateFilter] INVALID OPERATOR - Throwing error');
    throw new Error(`Invalid operator: ${operator}`);
  }

  console.log('[ValidateFilter] Operator valid - Continuing');
  console.log('[ValidateFilter] Checking field...');

  if (!field) {
    console.log('[ValidateFilter] NO FIELD - Throwing error');
    throw new Error('Field required');
  }

  console.log('[ValidateFilter] All validation passed');
  return true;
}
```

### Step 2: Build & Deploy

```bash
npm run build && npm run deploy
# ✓ Built successfully in 6.2s
# ✓ Deployed to production in 12.4s
```

### Step 3: Test

```typescript
mcp__xano-mcp__execute({
  tool_id: "db_query",
  arguments: {
    workspace: 5,
    instance: 10,
    table_name: "users",
    filters: [{
      field: "email",
      operator: "=",
      value: "test@example.com"
    }]
  }
})
```

### Step 4: Check Logs

```
[ValidateFilter] Input: { "field": "email", "operator": "=", "value": "test@example.com" }
[ValidateFilter] Extracted: { field: "email", operator: "=", value: "test@example.com" }
[ValidateFilter] Checking operator validity
[ValidateFilter] Valid operators: ["eq", "ne", "gt", "lt", "gte", "lte"]
[ValidateFilter] Received operator: "="
[ValidateFilter] Operator in list? false
[ValidateFilter] INVALID OPERATOR - Throwing error
```

**Finding:** Code expects "eq" but user provides "="

### Step 5: Implement Fix

```typescript
export async function validateFilter(filter: any) {
  console.log('[ValidateFilter] Input:', JSON.stringify(filter, null, 2));

  const { field, value } = filter;
  let { operator } = filter;

  // Bug fix: Normalize SQL-style operators to Xano format
  const operatorMap: Record<string, string> = {
    '=': 'eq',
    '!=': 'ne',
    '>': 'gt',
    '<': 'lt',
    '>=': 'gte',
    '<=': 'lte'
  };

  console.log('[ValidateFilter] Original operator:', operator);
  if (operatorMap[operator]) {
    operator = operatorMap[operator];
    console.log('[ValidateFilter] Normalized to:', operator);
  }

  const validOps = ['eq', 'ne', 'gt', 'lt', 'gte', 'lte'];
  console.log('[ValidateFilter] Checking against valid ops:', validOps);
  console.log('[ValidateFilter] Operator in list?', validOps.includes(operator));

  if (!validOps.includes(operator)) {
    console.log('[ValidateFilter] INVALID OPERATOR - Throwing error');
    throw new Error(`Invalid operator: ${operator}`);
  }

  console.log('[ValidateFilter] Operator valid - Continuing');
  // ... rest of validation
}
```

### Step 6: Verify Fix

```bash
npm run build && npm run deploy
# Test again with same test case
```

**Logs:**
```
[ValidateFilter] Input: { "field": "email", "operator": "=", ... }
[ValidateFilter] Original operator: "="
[ValidateFilter] Normalized to: "eq"
[ValidateFilter] Checking against valid ops: ["eq", "ne", "gt", "lt", "gte", "lte"]
[ValidateFilter] Operator in list? true
[ValidateFilter] Operator valid - Continuing
```

**Result:** Success! Filter validation passes.

### Step 7: Clean & Commit

Remove debug logs:
```typescript
export async function validateFilter(filter: any) {
  const { field, value } = filter;
  let { operator } = filter;

  // Normalize SQL-style operators to Xano format
  const operatorMap: Record<string, string> = {
    '=': 'eq',
    '!=': 'ne',
    '>': 'gt',
    '<': 'lt',
    '>=': 'gte',
    '<=': 'lte'
  };

  if (operatorMap[operator]) {
    operator = operatorMap[operator];
  }

  const validOps = ['eq', 'ne', 'gt', 'lt', 'gte', 'lte'];

  if (!validOps.includes(operator)) {
    throw new Error(`Invalid operator: ${operator}`);
  }

  // ... rest of validation
}
```

Deploy and commit:
```bash
npm run build && npm run deploy

git add src/tools/xano/db-query/
git commit -m "fix(db-query): accept SQL-style operators in filters

Bug: Filter validation rejected '=', '!=', '>', '<', '>=', '<=' operators
Found: Debug logs showed code only accepted Xano-style 'eq', 'ne', 'gt', etc.
Fix: Added operator normalization map to convert SQL-style to Xano-style
Test: Verified both SQL-style and Xano-style operators now work

Before: ValidationError: Invalid operator '='
After: Automatically normalizes '=' to 'eq' and processes successfully
"
```

---

## Time Investment

**Total Time for Example Bug:** 23 minutes
- Step 1 (Add logs): 5 min
- Step 2 (Build/Deploy): 1 min
- Step 3 (Test): 2 min
- Step 4 (Analyze logs): 4 min
- Step 5 (Implement fix): 3 min
- Step 6 (Verify): 3 min
- Step 7 (Clean/Commit): 5 min

**ROI:** 23 minutes vs hours of guessing and trial-and-error

---

## Key Takeaways

1. Debug logs show exactly what's happening
2. Testing with real data reproduces actual issues
3. Fixes based on evidence are correct first time
4. Verification ensures fix works
5. Clean code and detailed commits preserve knowledge

**The cycle works because you KNOW what's happening, not guessing.**
