# Playwright MCP Tool Reference

Complete reference for all 21 Playwright MCP tools with parameters, examples, and best practices.

## Table of Contents

1. [Navigation Tools](#navigation-tools)
2. [Inspection Tools](#inspection-tools)
3. [Interaction Tools](#interaction-tools)
4. [Form Tools](#form-tools)
5. [Advanced Tools](#advanced-tools)
6. [Utility Tools](#utility-tools)

---

## Navigation Tools

### browser_navigate

**Purpose**: Navigate to a URL

**Parameters**:
- `url` (required): Full URL including protocol (http:// or https://)

**Example**:
```json
{
  "url": "https://example.com/login"
}
```

**Best Practices**:
- Always include protocol (https:// or http://)
- Wait for page load before taking snapshot
- Check console after navigation for load errors

**Common Issues**:
- Missing protocol → Error
- Redirect handling → Automatic
- Slow page load → Increase timeout if needed

---

### browser_navigate_back

**Purpose**: Navigate to previous page in history

**Parameters**: None

**Example**:
```json
{}
```

**Best Practices**:
- Useful for multi-step workflows
- Take snapshot after going back
- Verify you're on expected page

**Common Issues**:
- No history → Error
- Page state may differ from first visit

---

### browser_tabs

**Purpose**: Manage browser tabs (list, create, close, select)

**Parameters**:
- `action` (required): "list" | "new" | "close" | "select"
- `index` (optional): Tab index for close/select actions

**Examples**:
```json
// List all tabs
{ "action": "list" }

// Create new tab
{ "action": "new" }

// Close tab by index
{ "action": "close", "index": 1 }

// Select tab by index
{ "action": "select", "index": 0 }
```

**Best Practices**:
- List tabs first to see current state
- Track tab indices when working with multiple tabs
- Close unused tabs to free resources

---

## Inspection Tools

### browser_snapshot

**Purpose**: 🌟 Capture accessibility snapshot of current page state

**Parameters**: None

**Returns**:
- Hierarchical page structure
- Element refs for interactions
- Visible text and labels
- Interactive element states

**Example**:
```json
{}
```

**Best Practices**:
- **ALWAYS use before interacting with elements**
- Use returned `ref` values for clicks/types
- Re-snapshot after dynamic content loads
- Review snapshot to understand page structure

**Why This Is Critical**:
- Provides exact element references
- Shows what's actually visible
- Prevents guessing selectors
- Faster than screenshots for automation

**When to Re-Snapshot**:
- After navigation
- After clicking buttons that load content
- After form submission
- After any DOM changes

---

### browser_console_messages

**Purpose**: Get console messages (logs, warnings, errors)

**Parameters**:
- `onlyErrors` (optional): boolean - Return only error messages

**Examples**:
```json
// Get all messages
{}

// Get only errors
{ "onlyErrors": true }
```

**Best Practices**:
- Check after every critical action
- Use `onlyErrors: true` for quick health checks
- Look for patterns in errors (same error repeating)
- Console errors often explain why something failed

**Common Error Types**:
- JavaScript errors → Code bugs
- Network errors → API failures
- CORS errors → Backend configuration
- 404 errors → Missing resources

---

### browser_network_requests

**Purpose**: Get all network requests since page load

**Parameters**: None

**Returns**:
- URL of each request
- Method (GET, POST, etc.)
- Status code
- Response time

**Example**:
```json
{}
```

**Best Practices**:
- Check after form submissions
- Verify API calls were made
- Look for 4xx/5xx status codes
- Identify slow requests

**Use Cases**:
- Debugging form submission failures
- Verifying API integration
- Performance testing
- Finding failed resource loads

---

## Interaction Tools

### browser_click

**Purpose**: Click an element on the page

**Parameters**:
- `element` (required): Human-readable description
- `ref` (required): Exact element reference from snapshot
- `button` (optional): "left" | "right" | "middle" (default: "left")
- `doubleClick` (optional): boolean (default: false)
- `modifiers` (optional): ["Alt", "Control", "Meta", "Shift"]

**Example**:
```json
{
  "element": "Submit button",
  "ref": "ref-42"
}
```

**Best Practices**:
- ALWAYS get `ref` from snapshot first
- Use descriptive `element` text
- Wait for element to be ready
- Verify click result with snapshot

**Common Issues**:
- Element not clickable → Wait or scroll
- Wrong ref → Element not found error
- Element covered → Another element in the way

---

### browser_type

**Purpose**: Type text into an input field

**Parameters**:
- `element` (required): Human-readable description
- `ref` (required): Exact element reference from snapshot
- `text` (required): Text to type
- `slowly` (optional): boolean - Type one character at a time
- `submit` (optional): boolean - Press Enter after typing

**Example**:
```json
{
  "element": "Email input field",
  "ref": "ref-15",
  "text": "user@example.com"
}
```

**Best Practices**:
- Use `browser_fill_form` for multiple fields instead
- Use `slowly: true` for fields with keypress handlers
- Use `submit: true` for single-field forms (search bars)
- Clear existing text first if needed

---

### browser_hover

**Purpose**: Hover mouse over an element

**Parameters**:
- `element` (required): Human-readable description
- `ref` (required): Exact element reference from snapshot

**Example**:
```json
{
  "element": "User profile menu",
  "ref": "ref-88"
}
```

**Use Cases**:
- Reveal dropdown menus
- Show tooltips
- Trigger hover effects
- Test CSS :hover states

---

### browser_drag

**Purpose**: Drag and drop between two elements

**Parameters**:
- `startElement` (required): Source element description
- `startRef` (required): Source element ref from snapshot
- `endElement` (required): Target element description
- `endRef` (required): Target element ref from snapshot

**Example**:
```json
{
  "startElement": "Draggable item",
  "startRef": "ref-10",
  "endElement": "Drop zone",
  "endRef": "ref-20"
}
```

**Use Cases**:
- Drag-and-drop interfaces
- Reordering lists
- File upload (drag files to upload zone)
- Kanban boards

---

## Form Tools

### browser_fill_form

**Purpose**: Fill multiple form fields atomically

**Parameters**:
- `fields` (required): Array of field objects
  - `name`: Field description
  - `ref`: Element ref from snapshot
  - `type`: "textbox" | "checkbox" | "radio" | "combobox" | "slider"
  - `value`: Value to set

**Example**:
```json
{
  "fields": [
    {
      "name": "Email field",
      "ref": "ref-10",
      "type": "textbox",
      "value": "user@example.com"
    },
    {
      "name": "Password field",
      "ref": "ref-11",
      "type": "textbox",
      "value": "SecurePass123"
    },
    {
      "name": "Remember me checkbox",
      "ref": "ref-12",
      "type": "checkbox",
      "value": "true"
    }
  ]
}
```

**Best Practices**:
- ✅ **PREFERRED over individual browser_type calls**
- Atomic operation (all or nothing)
- Single snapshot needed for all fields
- Faster execution
- Consistent state

**Field Types**:
- `textbox`: Text inputs, textareas
- `checkbox`: Checkboxes (value: "true"/"false")
- `radio`: Radio buttons (value: option text)
- `combobox`: Select dropdowns (value: option text)
- `slider`: Range inputs (value: number as string)

---

### browser_select_option

**Purpose**: Select option(s) from dropdown

**Parameters**:
- `element` (required): Dropdown description
- `ref` (required): Element ref from snapshot
- `values` (required): Array of values to select

**Example**:
```json
{
  "element": "Country selector",
  "ref": "ref-25",
  "values": ["United States"]
}
```

**Best Practices**:
- Use `browser_fill_form` instead when filling entire form
- For single select: array with one value
- For multi-select: array with multiple values
- Values must match option text exactly

---

### browser_file_upload

**Purpose**: Upload one or more files

**Parameters**:
- `paths` (optional): Array of absolute file paths

**Examples**:
```json
// Upload files
{
  "paths": ["/Users/username/file1.pdf", "/Users/username/file2.png"]
}

// Cancel file chooser
{
  "paths": []
}
```

**Best Practices**:
- Use absolute paths only
- Verify files exist before uploading
- Multiple files for multi-file inputs
- Empty array to cancel chooser

---

## Advanced Tools

### browser_evaluate

**Purpose**: Execute JavaScript in page context

**Parameters**:
- `function` (required): JavaScript function as string
  - `() => { /* code */ }` - No element
  - `(element) => { /* code */ }` - With element
- `element` (optional): Element description
- `ref` (optional): Element ref (if targeting specific element)

**Examples**:
```json
// Evaluate on page
{
  "function": "() => { return document.title; }"
}

// Evaluate on element
{
  "element": "Text container",
  "ref": "ref-30",
  "function": "(element) => { return element.textContent; }"
}
```

**Best Practices**:
- Use for reading computed values
- Access DOM APIs not available via other tools
- Return serializable data (no DOM nodes)
- Avoid mutations (use interaction tools instead)

**Common Use Cases**:
- Get computed styles
- Read custom data attributes
- Check element visibility
- Access window/document properties

---

### browser_handle_dialog

**Purpose**: Handle alert/confirm/prompt dialogs

**Parameters**:
- `accept` (required): boolean - Accept or dismiss
- `promptText` (optional): Text to enter (for prompt dialogs)

**Examples**:
```json
// Accept alert/confirm
{ "accept": true }

// Dismiss dialog
{ "accept": false }

// Answer prompt
{
  "accept": true,
  "promptText": "User response text"
}
```

**Best Practices**:
- Dialog must be open when called
- Dialogs block other operations
- Handle immediately when appeared
- Test both accept and dismiss paths

---

### browser_press_key

**Purpose**: Press keyboard key(s)

**Parameters**:
- `key` (required): Key name or character

**Examples**:
```json
// Press single key
{ "key": "Enter" }

// Type character
{ "key": "a" }

// Special keys
{ "key": "ArrowDown" }
{ "key": "Escape" }
```

**Common Keys**:
- Navigation: ArrowUp, ArrowDown, ArrowLeft, ArrowRight
- Actions: Enter, Escape, Tab, Backspace, Delete
- Modifiers: Shift, Control, Alt, Meta
- Function: F1-F12

---

### browser_wait_for

**Purpose**: Wait for condition to be true

**Parameters** (one of):
- `text`: Text to wait for to appear
- `textGone`: Text to wait for to disappear
- `time`: Seconds to wait

**Examples**:
```json
// Wait for text to appear
{ "text": "Success! Form submitted" }

// Wait for loading to finish
{ "textGone": "Loading..." }

// Wait fixed time
{ "time": 2 }
```

**Best Practices**:
- Prefer `text` over `time` (more reliable)
- Use for dynamic content loading
- Wait for success/error messages
- Avoid arbitrary timeouts when possible

---

### browser_take_screenshot

**Purpose**: Take screenshot of page or element

**Parameters**:
- `filename` (optional): Relative or absolute path
- `type` (optional): "png" | "jpeg" (default: "png")
- `fullPage` (optional): boolean - Capture full scrollable page
- `element` (optional): Element description (with ref)
- `ref` (optional): Element ref from snapshot

**Examples**:
```json
// Screenshot viewport
{
  "filename": "page.png"
}

// Full page screenshot
{
  "filename": "full-page.png",
  "fullPage": true
}

// Screenshot specific element
{
  "filename": "button.png",
  "element": "Submit button",
  "ref": "ref-42"
}
```

**Best Practices**:
- Use relative paths (stays in output dir)
- PNG for quality, JPEG for smaller size
- Element screenshots for focused testing
- Full page for documentation

**Use Cases**:
- Visual regression testing
- Documentation
- Bug reports
- Comparison testing

---

## Utility Tools

### browser_resize

**Purpose**: Resize browser window

**Parameters**:
- `width` (required): Width in pixels
- `height` (required): Height in pixels

**Example**:
```json
{
  "width": 375,
  "height": 667
}
```

**Common Viewports**:
- Mobile: 375x667 (iPhone), 360x640 (Android)
- Tablet: 768x1024 (iPad), 1024x768 (landscape)
- Desktop: 1920x1080, 1366x768, 1440x900

**Use Cases**:
- Mobile responsive testing
- Viewport-specific behavior
- Screenshot consistency

---

### browser_close

**Purpose**: Close the browser and free resources

**Parameters**: None

**Example**:
```json
{}
```

**Best Practices**:
- Always close when done
- Frees system resources
- Required before starting new browser
- Good practice in automation scripts

---

### browser_install

**Purpose**: Install browser if not present

**Parameters**: None

**Example**:
```json
{}
```

**When to Use**:
- First time setup
- After "browser not installed" error
- When upgrading browser version
- Rarely needed in normal workflow

---

## Tool Combinations

### Login Flow
```
1. browser_navigate → Login page
2. browser_snapshot → Get form refs
3. browser_fill_form → Enter credentials
4. browser_click → Submit button (ref from snapshot)
5. browser_wait_for → "Welcome" text
6. browser_snapshot → Verify logged in
```

### Form Testing
```
1. browser_navigate → Form page
2. browser_snapshot → Get field refs
3. browser_fill_form → Fill all fields
4. browser_click → Submit
5. browser_console_messages (onlyErrors: true) → Check for errors
6. browser_network_requests → Verify submission
7. browser_wait_for → Success message
```

### Debugging Flow
```
1. browser_snapshot → Current state
2. browser_console_messages → Check errors
3. browser_network_requests → Check API calls
4. browser_take_screenshot → Visual evidence
5. browser_evaluate → Inspect specific values
```

---

**Remember**: Always snapshot first, use exact refs, verify results!
