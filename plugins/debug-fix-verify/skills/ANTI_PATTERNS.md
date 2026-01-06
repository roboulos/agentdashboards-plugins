# Anti-Patterns: What NOT to Do

Common mistakes to avoid when debugging and fixing bugs.

---

## Table of Contents

1. [Guessing Without Logging](#guessing-without-logging)
2. [Insufficient Logs](#insufficient-logs)
3. [Testing with Mock Data](#testing-with-mock-data)
4. [Removing Logs Too Early](#removing-logs-too-early)
5. [Not Documenting Findings](#not-documenting-findings)
6. [Fixing Multiple Bugs at Once](#fixing-multiple-bugs-at-once)
7. [Skipping Verification](#skipping-verification)
8. [Changing Unrelated Code](#changing-unrelated-code)

---

## Guessing Without Logging

### The Anti-Pattern

Making changes to code based on assumptions about what might be wrong, without first understanding what's actually happening.

### Example

**DON'T DO THIS:**
```typescript
// User reports: "Filter validation is failing"
// Developer thinks: "Probably the operator check is wrong"

// Makes change without investigating
if (!validOps.includes(operator)) {
  // Just remove this check, it's probably too strict
  // throw new Error(`Invalid operator: ${operator}`);
}
```

**Problems:**
- Might not fix the actual issue
- Could introduce new bugs
- Wastes time on wrong solutions
- Doesn't understand root cause

### The Right Way

```typescript
// Add debug logs FIRST
console.log('[Validate] Checking operator:', operator);
console.log('[Validate] Valid operators:', validOps);
console.log('[Validate] Is valid?', validOps.includes(operator));

// Build, deploy, test, check logs
// Logs show: operator="=" but validOps=["eq", "ne", "gt"]
// NOW you know the real issue

// Fix based on evidence
const operatorMap = { '=': 'eq', '!=': 'ne' };
const normalized = operatorMap[operator] || operator;
```

### Why It Matters

- **Guessing wastes time** - Multiple iterations of wrong fixes
- **Evidence finds root cause** - Logs show exactly what's wrong
- **Understanding prevents recurrence** - You learn the actual issue

### Key Principle

**"Never guess. Always log first, understand what's happening, then fix."**

---

## Insufficient Logs

### The Anti-Pattern

Adding only 1-2 logs, or logging only the obvious places, missing the actual problem location.

### Example

**DON'T DO THIS:**
```typescript
export async function processFilter(filter: any) {
  console.log('Processing filter');  // Too vague

  const validated = validateFilter(filter);
  const normalized = normalizeFilter(validated);
  const result = executeFilter(normalized);

  console.log('Done');  // Doesn't help

  return result;
}
```

**Problems:**
- Doesn't show which step fails
- Doesn't log intermediate values
- Can't see execution flow
- Wastes debugging time

### The Right Way

```typescript
export async function processFilter(filter: any) {
  console.log('[ProcessFilter] === ENTRY ===');
  console.log('[ProcessFilter] Input filter:', filter);

  console.log('[ProcessFilter] Step 1: Validate');
  const validated = validateFilter(filter);
  console.log('[ProcessFilter] Validated:', validated);

  console.log('[ProcessFilter] Step 2: Normalize');
  const normalized = normalizeFilter(validated);
  console.log('[ProcessFilter] Normalized:', normalized);

  console.log('[ProcessFilter] Step 3: Execute');
  const result = executeFilter(normalized);
  console.log('[ProcessFilter] Result:', result);

  console.log('[ProcessFilter] === EXIT ===');
  return result;
}
```

**Benefits:**
- Shows exact step where issue occurs
- Logs values at each stage
- Clear execution flow
- Quick problem identification

### Rule of Thumb

**Minimum 10+ logs for any bug investigation.**

If you can't identify the problem in logs, you didn't add enough logs.

---

## Testing with Mock Data

### The Anti-Pattern

Using fake, simplified, or made-up test data instead of the actual data that causes the bug.

### Example

**DON'T DO THIS:**
```typescript
// Bug report: "Filter failing for email field with '=' operator on users table"

// Test with simplified mock data
const testCase = {
  table: 'test',  // Not the real table
  filters: {
    field: 'id',  // Not the problematic field
    operator: 'eq'  // Not the problematic operator
  }
};
```

**Problems:**
- Might not reproduce the actual bug
- Missing real-world conditions
- False confidence when test passes
- Bug still exists in production

### The Right Way

```typescript
// Use EXACT data from bug report
const testCase = {
  workspace: 5,  // Actual workspace
  instance: 10,  // Actual instance
  table_name: 'users',  // Actual table
  filters: [{
    field: 'email',  // Actual field
    operator: '=',  // Actual operator that fails
    value: 'test@example.com'  // Actual value
  }]
};

// Test with this reproduces the exact bug
await mcp__xano-mcp__execute({
  tool_id: 'db_query',
  arguments: testCase
});
```

### Why It Matters

**Real data reveals real bugs.** Mock data might hide the issue or test the wrong thing.

### Key Principle

**"Always test with the exact data that reproduces the bug."**

---

## Removing Logs Too Early

### The Anti-Pattern

Removing debug logs before verifying the fix actually works.

### Example

**DON'T DO THIS:**
```typescript
// Step 1: Add logs
console.log('[Handler] Checking operator:', operator);

// Step 2: Implement fix
const normalized = normalizeOperator(operator);

// Step 3: IMMEDIATELY remove logs before testing
// No logs left to verify fix works!

// Step 4: Deploy and hope it works
```

**Problems:**
- Can't verify fix in logs
- If fix doesn't work, need to add logs again
- Wastes time with extra build/deploy cycles

### The Right Way

```typescript
// Step 1: Add logs
console.log('[Handler] Checking operator:', operator);

// Step 2: Implement fix (KEEP LOGS)
console.log('[Handler] Original operator:', operator);
const normalized = normalizeOperator(operator);
console.log('[Handler] Normalized operator:', normalized);

// Step 3: Build, deploy, test
// Step 4: Check logs - verify fix works
// Logs show: "Original: '=', Normalized: 'eq'" ✓

// Step 5: NOW remove logs
// Final clean version

// Step 6: Deploy clean code
```

### Proper Sequence

1. Add debug logs
2. Implement fix (keep logs)
3. Build & deploy
4. Test
5. **Check logs to verify fix works**
6. Remove debug logs
7. Build & deploy clean version

### Key Principle

**"Keep debug logs until you've verified the fix works."**

---

## Not Documenting Findings

### The Anti-Pattern

Fixing the bug but not recording what you found or how you fixed it.

### Example

**DON'T DO THIS:**
```bash
# Quick fix
git add .
git commit -m "fix validation"
git push
```

**Problems:**
- No record of what was wrong
- Can't learn from this bug
- Future similar bugs harder to fix
- Team doesn't benefit from knowledge

### The Right Way

```bash
git add .
git commit -m "fix(db-query): accept SQL-style operators in filters

Bug: Filter validation rejected '=' operator
Found: Debug logs showed code only accepted 'eq', 'ne', 'gt', 'lt'
      Users were providing SQL-style operators but code expected Xano-style
Fix: Added operator normalization map to convert SQL to Xano format
     Normalization: '=' -> 'eq', '!=' -> 'ne', '>' -> 'gt', etc.
Test: Verified both SQL-style and Xano-style operators work correctly

Before: ValidationError: Invalid operator '='
After: Successfully normalizes '=' to 'eq' and processes query

Related: db-query tool, filter validation, operator handling
"
git push
```

**Benefits:**
- Clear record of problem and solution
- Future reference for similar issues
- Team learns from this fix
- Documents the "why" not just the "what"

### Commit Message Template

```
fix(component): brief description

Bug: What was broken
Found: What debug logs revealed
Fix: How it was fixed
Test: Verification results

Before: [error or incorrect behavior]
After: [correct behavior]

Related: [related components or topics]
```

### Key Principle

**"Document findings so others (and future you) can learn from this bug."**

---

## Fixing Multiple Bugs at Once

### The Anti-Pattern

Trying to fix several bugs in one session, mixing changes together.

### Example

**DON'T DO THIS:**
```typescript
// Fixing three bugs at once
export async function handler(params: any) {
  // Bug 1: Filter operator validation
  const normalizedOp = normalizeOperator(params.operator);

  // Bug 2: Sort direction validation
  const normalizedDir = normalizeDirection(params.direction);

  // Bug 3: Pagination limit validation
  const validLimit = Math.min(params.limit, 100);

  // ...
}

// Single commit with all three fixes
git commit -m "fix bugs"
```

**Problems:**
- Hard to debug which fix solves which bug
- If one fix is wrong, have to revert all
- Can't track which change caused issues
- Logs are confusing with multiple changes
- Difficult to verify each fix independently

### The Right Way

```typescript
// Fix Bug 1 ONLY
export async function handler(params: any) {
  console.log('[Handler] Fixing operator normalization');
  const normalizedOp = normalizeOperator(params.operator);
  console.log('[Handler] Operator normalized:', normalizedOp);
  // ... rest unchanged
}

// Build, deploy, test, verify Bug 1 fix
// Remove logs, commit

git commit -m "fix(handler): normalize filter operators"

// THEN fix Bug 2 separately
// Then Bug 3 separately
```

**Benefits:**
- Clear cause and effect
- Easy to verify each fix
- Easy to revert if needed
- Clean commit history
- Focused debugging

### Key Principle

**"One bug, one fix, one commit. Don't batch bug fixes."**

---

## Skipping Verification

### The Anti-Pattern

Implementing a fix without testing it actually works.

### Example

**DON'T DO THIS:**
```typescript
// Add fix
const normalized = normalizeOperator(operator);

// Build and deploy
npm run build && npm run deploy

// Assume it works, move on
// ❌ Never tested!
```

**Problems:**
- Fix might not work
- Might break other things
- Bugs reach production
- Waste time later fixing the fix

### The Right Way

```typescript
// 1. Add fix
const normalized = normalizeOperator(operator);

// 2. Build and deploy
npm run build && npm run deploy

// 3. TEST with real data
await mcp__xano-mcp__execute({
  tool_id: 'db_query',
  arguments: testCase
});

// 4. CHECK LOGS
wrangler tail
// Verify: Logs show fix working

// 5. TEST REGRESSIONS
// Test other use cases still work

// 6. VERIFIED - Now can remove debug logs and finalize
```

### Verification Checklist

- [ ] Bug no longer occurs
- [ ] Expected behavior happens
- [ ] No new errors introduced
- [ ] Related functionality still works
- [ ] Performance is acceptable
- [ ] Logs show correct execution

### Key Principle

**"Never assume a fix works. Always verify with tests and logs."**

---

## Changing Unrelated Code

### The Anti-Pattern

Refactoring, improving, or changing code that's not related to the bug being fixed.

### Example

**DON'T DO THIS:**
```typescript
// Bug: Filter operator validation failing

export async function handler(params: any) {
  // Fix the bug
  const normalized = normalizeOperator(params.operator);

  // But also refactor unrelated code...
  // ❌ Rename variables
  const usr = params.user; // was: user

  // ❌ Change formatting
  const { a, b, c } = params; // was multiline

  // ❌ Add new feature
  if (params.cache) {
    cacheResult(result); // Not part of bug fix!
  }

  // ❌ Update unrelated logic
  // Completely different function improved
}
```

**Problems:**
- Hard to identify what fixed the bug
- Mixing concerns in one commit
- Risk of introducing new bugs
- Difficult code review
- Confusing for future debugging

### The Right Way

```typescript
// ONLY fix the specific bug

export async function handler(params: any) {
  // Fix the bug - ONLY this change
  const normalized = normalizeOperator(params.operator);

  // Everything else unchanged
  const user = params.user;

  const {
    field1,
    field2,
    field3
  } = params;

  // ... rest of code exactly as it was
}

// Separate commit later for refactoring
// Separate commit for new features
```

### When to Change Other Code

**OK to change:**
- Code directly related to the bug
- Code in the execution path that's broken
- Tests for the fixed functionality

**NOT OK to change:**
- Formatting or style
- Unrelated features
- "While I'm here" improvements
- Refactoring for the sake of refactoring

### Key Principle

**"Fix ONLY what's broken. Don't refactor during bug fixes."**

---

## Summary: Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Right Approach |
|-------------|--------------|----------------|
| Guessing without logging | Wastes time, might not fix root cause | Add logs, understand, then fix |
| Insufficient logs | Can't find the problem | 10+ logs minimum |
| Testing with mock data | Might not reproduce bug | Use real data that causes bug |
| Removing logs too early | Can't verify fix works | Keep logs until verified |
| Not documenting | Knowledge lost | Detailed commit messages |
| Fixing multiple bugs | Hard to debug and verify | One bug at a time |
| Skipping verification | Fix might not work | Always test and verify |
| Changing unrelated code | Confuses cause and effect | Only fix what's broken |

---

## How to Avoid These Mistakes

1. **Follow the workflow** - Steps exist for a reason
2. **Be systematic** - Don't skip steps
3. **Be patient** - Rushing leads to mistakes
4. **Document everything** - Future you will thank you
5. **Focus** - One bug, one fix, one commit
6. **Verify** - Never assume, always test
7. **Learn** - Each bug teaches a lesson

---

## The Cost of Anti-Patterns

**Guessing approach (anti-pattern):**
- 3-4 wrong fixes tried: 2 hours
- Still not fixed: another day
- Total: 1+ days, frustration

**Debug-fix-verify approach (right way):**
- Add logs: 5 min
- Test and analyze: 10 min
- Fix based on evidence: 5 min
- Verify: 5 min
- Total: 25 minutes, confidence

**The systematic approach is 10x faster and 100x more reliable.**

---

## Remember

The debug-fix-verify cycle exists because these anti-patterns are common and costly. Following the systematic approach prevents these mistakes and leads to faster, more reliable bug fixes.

**When in doubt, add more logs and follow the process.**
