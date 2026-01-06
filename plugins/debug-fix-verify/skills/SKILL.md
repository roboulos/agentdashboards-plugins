---
name: debug-fix-verify-agent
description: Systematic debug-log-test-fix-verify workflow for fixing bugs in production code. Use when debugging issues, fixing bugs, investigating unexpected behavior, or implementing features that require understanding current code behavior first. Covers adding debug logs, testing with real data, analyzing logs, implementing fixes, verifying fixes work, and clean deployment. Keywords - debug, fix bug, troubleshoot, investigate issue, wrangler tail, console log, test fix, verify fix, not working, broken, incorrect behavior, unexpected result, production bug.
---

# Debug-Fix-Verify Agent

## Purpose

Provides a systematic, proven workflow for fixing bugs in production code by understanding current behavior through debug logging before making changes. Prevents guessing and ensures fixes are based on actual execution flow analysis.

## When to Use This Skill

Automatically activates when you mention:
- Fixing bugs or debugging issues
- Investigating why something doesn't work
- Understanding current code behavior
- Testing and verifying fixes
- Production issues or unexpected behavior
- Adding logs or troubleshooting

---

## Core Philosophy

**NEVER GUESS - ALWAYS LOG FIRST**

The fundamental principle: Before changing code, understand what it's actually doing through comprehensive debug logging. Let the logs tell you where the problem is, don't assume.

---

## Quick Start: The 7-Step Cycle

```
1. Add Debug Logs (10+ strategic logs)
2. Build & Deploy
3. Test with Real Data
4. Check Logs (wrangler tail)
5. Implement Fix (based on findings)
6. Verify Fix Works
7. Clean & Commit
```

**Time Investment:** 15-30 minutes per bug
**Success Rate:** 95%+ when followed systematically

---

## Navigation Guide

| Need to... | Read this |
|------------|-----------|
| Complete workflow with examples | [WORKFLOW.md](WORKFLOW.md) |
| Debug logging patterns | [DEBUG_PATTERNS.md](DEBUG_PATTERNS.md) |
| Testing strategies | [TESTING.md](TESTING.md) |
| Common pitfalls to avoid | [ANTI_PATTERNS.md](ANTI_PATTERNS.md) |

---

## Quick Reference

### Step 1: Add Debug Logs

```typescript
// At function entry
console.log('[FunctionName] Called with params:', params);

// Before conditions
console.log('[FunctionName] Checking condition X:', value);

// Inside conditions
if (condition) {
  console.log('[FunctionName] Taking TRUE path for condition X');
} else {
  console.log('[FunctionName] Taking FALSE path for condition X');
}

// Before operations
console.log('[FunctionName] About to perform operation:', operation);

// After operations
console.log('[FunctionName] Operation result:', result);

// At function exit
console.log('[FunctionName] Returning:', returnValue);
```

**Rule of Thumb:** 10+ logs minimum for any bug investigation

### Step 2: Build & Deploy

```bash
npm run build && npm run deploy
```

Wait for deployment success confirmation.

### Step 3: Test with Real Data

```typescript
// Use MCP execute tool
mcp__xano-mcp__execute({
  tool_id: "tool_name",
  arguments: {
    // Actual test case that reproduces bug
  }
})
```

### Step 4: Check Logs

```bash
wrangler tail
```

Watch live logs, analyze debug output to understand execution flow.

### Step 5: Implement Fix

Based on what logs reveal, implement the actual fix:
- Keep debug logs initially
- Change only what's necessary
- Focus on root cause

### Step 6: Verify Fix

```bash
npm run build && npm run deploy
# Test again with same test case
# Check logs to confirm fix works
```

### Step 7: Clean & Commit

```typescript
// Remove all debug console.log statements
// Keep code production-ready
```

```bash
npm run build && npm run deploy
# Final verification test
git commit -m "fix: [description]

Bug: [what was broken]
Found: [what debug logs revealed]
Fix: [how it was fixed]
Test: [verification results]"
```

