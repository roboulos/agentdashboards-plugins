# Advanced Playwright Patterns

Advanced automation patterns for complex scenarios.

## Multi-Tab Workflows

### Pattern: Open Link in New Tab

```
Step 1: List current tabs
→ browser_tabs action="list"

Step 2: Open new tab
→ browser_tabs action="new"

Step 3: Navigate in new tab
→ browser_navigate url="https://example.com"

Step 4: Work in new tab
→ (perform actions)

Step 5: Switch back to original tab
→ browser_tabs action="select" index=0

Step 6: Close tab when done
→ browser_tabs action="close" index=1
```

### Pattern: Compare Content Across Tabs

```
1. Open page 1 in tab 0
2. Take snapshot, save relevant data
3. Create new tab
4. Open page 2 in tab 1
5. Take snapshot, compare with saved data
6. Switch between tabs as needed
```

## File Upload Automation

### Pattern: Upload Single File

```
Step 1: Trigger file chooser
→ browser_click element="Upload button" ref="ref-from-snapshot"

Step 2: Upload file immediately after
→ browser_file_upload paths=["/absolute/path/to/file.pdf"]

Step 3: Verify upload
→ browser_wait_for text="Upload complete"
→ browser_snapshot to verify file listed
```

### Pattern: Upload Multiple Files

```
browser_file_upload paths=[
  "/path/to/file1.pdf",
  "/path/to/file2.png",
  "/path/to/file3.docx"
]
```

### Pattern: Cancel File Upload

```
browser_file_upload paths=[]
```

## Dialog Handling Strategies

### Pattern: Handle Alert Chain

```
1. Perform action that triggers first alert
2. browser_handle_dialog accept=true
3. Second alert appears automatically
4. browser_handle_dialog accept=true
5. Continue workflow
```

### Pattern: Test Confirm Dialog Both Ways

```
Test Path 1: Accept
1. Click "Delete"
2. browser_handle_dialog accept=true
3. Verify item deleted

Test Path 2: Cancel
1. Click "Delete"
2. browser_handle_dialog accept=false
3. Verify item still exists
```

### Pattern: Prompt Dialog with Input

```
1. Click "Rename"
2. browser_handle_dialog accept=true promptText="New Name"
3. Verify name changed
```

## JavaScript Evaluation Patterns

### Pattern: Get Computed Styles

```
browser_evaluate
  element="Target element"
  ref="ref-42"
  function="(el) => window.getComputedStyle(el).backgroundColor"
```

### Pattern: Check Element Visibility

```
browser_evaluate
  element="Hidden element"
  ref="ref-99"
  function="(el) => el.offsetParent !== null"
```

### Pattern: Get Custom Data Attributes

```
browser_evaluate
  element="Product card"
  ref="ref-10"
  function="(el) => el.dataset.productId"
```

### Pattern: Access Window Properties

```
browser_evaluate
  function="() => ({ width: window.innerWidth, height: window.innerHeight })"
```

## Custom Wait Conditions

### Pattern: Wait for Element Count

```
1. Trigger "Load More"
2. browser_wait_for text="Item 21" (specific item appears)
3. Continue
```

### Pattern: Wait for Loading to Complete

```
1. Perform action
2. browser_wait_for text="Loading..." (appears)
3. browser_wait_for textGone="Loading..." (disappears)
4. Verify result
```

### Pattern: Polling with Snapshots

```
For dynamically updating content:
1. Take initial snapshot
2. Wait fixed time: browser_wait_for time=2
3. Take new snapshot
4. Compare snapshots manually
5. Repeat if needed
```

## Performance Testing

### Pattern: Measure Page Load Time

```
1. Note start time
2. browser_navigate
3. browser_wait_for text="Page loaded indicator"
4. browser_network_requests
5. Analyze request timing
```

### Pattern: Monitor API Response Times

```
1. Perform action (search, filter, etc)
2. browser_network_requests
3. Find relevant API call
4. Check response time
5. Flag if > threshold (e.g., 3 seconds)
```

## Accessibility Testing

### Pattern: Check Page Structure

```
1. browser_snapshot
2. Verify hierarchical structure
3. Check for proper headings
4. Verify interactive elements have labels
```

### Pattern: Keyboard Navigation

```
1. browser_press_key key="Tab"
2. Take snapshot (verify focus moved)
3. browser_press_key key="Tab"
4. Take snapshot (verify next element focused)
5. browser_press_key key="Enter"
6. Verify action triggered
```

## Mobile Testing

### Pattern: Test Mobile Viewport

```
1. browser_resize width=375 height=667 (iPhone)
2. browser_navigate
3. browser_snapshot (verify mobile layout)
4. Test mobile-specific features
```

### Common Mobile Viewports

```
iPhone SE: 375x667
iPhone 12/13: 390x844
iPhone 14 Pro Max: 430x932
Samsung Galaxy: 360x640
iPad: 768x1024
iPad Pro: 1024x1366
```

## Form Validation Testing

### Pattern: Test Client-Side Validation

```
1. Fill form with invalid data
2. browser_click submit
3. browser_snapshot (verify validation messages)
4. browser_console_messages (check for errors)
5. Fix data
6. Submit successfully
```

### Pattern: Test Required Fields

```
1. Leave field empty
2. Click submit
3. Verify browser validation blocks submit
4. Check for HTML5 validation message
```

## Dynamic Content Patterns

### Pattern: Infinite Scroll

```
1. browser_snapshot (count initial items)
2. browser_evaluate function="() => window.scrollTo(0, document.body.scrollHeight)"
3. browser_wait_for for new content indicator
4. browser_snapshot (verify more items loaded)
```

### Pattern: Auto-Refresh Content

```
1. Take initial snapshot (note timestamp/content)
2. browser_wait_for time=30 (or until refresh expected)
3. browser_snapshot (compare with initial)
4. Verify content updated
```

## Error Recovery Patterns

### Pattern: Retry on Failure

```
Try action:
1. Attempt interaction
2. Check console for errors
3. If error: Wait and retry
4. If success: Continue

Example:
1. Click button
2. browser_console_messages onlyErrors=true
3. If errors found:
   - browser_wait_for time=1
   - Refresh snapshot
   - Try click again
```

### Pattern: Fallback Strategy

```
Try primary method:
1. Attempt browser_click on button

If fails:
2. Fallback to JavaScript click:
   browser_evaluate
     element="Button"
     ref="ref-x"
     function="(el) => el.click()"
```

---

**Remember**: Advanced patterns require careful testing and error handling!
