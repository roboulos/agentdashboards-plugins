# Testing Strategies for Debug-Fix-Verify

Comprehensive guide to testing during bug fixes and verifications.

---

## Table of Contents

1. [Testing Principles](#testing-principles)
2. [Creating Test Cases](#creating-test-cases)
3. [Using MCP Execute](#using-mcp-execute)
4. [API Testing Patterns](#api-testing-patterns)
5. [Regression Testing](#regression-testing)
6. [Edge Case Testing](#edge-case-testing)
7. [Performance Testing](#performance-testing)

---

## Testing Principles

### Test with Real Data

**Never use mock data during bug fixes.**

**Bad:**
```typescript
// Mock data that might not reproduce bug
const testData = { id: 1, name: 'test' };
```

**Good:**
```typescript
// Actual data from production that reproduces bug
const testData = {
  workspace: 5,
  instance: 10,
  table_name: 'real_users_table',
  filters: {
    field: 'email',
    operator: '=',
    value: 'actual@user.com'
  }
};
```

### Reproducible Test Cases

Every test should:
- Consistently reproduce the bug
- Use the same parameters every time
- Be documented for future reference
- Be simple and minimal

### Test One Thing

Don't test multiple issues simultaneously:

**Bad:**
```typescript
// Testing filters, sorting, pagination all at once
{ filters: {...}, sort: {...}, page: 2, limit: 10 }
```

**Good:**
```typescript
// Testing just filters
{ filters: { field: 'email', operator: '=' } }

// Separate test for sorting
{ sort: { field: 'created_at', direction: 'desc' } }
```

---

## Creating Test Cases

### Minimal Reproduction

Start with the absolute minimum parameters needed to reproduce the bug.

**Process:**
1. Start with all parameters that might be involved
2. Remove one parameter at a time
3. Test after each removal
4. Stop when bug no longer reproduces
5. Last working set is your minimal test case

**Example:**
```typescript
// Original bug report
{
  workspace: 5,
  instance: 10,
  table_name: 'users',
  filters: { field: 'email', operator: '=', value: 'test@example.com' },
  sort: { field: 'created_at', direction: 'desc' },
  limit: 10,
  offset: 0
}

// Test 1: Remove offset - bug still happens
// Test 2: Remove limit - bug still happens
// Test 3: Remove sort - bug still happens

// Minimal test case
{
  workspace: 5,
  instance: 10,
  table_name: 'users',
  filters: { field: 'email', operator: '=', value: 'test@example.com' }
}
```

### Test Case Documentation

Document each test case:

```typescript
/**
 * Test Case: Filter with SQL operator
 *
 * Bug: Validation rejects '=' operator
 * Expected: Should accept '=' and normalize to 'eq'
 *
 * Test Data:
 */
const testCase = {
  name: "SQL operator test",
  input: {
    workspace: 5,
    instance: 10,
    table_name: 'users',
    filters: [{
      field: 'email',
      operator: '=',  // SQL-style operator
      value: 'test@example.com'
    }]
  },
  expectedResult: "Success",
  actualResult: "ValidationError: Invalid operator '='"
};
```

### Test Case Templates

**Happy Path Test:**
```typescript
const happyPathTest = {
  description: "Valid input should succeed",
  input: { /* valid params */ },
  expected: { success: true, data: expect.any(Array) }
};
```

**Error Case Test:**
```typescript
const errorCaseTest = {
  description: "Invalid input should fail gracefully",
  input: { /* invalid params */ },
  expected: { error: true, message: expect.stringContaining('Invalid') }
};
```

**Edge Case Test:**
```typescript
const edgeCaseTest = {
  description: "Boundary condition",
  input: { /* edge case params */ },
  expected: { /* expected behavior */ }
};
```

---

## Using MCP Execute

### Basic Execution

```typescript
mcp__xano-mcp__execute({
  tool_id: "tool_name",
  arguments: {
    // Test parameters
  }
})
```

### Structured Testing

```typescript
// Define test case
const testCase = {
  workspace: 5,
  instance: 10,
  table_name: 'users',
  filters: [{ field: 'email', operator: '=', value: 'test@example.com' }]
};

console.log('Testing with:', testCase);

// Execute test
const result = await mcp__xano-mcp__execute({
  tool_id: "db_query",
  arguments: testCase
});

console.log('Result:', result);
```

### Multiple Test Cases

```typescript
const testCases = [
  {
    name: 'SQL operator =',
    input: { filters: [{ field: 'email', operator: '=' }] }
  },
  {
    name: 'SQL operator !=',
    input: { filters: [{ field: 'status', operator: '!=' }] }
  },
  {
    name: 'Xano operator eq',
    input: { filters: [{ field: 'email', operator: 'eq' }] }
  }
];

for (const test of testCases) {
  console.log(`\n=== Test: ${test.name} ===`);

  const result = await mcp__xano-mcp__execute({
    tool_id: "db_query",
    arguments: {
      workspace: 5,
      instance: 10,
      table_name: 'users',
      ...test.input
    }
  });

  console.log('Result:', result);
}
```

### Capturing Test Results

```typescript
const results: any[] = [];

for (const test of testCases) {
  const result = await mcp__xano-mcp__execute({
    tool_id: "tool_name",
    arguments: test.input
  });

  results.push({
    test: test.name,
    success: !result.error,
    result: result
  });
}

console.log('\n=== Test Summary ===');
console.log('Total tests:', results.length);
console.log('Passed:', results.filter(r => r.success).length);
console.log('Failed:', results.filter(r => !r.success).length);
console.log('\nDetails:', results);
```

---

## API Testing Patterns

### Direct Curl Testing

```bash
# Test API endpoint directly
curl -X POST https://mcp-v3.snappysaas.com/sse/message \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "method": "tools/call",
    "params": {
      "name": "xano_db_query",
      "arguments": {
        "workspace": 5,
        "instance": 10,
        "table_name": "users",
        "filters": [{
          "field": "email",
          "operator": "=",
          "value": "test@example.com"
        }]
      }
    }
  }'
```

### Testing with HTTPie

```bash
# Cleaner syntax with httpie
http POST https://mcp-v3.snappysaas.com/sse/message \
  Authorization:"Bearer ${TOKEN}" \
  method=tools/call \
  params:='{
    "name": "xano_db_query",
    "arguments": {
      "workspace": 5,
      "instance": 10,
      "table_name": "users"
    }
  }'
```

### Automated API Tests

```typescript
async function testEndpoint(testCase: any) {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      method: 'tools/call',
      params: {
        name: 'xano_db_query',
        arguments: testCase
      }
    })
  });

  const result = await response.json();

  return {
    status: response.status,
    ok: response.ok,
    data: result
  };
}

// Run tests
const result1 = await testEndpoint(testCase1);
const result2 = await testEndpoint(testCase2);
```

---

## Regression Testing

### What is Regression Testing?

Testing that your fix doesn't break existing functionality.

### Identifying Regression Risks

After fixing a bug, test:
1. **Related features** - Similar functionality that uses same code
2. **Dependent features** - Features that depend on fixed code
3. **Common use cases** - Typical user workflows
4. **Edge cases** - Boundary conditions

### Example Regression Tests

**Bug Fix:** Accept both '=' and 'eq' operators

**Regression Tests:**
```typescript
const regressionTests = [
  {
    name: 'Existing eq operator still works',
    input: { operator: 'eq' },
    expected: { success: true }
  },
  {
    name: 'Other operators not affected',
    input: { operator: 'ne' },
    expected: { success: true }
  },
  {
    name: 'Filters without operators still work',
    input: { field: 'email' },
    expected: { success: true }
  },
  {
    name: 'Multiple filters still work',
    input: {
      filters: [
        { field: 'email', operator: '=' },
        { field: 'status', operator: 'eq' }
      ]
    },
    expected: { success: true }
  }
];
```

### Before/After Testing

```typescript
// Before fix: Document current behavior
const beforeResults = {
  'SQL operator =': 'ERROR: Invalid operator',
  'Xano operator eq': 'SUCCESS',
  'Other operators': 'SUCCESS'
};

// After fix: Verify new behavior
const afterResults = {
  'SQL operator =': 'SUCCESS',  // Fixed
  'Xano operator eq': 'SUCCESS', // Still works
  'Other operators': 'SUCCESS'   // Not broken
};

// Compare
const regressions = [];
for (const test in beforeResults) {
  if (beforeResults[test] === 'SUCCESS' && afterResults[test] !== 'SUCCESS') {
    regressions.push(test);
  }
}

if (regressions.length > 0) {
  console.error('REGRESSIONS DETECTED:', regressions);
}
```

---

## Edge Case Testing

### Common Edge Cases

1. **Empty values**
   ```typescript
   { field: '', operator: 'eq', value: '' }
   ```

2. **Null values**
   ```typescript
   { field: null, operator: null, value: null }
   ```

3. **Undefined values**
   ```typescript
   { field: undefined }
   ```

4. **Type mismatches**
   ```typescript
   { field: 123, operator: [], value: {} }
   ```

5. **Boundary values**
   ```typescript
   { limit: 0 }
   { limit: 999999 }
   { offset: -1 }
   ```

6. **Special characters**
   ```typescript
   { value: "test@#$%^&*()" }
   { field: "user.email" }
   ```

7. **Array edge cases**
   ```typescript
   { filters: [] }  // Empty array
   { filters: [{}] }  // Array with empty object
   ```

### Edge Case Test Suite

```typescript
const edgeCases = [
  { name: 'Empty string field', input: { field: '' } },
  { name: 'Null operator', input: { operator: null } },
  { name: 'Undefined value', input: { value: undefined } },
  { name: 'Zero limit', input: { limit: 0 } },
  { name: 'Negative offset', input: { offset: -1 } },
  { name: 'Empty array', input: { filters: [] } },
  { name: 'Special chars', input: { value: "test@#$%" } }
];

for (const edgeCase of edgeCases) {
  try {
    const result = await testFunction(edgeCase.input);
    console.log(`✓ ${edgeCase.name}:`, result);
  } catch (error) {
    console.log(`✗ ${edgeCase.name}:`, error.message);
  }
}
```

---

## Performance Testing

### Timing Individual Operations

```typescript
console.time('operation');
await operation();
console.timeEnd('operation');
// Output: operation: 245ms
```

### Comparing Before/After Performance

```typescript
// Before fix
console.time('before');
await oldImplementation();
console.timeEnd('before');
// Output: before: 500ms

// After fix
console.time('after');
await newImplementation();
console.timeEnd('after');
// Output: after: 250ms

// 50% improvement
```

### Load Testing

```typescript
const iterations = 100;
const startTime = Date.now();

for (let i = 0; i < iterations; i++) {
  await operation();
}

const totalTime = Date.now() - startTime;
const avgTime = totalTime / iterations;

console.log(`Total time: ${totalTime}ms`);
console.log(`Average time: ${avgTime}ms`);
console.log(`Operations/sec: ${1000 / avgTime}`);
```

### Memory Impact

```typescript
const memBefore = process.memoryUsage();

// Run operation
await operation();

const memAfter = process.memoryUsage();
const memDelta = memAfter.heapUsed - memBefore.heapUsed;

console.log(`Memory increase: ${Math.round(memDelta / 1024 / 1024)}MB`);
```

---

## Test Documentation

### Test Report Template

```markdown
# Test Report: [Bug Fix Name]

## Date
2025-11-15

## Bug Description
[What was broken]

## Test Cases

### Test 1: [Name]
- Input: {...}
- Expected: Success
- Actual: Success ✓

### Test 2: [Name]
- Input: {...}
- Expected: Error message
- Actual: Error message ✓

## Regression Tests
- [x] Existing feature 1 still works
- [x] Existing feature 2 still works
- [x] Edge case 1 handled
- [x] Edge case 2 handled

## Performance
- Before: 500ms
- After: 250ms
- Improvement: 50%

## Conclusion
All tests passed. Fix verified and safe to deploy.
```

### Inline Test Documentation

```typescript
/**
 * BUG FIX TEST: Filter operator normalization
 *
 * Issue: ValidationError for '=' operator
 * Fix: Normalize SQL-style to Xano-style operators
 *
 * Test Cases:
 * 1. '=' normalizes to 'eq' ✓
 * 2. '!=' normalizes to 'ne' ✓
 * 3. 'eq' still works ✓
 * 4. Invalid operators still fail ✓
 *
 * Verified: 2025-11-15
 */
```

---

## Best Practices

1. **Test before fixing** - Verify bug exists
2. **Test during fixing** - Verify debug logs show root cause
3. **Test after fixing** - Verify fix works
4. **Test regressions** - Verify nothing broke
5. **Test edge cases** - Verify robustness
6. **Document tests** - For future reference
7. **Keep test cases** - Reuse for regression testing
8. **Use real data** - Not mocks
9. **Automate when possible** - Reduce manual effort
10. **Version control tests** - Track test evolution

---

## Common Testing Mistakes

### Mistake 1: Testing with Mocks

**Don't:**
```typescript
const mockData = { id: 1, name: 'test' };
```

**Do:**
```typescript
const realData = { workspace: 5, instance: 10, table_name: 'actual_table' };
```

### Mistake 2: Not Testing Regressions

**Don't:** Only test the specific bug
**Do:** Test related functionality too

### Mistake 3: Removing Test Cases

**Don't:** Delete test cases after fix
**Do:** Keep them for future regression testing

### Mistake 4: Complex Test Cases

**Don't:** Test multiple things at once
**Do:** One test case per scenario

### Mistake 5: Not Documenting

**Don't:** Just run tests without recording results
**Do:** Document what was tested and results

---

## Summary

Effective testing during debug-fix-verify:
- Use real data
- Create minimal reproducible test cases
- Test before, during, and after fixing
- Check for regressions
- Document everything
- Keep test cases for future use

Testing is not optional - it's what verifies your fix actually works.
