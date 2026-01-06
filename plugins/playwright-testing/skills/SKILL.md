---
name: playwright-browser-automation
description: Expert guidance for Playwright MCP browser automation including snapshots, navigation, interactions, form filling, testing, debugging, and best practices. Use when automating browsers, testing web applications, scraping websites, taking screenshots, filling forms, clicking elements, evaluating JavaScript, handling dialogs, monitoring network requests, or debugging frontend issues with Playwright.
---

# Playwright Browser Automation Expert

## Purpose

Optimize Playwright MCP usage for browser automation tasks including web testing, scraping, form automation, debugging, and visual testing. This skill prevents common mistakes and enforces best practices for reliable, efficient browser automation.

## When to Use This Skill

Automatically activates when working with:
- Browser automation and web testing
- Playwright MCP tools and commands
- Web scraping and data extraction
- Form filling and user interaction simulation
- Screenshot and visual testing
- Debugging frontend applications
- Network monitoring and API testing
- Dialog and popup handling

---

## 🎯 Core Workflow Philosophy

### The Snapshot-First Rule

**ALWAYS use `browser_snapshot` before taking any action on the page.**

```
❌ WRONG: Guess element selectors
✅ RIGHT: Snapshot → Find element → Use exact ref
```

**Why this matters:**
- Snapshots provide exact element references (`ref` attribute)
- Guessing selectors = 80% failure rate
- Using snapshot refs = 95%+ success rate
- Snapshots show current page state (what's actually visible)

### Standard Workflow Pattern

```
1. Navigate to URL (browser_navigate)
2. Take snapshot (browser_snapshot)
3. Analyze snapshot for target elements
4. Interact using exact refs from snapshot
5. Verify result (another snapshot or console check)
```

---

## 🚀 Quick Start Patterns

### Pattern 1: Navigate and Interact

```markdown
**Step 1: Navigate**
- Use: browser_navigate
- URL: Full URL including protocol

**Step 2: Snapshot**
- Use: browser_snapshot
- Get current page state

**Step 3: Find Element**
- Review snapshot for target element
- Copy exact `ref` attribute value

**Step 4: Interact**
- Use: browser_click, browser_type, browser_select_option
- Provide: element description + exact ref
```

### Pattern 2: Form Filling

```markdown
**Best Practice: Use browser_fill_form for multiple fields**

Advantages:
- Single tool call for entire form
- Atomic operation (all or nothing)
- Faster than individual field fills
- Built-in validation

Steps:
1. Snapshot to see form structure
2. Identify all field refs
3. Call browser_fill_form with all fields
```

### Pattern 3: Testing Flow

```markdown
1. Navigate to page
2. Snapshot (verify page loaded)
3. Fill form / interact with elements
4. Submit / trigger action
5. Wait for result (browser_wait_for)
6. Snapshot (verify expected result)
7. Check console for errors (browser_console_messages)
8. Verify network requests (browser_network_requests)
```

---

## 📋 Essential Tool Categories

### Navigation Tools
- **browser_navigate** - Go to URL
- **browser_navigate_back** - Go back one page
- **browser_tabs** - Manage multiple tabs

### Inspection Tools
- **browser_snapshot** - 🌟 MOST IMPORTANT - Get page state
- **browser_console_messages** - Check for JavaScript errors
- **browser_network_requests** - Monitor API calls

### Interaction Tools
- **browser_click** - Click elements (needs ref from snapshot)
- **browser_type** - Type into inputs (needs ref from snapshot)
- **browser_fill_form** - Fill multiple fields atomically
- **browser_select_option** - Select dropdown options
- **browser_hover** - Hover over elements
- **browser_drag** - Drag and drop

### Advanced Tools
- **browser_evaluate** - Run JavaScript in page context
- **browser_handle_dialog** - Handle alerts/confirms/prompts
- **browser_file_upload** - Upload files
- **browser_press_key** - Keyboard actions
- **browser_wait_for** - Wait for text/conditions
- **browser_take_screenshot** - Visual capture

### Utility Tools
- **browser_resize** - Change viewport size
- **browser_close** - Close browser
- **browser_install** - Install browser if needed

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake #1: Not Using Snapshots

```markdown
BAD:
"Click the submit button"
→ Tool call: browser_click with guessed selector

GOOD:
"Take snapshot to find submit button"
→ browser_snapshot
→ Find submit button in results
→ browser_click with exact ref from snapshot
```

### ❌ Mistake #2: Not Waiting for Dynamic Content

```markdown
BAD:
1. Click "Load Data"
2. Immediately snapshot
→ Data not loaded yet!

GOOD:
1. Click "Load Data"
2. Wait for data: browser_wait_for with expected text
3. Snapshot to verify
```

### ❌ Mistake #3: Ignoring Console Errors

```markdown
BAD:
"Form submitted successfully"
→ Didn't check console for JavaScript errors

GOOD:
1. Submit form
2. Check console: browser_console_messages(onlyErrors: true)
3. Verify no errors before confirming success
```

### ❌ Mistake #4: Individual Field Fills Instead of Form Fill

```markdown
BAD:
browser_type for field 1
browser_type for field 2
browser_type for field 3
→ 3 separate snapshots needed!

GOOD:
browser_fill_form with all fields
→ Single atomic operation
```

### ❌ Mistake #5: Not Using Element Refs

```markdown
BAD:
element: "Submit button"
ref: "button.submit-btn"
→ Guessed selector, likely to fail

GOOD:
element: "Submit button"
ref: "ref-123"
→ Exact ref from snapshot, will work
```

---

## 🔍 Debugging Workflows

For detailed debugging patterns, see:
- [resources/debugging-patterns.md](resources/debugging-patterns.md)

**Quick Debug Checklist:**
1. ✅ Take fresh snapshot
2. ✅ Check console errors (onlyErrors: true)
3. ✅ Check network requests (API failures?)
4. ✅ Verify element is visible in snapshot
5. ✅ Use exact ref from snapshot
6. ✅ Wait for dynamic content if needed

---

## 📚 Reference Files

For detailed information on specific topics:

### [resources/tool-reference.md](resources/tool-reference.md)
Complete reference for all Playwright MCP tools:
- Tool-by-tool documentation
- Parameters and options
- Real-world examples
- Common pitfalls per tool

### [resources/debugging-patterns.md](resources/debugging-patterns.md)
Comprehensive debugging guide:
- Element not found errors
- Timing issues and race conditions
- Network request failures
- Console error diagnosis
- Screenshot comparison debugging

### [resources/advanced-patterns.md](resources/advanced-patterns.md)
Advanced automation patterns:
- Multi-tab workflows
- File upload automation
- Dialog handling strategies
- JavaScript evaluation patterns
- Custom wait conditions
- Performance testing

### [resources/testing-strategies.md](resources/testing-strategies.md)
Testing-focused workflows:
- End-to-end test patterns
- Visual regression testing
- API testing via network monitoring
- Accessibility testing
- Mobile viewport testing
- Cross-browser considerations

---

## 🎓 Best Practices Summary

### Always Do
✅ Take snapshot before every interaction
✅ Use exact `ref` values from snapshots
✅ Check console for errors after actions
✅ Use `browser_fill_form` for multiple fields
✅ Wait for dynamic content with `browser_wait_for`
✅ Monitor network requests for API issues
✅ Close browser when done to free resources

### Never Do
❌ Guess element selectors
❌ Skip snapshots to "save time"
❌ Ignore console errors
❌ Assume content loaded without waiting
❌ Use individual type calls for forms
❌ Leave browsers open indefinitely

---

## Quick Command Reference

```bash
# Take snapshot (do this first!)
browser_snapshot

# Navigate
browser_navigate url="https://example.com"

# Fill entire form (preferred)
browser_fill_form fields=[{name:"...", ref:"...", value:"..."}, ...]

# Click element (use ref from snapshot)
browser_click element="Submit" ref="ref-from-snapshot"

# Wait for content
browser_wait_for text="Success"

# Check for errors
browser_console_messages onlyErrors=true

# Check network
browser_network_requests

# Take screenshot
browser_take_screenshot filename="test.png"
```

---

## Performance Tips

1. **Batch Operations**: Use `browser_fill_form` instead of multiple `browser_type` calls
2. **Minimize Snapshots**: But don't skip them when needed
3. **Use Waits Wisely**: Wait for specific text/elements, not arbitrary timeouts
4. **Close When Done**: Free browser resources with `browser_close`
5. **Resize Appropriately**: Use `browser_resize` for mobile testing only when needed

---

**Skill Status**: ACTIVE ✅
**Line Count**: < 500 (following 500-line rule) ✅
**Progressive Disclosure**: Reference files for detailed patterns ✅

**Remember**: Snapshot first, use exact refs, verify results!
