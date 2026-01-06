# Playwright Debugging Patterns

Comprehensive debugging guide for common Playwright automation issues.

## Table of Contents

1. [Element Not Found Errors](#element-not-found-errors)
2. [Timing and Race Conditions](#timing-and-race-conditions)
3. [Network Request Failures](#network-request-failures)
4. [Console Error Diagnosis](#console-error-diagnosis)
5. [Screenshot Comparison](#screenshot-comparison-debugging)
6. [Form Submission Issues](#form-submission-issues)
7. [Dialog and Popup Problems](#dialog-and-popup-problems)

---

## Element Not Found Errors

### Symptom
Error: "Element not found" or "Invalid ref"

### Debugging Steps

**Step 1: Verify Element Exists**
```
1. Take fresh snapshot
2. Search snapshot output for element text
3. Verify element is visible in current state
```

**Step 2: Check Element Visibility**
Elements might be:
- Hidden by CSS (display: none, visibility: hidden)
- Outside viewport (need scrolling)
- Behind another element (z-index issues)
- Inside collapsed accordion/tab

**Step 3: Wait for Dynamic Content**
```
1. Identify if element loads dynamically
2. Add wait condition:
   - browser_wait_for with expected text
   - browser_wait_for for loading spinner to disappear
3. Then take snapshot
```

**Step 4: Verify Ref is Current**
```
❌ Using old ref from previous snapshot
✅ Take new snapshot, use fresh ref
```

### Common Causes

| Cause | Solution |
|-------|----------|
| Element not loaded yet | Add browser_wait_for before snapshot |
| Wrong page | Verify navigation completed |
| Element inside iframe | Iframes require special handling |
| Dynamic ref changed | Always use latest snapshot |
| Element hidden | Check CSS, wait for animation |

---

## Timing and Race Conditions

### Symptom
Works sometimes, fails other times; "flaky" behavior

### Debugging Steps

**Step 1: Identify Race Condition**
```
Common scenarios:
- Clicking before element ready
- Reading data before API loads it
- Submitting form before validation complete
- Screenshot before render complete
```

**Step 2: Add Explicit Waits**
```
Instead of:
1. Click "Load More"
2. Snapshot

Do:
1. Click "Load More"
2. Wait for specific text: browser_wait_for text="Item 21"
3. Snapshot
```

**Step 3: Wait for Network Quiet**
```
After action that triggers API call:
1. Perform action (click, submit)
2. browser_wait_for textGone="Loading..."
3. browser_network_requests to verify call completed
4. Check console for errors
5. Proceed with next step
```

### Wait Strategies

**Good Waits** (Reliable):
- Wait for specific text to appear
- Wait for loading indicator to disappear
- Wait for expected number of items
- Wait for network request to complete

**Bad Waits** (Unreliable):
- Fixed time delays (browser_wait_for time=2)
- Arbitrary timeouts
- Assuming load time

### Pattern: Robust Wait

```
Step 1: Trigger action
→ browser_click on "Submit"

Step 2: Wait for loading to start (optional)
→ browser_wait_for text="Processing..."

Step 3: Wait for loading to finish
→ browser_wait_for textGone="Processing..."

Step 4: Wait for result
→ browser_wait_for text="Success"

Step 5: Verify
→ browser_snapshot
→ browser_console_messages onlyErrors=true
```

---

## Network Request Failures

### Symptom
Form submission fails, data doesn't load, API errors

### Debugging Steps

**Step 1: Check Network Tab**
```
browser_network_requests

Look for:
- 4xx errors (400, 401, 403, 404)
- 5xx errors (500, 502, 503)
- Failed requests (no status code)
- Slow requests (>3s response time)
```

**Step 2: Verify API Call Was Made**
```
Expected: POST to /api/submit
Actual: No matching request

Causes:
- Form validation prevented submission
- JavaScript error blocked request
- Button not actually clickable
```

**Step 3: Check Console for Network Errors**
```
browser_console_messages onlyErrors=true

Common error patterns:
- "Failed to fetch" → CORS or network issue
- "404 Not Found" → Wrong API endpoint
- "401 Unauthorized" → Auth token missing/expired
- "Network request failed" → Server down/unreachable
```

**Step 4: Verify Request Payload**
```
browser_network_requests

Check:
- Request method (GET vs POST)
- Request URL (correct endpoint?)
- Timing (request made when expected?)
```

### Common Network Issues

| Status Code | Meaning | Debug Steps |
|-------------|---------|-------------|
| 400 | Bad Request | Check form data validation |
| 401 | Unauthorized | Check auth token/cookies |
| 403 | Forbidden | Check permissions |
| 404 | Not Found | Verify API endpoint URL |
| 500 | Server Error | Check server logs |
| CORS error | Cross-origin blocked | Check server CORS config |

---

## Console Error Diagnosis

### Symptom
Functionality broken, unexpected behavior

### Debugging Steps

**Step 1: Check Console After Every Action**
```
After any interaction:
browser_console_messages onlyErrors=true
```

**Step 2: Categorize Errors**

**JavaScript Errors**:
```
TypeError: Cannot read property 'x' of undefined
ReferenceError: variable is not defined
→ Frontend code bugs
```

**Network Errors**:
```
Failed to load resource: the server responded with 404
CORS policy: No 'Access-Control-Allow-Origin'
→ API/backend issues
```

**React/Framework Errors**:
```
Warning: Each child in a list should have a unique "key" prop
Error: Minified React error #31
→ Framework-specific issues
```

**Step 3: Read Error Messages Carefully**
Console errors often explain:
- What went wrong
- Which file/line caused it
- What value was unexpected

**Step 4: Reproduce Error**
```
1. Note exact steps before error
2. Take screenshot at error point
3. Check network requests at error point
4. Verify page state with snapshot
```

### Error Priority

**Critical** (Fix immediately):
- Uncaught exceptions
- Failed API requests
- Authentication errors

**Important** (Fix soon):
- React warnings
- Deprecation notices
- Performance warnings

**Informational** (Can ignore):
- Development-only warnings
- Third-party library info logs

---

## Screenshot Comparison Debugging

### Use Case
Visual regression testing, verifying layouts

### Pattern: Before/After Screenshots

```
Step 1: Take baseline screenshot
→ browser_navigate to page
→ browser_wait_for text="Page loaded"
→ browser_take_screenshot filename="before.png"

Step 2: Perform action
→ browser_click on element

Step 3: Take comparison screenshot
→ browser_wait_for expected change
→ browser_take_screenshot filename="after.png"

Step 4: Manually compare
→ Look at before.png vs after.png
→ Verify expected change occurred
```

### Screenshot Best Practices

**For Consistency**:
- Use same viewport size (browser_resize)
- Wait for fonts/images to load
- Hide dynamic content (timestamps, randomized elements)
- Take full page screenshots for layout testing

**For Debugging**:
- Screenshot before error
- Screenshot after error
- Screenshot expected vs actual state
- Element-specific screenshots for focused testing

---

## Form Submission Issues

### Symptom
Form doesn't submit, validation fails, data not saved

### Debugging Checklist

**Step 1: Verify Form Fields Filled**
```
After browser_fill_form:
→ browser_snapshot
→ Verify values appear in fields
→ Check for validation error messages
```

**Step 2: Check Required Fields**
```
Common issue: Missing required field
→ Snapshot shows which fields are empty
→ Browser validation may block submit
```

**Step 3: Verify Submit Button Clickable**
```
→ browser_snapshot
→ Find submit button in snapshot
→ Check if button is enabled (not disabled attribute)
```

**Step 4: Check Form Validation**
```
After filling form:
→ browser_console_messages
→ Look for validation errors
→ Check for error messages in snapshot
```

**Step 5: Monitor Submission**
```
→ browser_click submit button
→ browser_wait_for text="Success" or textGone="Loading"
→ browser_network_requests to verify POST
→ browser_console_messages to check for errors
```

### Common Form Issues

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Client validation fails | No network request | Check console, fix field values |
| Submit button disabled | Click has no effect | Verify all required fields filled |
| Server validation fails | 400 status code | Check network request payload |
| CSRF token missing | 403 status code | Check if form includes CSRF token |
| Captcha required | Form blocks submission | May need manual intervention |

---

## Dialog and Popup Problems

### Symptom
Alerts/confirms/prompts block automation

### Debugging Steps

**Step 1: Detect Dialog**
```
If action triggers dialog:
→ Immediately call browser_handle_dialog
→ Dialog blocks other operations until handled
```

**Step 2: Handle Dialog Appropriately**
```
For alert:
→ browser_handle_dialog accept=true

For confirm (test both paths):
→ browser_handle_dialog accept=true (confirm)
→ browser_handle_dialog accept=false (cancel)

For prompt:
→ browser_handle_dialog accept=true promptText="response"
```

**Step 3: Verify Dialog Handling**
```
After handling:
→ browser_snapshot (verify page state)
→ browser_console_messages (check for errors)
```

### Dialog Timing

**Immediate Handling Required**:
```
❌ Wrong:
1. Click button
2. Take snapshot ← Dialog blocks this!

✅ Right:
1. Click button
2. browser_handle_dialog accept=true
3. Take snapshot
```

### Multiple Dialogs

```
If action triggers multiple dialogs in sequence:
1. Click button
2. browser_handle_dialog (first dialog)
3. browser_handle_dialog (second dialog)
4. Continue workflow
```

---

## General Debugging Workflow

### When Something Goes Wrong

**Level 1: Quick Check**
```
1. browser_console_messages onlyErrors=true
2. Read error messages
3. Fix obvious issues
```

**Level 2: Detailed Investigation**
```
1. browser_snapshot (current state)
2. browser_console_messages (all messages)
3. browser_network_requests (API calls)
4. browser_take_screenshot (visual evidence)
5. Review each for clues
```

**Level 3: Step-by-Step Reproduction**
```
1. Start from beginning
2. Add waits between steps
3. Snapshot after each step
4. Check console after each step
5. Identify exact point of failure
```

### Debug Output Template

```
## Debug Report

**Issue**: [Describe what's not working]

**Steps Taken**:
1. [Action]
2. [Action]
3. [Failure point]

**Console Errors**:
[Output from browser_console_messages]

**Network Requests**:
[Relevant requests from browser_network_requests]

**Page State**:
[Relevant excerpt from browser_snapshot]

**Screenshot**:
[Reference to screenshot file]

**Expected Behavior**:
[What should happen]

**Actual Behavior**:
[What actually happened]
```

---

## Performance Debugging

### Symptom
Automation is slow, timeouts occur

### Debugging Steps

**Step 1: Identify Slow Operations**
```
browser_network_requests

Look for:
- Requests taking >3 seconds
- Multiple requests to same endpoint
- Large file downloads
- Slow API responses
```

**Step 2: Optimize Waits**
```
Replace fixed waits with specific waits:
❌ browser_wait_for time=5
✅ browser_wait_for text="Expected result"
```

**Step 3: Batch Operations**
```
❌ Slow: Multiple individual type calls
browser_type field1
browser_type field2
browser_type field3

✅ Fast: Single form fill
browser_fill_form with all fields
```

**Step 4: Minimize Snapshots**
```
Take snapshots only when needed:
- Before interactions (to get refs)
- After dynamic content loads
- When verifying results

Don't snapshot unnecessarily between every step
```

---

**Remember**: When debugging, always check console, network, and snapshots!