---

## Critical Success Factors

1. **Log Comprehensively** - Don't skimp on logs (10+ minimum)
2. **Test with Real Tools** - Use MCP execute or actual API calls
3. **Follow the Logs** - Let debug output guide you, don't assume
4. **Verify Before Cleaning** - Keep logs until fix confirmed
5. **One Issue at a Time** - Don't batch multiple bugs
6. **Document Findings** - Commit messages explain what logs showed

---

## Tools You'll Use

- **Bash tool** - For build/deploy commands
- **Edit tool** - For adding logs and implementing fixes
- **mcp__xano-mcp__execute** - For testing tools directly
- **wrangler tail** - For viewing live worker logs
- **git commit** - For final commits with findings

---

## Example Workflow Prompt

When you start debugging, follow this pattern:

```
I'll fix this systematically using the debug-log-test-fix-verify cycle:

1. Adding 10+ debug logs to understand current behavior
2. Building and deploying to test environment
3. Running test case and monitoring wrangler tail logs
4. Implementing fix based on findings
5. Verifying fix works with same test case
6. Removing debug logs for production
7. Final deploy and commit with detailed findings

Starting with debug logs in [file_name]...
```

---

## Common Bug Types

### Type 1: Logic Bugs
**Symptom:** Wrong results, incorrect behavior
**Debug Focus:** Log all conditions and branches
**Solution:** Usually in if/else logic or missing cases

### Type 2: Data Transformation Bugs
**Symptom:** Data in wrong format or missing fields
**Debug Focus:** Log inputs, transformations, outputs
**Solution:** Mapping issues or missing conversions

### Type 3: Validation Bugs
**Symptom:** Valid inputs rejected or invalid accepted
**Debug Focus:** Log validation checks and results
**Solution:** Incorrect validators or missing checks

### Type 4: Integration Bugs
**Symptom:** API calls fail or return unexpected data
**Debug Focus:** Log request/response pairs
**Solution:** Wrong parameters or response handling

---

## Performance Notes

### Build & Deploy Time
- Build: ~5-10 seconds
- Deploy: ~10-20 seconds
- Total cycle: ~30 seconds per iteration

### Logging Overhead
- Debug logs: Negligible performance impact
- Remove before final deployment for production cleanliness
- Keep critical error logs permanently

### Testing Time
- Per test: ~5-10 seconds
- Log analysis: ~2-5 minutes
- Total debug cycle: ~15-30 minutes per bug

---

## Resource Files

### [WORKFLOW.md](WORKFLOW.md)
Complete step-by-step workflow with detailed examples from real bug fixes. Shows before/after code, log output analysis, and decision-making process.

### [DEBUG_PATTERNS.md](DEBUG_PATTERNS.md)
Library of debug logging patterns for different scenarios:
- Function entry/exit logs
- Conditional logic logs
- Data transformation logs
- Error handling logs
- Integration point logs

### [TESTING.md](TESTING.md)
Testing strategies and patterns:
- Using MCP execute for direct tool testing
- Creating reproducible test cases
- Verifying fixes work
- Regression testing

### [ANTI_PATTERNS.md](ANTI_PATTERNS.md)
Common mistakes to avoid:
- Guessing without logging
- Insufficient logs
- Testing with mock data
- Removing logs too early
- Not documenting findings

---

## Related Skills

- **xano-mcp-tool-developer** - For MCP tool-specific debugging
- **backend-dev-guidelines** - For Node.js/TypeScript patterns
- **error-tracking** - For Sentry integration

---

## Success Metrics

A successful debug session includes:
- 10+ strategic debug logs added
- Real test case that reproduces bug
- Clear log output analyzed
- Root cause identified from logs
- Fix implemented based on findings
- Fix verified with same test case
- Debug logs removed
- Detailed commit message with findings

---

**Skill Status**: COMPLETE
**Line Count**: < 500
**Progressive Disclosure**: 4 resource files
**Proven Pattern**: Used successfully on 5+ production bugs
