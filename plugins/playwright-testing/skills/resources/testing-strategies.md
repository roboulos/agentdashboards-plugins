# Playwright Testing Strategies

Comprehensive testing workflows for different testing scenarios.

## End-to-End Testing

### Pattern: Complete User Journey

```
Test: User registration and login flow

Step 1: Navigate to registration
→ browser_navigate url="https://app.example.com/register"
→ browser_snapshot

Step 2: Fill registration form
→ browser_fill_form fields=[
    {name:"Email", ref:"ref-1", type:"textbox", value:"test@example.com"},
    {name:"Password", ref:"ref-2", type:"textbox", value:"SecurePass123"},
    {name:"Confirm", ref:"ref-3", type:"textbox", value:"SecurePass123"}
  ]

Step 3: Submit and verify
→ browser_click element="Sign Up" ref="ref-4"
→ browser_wait_for text="Registration successful"
→ browser_console_messages onlyErrors=true
→ browser_network_requests (verify API call)

Step 4: Navigate to login
→ browser_navigate url="https://app.example.com/login"

Step 5: Login with new account
→ browser_fill_form (email + password)
→ browser_click submit
→ browser_wait_for text="Welcome"
→ browser_snapshot (verify logged in)

Step 6: Verify session
→ browser_navigate to protected page
→ Verify no redirect to login
```

### Pattern: Multi-Step Workflow

```
Test: E-commerce checkout flow

1. Browse products
2. Add to cart
3. View cart
4. Proceed to checkout
5. Fill shipping info
6. Fill payment info
7. Review order
8. Submit order
9. Verify confirmation

At each step:
- Snapshot to verify state
- Check console for errors
- Monitor network requests
- Verify expected UI changes
```

## Visual Regression Testing

### Pattern: Screenshot Comparison

```
Test: Layout consistency across pages

Step 1: Define viewport
→ browser_resize width=1920 height=1080

Step 2: Capture baseline
→ browser_navigate url="https://app.example.com/page1"
→ browser_wait_for text="Page loaded"
→ browser_take_screenshot filename="baseline-page1.png" fullPage=true

Step 3: After changes, capture again
→ browser_navigate url="https://app.example.com/page1"
→ browser_wait_for text="Page loaded"
→ browser_take_screenshot filename="updated-page1.png" fullPage=true

Step 4: Manually compare
→ Review baseline vs updated screenshots
→ Verify intentional changes only
```

### Pattern: Component Screenshots

```
Test: Button styling consistency

For each button variant:
1. Navigate to component showcase
2. browser_snapshot to find button
3. browser_take_screenshot
     element="Primary button"
     ref="ref-x"
     filename="button-primary.png"
4. Repeat for all variants
5. Compare screenshots
```

## API Testing via Network Monitoring

### Pattern: Verify API Integration

```
Test: Form submission sends correct data

Step 1: Fill form
→ browser_fill_form with test data

Step 2: Submit and monitor
→ browser_click submit button
→ browser_wait_for textGone="Submitting..."
→ browser_network_requests

Step 3: Verify API call
→ Check requests for POST to /api/submit
→ Verify status code 200
→ Verify request made to correct endpoint

Step 4: Verify response handling
→ browser_console_messages (no errors)
→ browser_snapshot (success message shown)
```

### Pattern: Error Handling Test

```
Test: Network failure handling

Step 1: Trigger action that makes API call
Step 2: browser_network_requests
Step 3: Look for failed requests (4xx/5xx)
Step 4: Verify error displayed to user
Step 5: browser_console_messages (check error logging)
```

## Responsive Design Testing

### Pattern: Multi-Viewport Test

```
Test: Responsive navigation menu

Viewports to test:
- Mobile: 375x667
- Tablet: 768x1024
- Desktop: 1920x1080

For each viewport:
1. browser_resize width=X height=Y
2. browser_navigate to page
3. browser_snapshot
4. Verify expected layout:
   - Mobile: Hamburger menu visible
   - Tablet: Partial menu visible
   - Desktop: Full menu visible
5. Test interactions (menu toggle on mobile)
6. browser_take_screenshot filename="nav-{viewport}.png"
```

### Pattern: Orientation Testing

```
Test: Mobile landscape vs portrait

Portrait:
→ browser_resize width=375 height=667
→ Test and screenshot

Landscape:
→ browser_resize width=667 height=375
→ Test and screenshot
→ Verify layout adapts
```

## Performance Testing

### Pattern: Page Load Performance

```
Test: Homepage load time

Step 1: Clear cache (browser_close then restart)
Step 2: browser_navigate url="https://app.example.com"
Step 3: browser_wait_for text="Page loaded indicator"
Step 4: browser_network_requests

Step 5: Analyze:
→ Count total requests
→ Find slowest requests (>3s)
→ Calculate total load time
→ Identify bottlenecks

Step 6: Document findings
```

### Pattern: Interaction Response Time

```
Test: Search response time

Step 1: Navigate to search
Step 2: Note start time
Step 3: browser_type in search field
Step 4: browser_wait_for text="Results loaded"
Step 5: Note end time
Step 6: browser_network_requests
Step 7: Verify API response time acceptable
```

## Accessibility Testing

### Pattern: Keyboard Navigation Test

```
Test: Form completable via keyboard only

Step 1: browser_navigate to form
Step 2: browser_press_key key="Tab"
Step 3: browser_snapshot (verify first field focused)
Step 4: browser_type (without clicking)
Step 5: browser_press_key key="Tab"
Step 6: Repeat for all fields
Step 7: browser_press_key key="Enter" (submit)
Step 8: Verify submission successful
```

### Pattern: Screen Reader Compatibility

```
Test: Semantic HTML structure

Step 1: browser_snapshot
Step 2: Verify in snapshot:
   - Proper heading hierarchy (h1, h2, h3)
   - Form labels associated with inputs
   - Buttons have descriptive text
   - Images have alt attributes (check with evaluate)
   - Links have meaningful text

Step 3: browser_evaluate to check ARIA attributes
```

## Security Testing

### Pattern: XSS Prevention Test

```
Test: Input sanitization

Step 1: Fill form with XSS attempt
→ browser_type text="<script>alert('xss')</script>"

Step 2: Submit form
→ browser_click submit

Step 3: Verify safe handling
→ browser_console_messages (no script execution)
→ browser_snapshot (script shown as text, not executed)
```

### Pattern: Authentication Test

```
Test: Protected route access

Step 1: browser_navigate to protected page (not logged in)
Step 2: Verify redirect to login
Step 3: Login with valid credentials
Step 4: browser_navigate to protected page again
Step 5: Verify access granted (no redirect)
Step 6: Logout
Step 7: Attempt access again
Step 8: Verify redirect back to login
```

## Regression Testing

### Pattern: Automated Regression Suite

```
Test: Core functionality after updates

For each critical user flow:
1. Run E2E test
2. Capture screenshots at key points
3. Check console for new errors
4. Monitor network for API changes
5. Compare results with baseline
6. Flag any differences for review
```

### Pattern: Smoke Test

```
Quick health check after deployment:

1. Homepage loads → browser_navigate
2. Login works → Fill form + submit
3. Core feature accessible → Navigate + interact
4. No console errors → browser_console_messages
5. API calls succeed → browser_network_requests

If any fail: Block deployment
```

## Form Validation Testing

### Pattern: Client-Side Validation

```
Test: Email field validation

Invalid Email Test:
1. browser_type text="not-an-email"
2. browser_click submit
3. browser_snapshot (verify validation message)
4. Verify form not submitted (no network request)

Valid Email Test:
1. browser_type text="valid@example.com"
2. browser_click submit
3. Verify submission proceeds
```

### Pattern: Server-Side Validation

```
Test: Backend validation handling

Step 1: Submit data that passes client validation
        but fails server validation
Step 2: browser_network_requests
Step 3: Verify 400 status code
Step 4: browser_snapshot
Step 5: Verify error message displayed to user
```

## Cross-Browser Considerations

### Pattern: Browser-Specific Testing

```
Note: Playwright MCP uses configured browser

Test in different browsers by:
1. Configure Playwright MCP for browser X
2. Run test suite
3. Document any browser-specific issues
4. Reconfigure for browser Y
5. Run tests again
6. Compare results
```

### Common Browser Differences

```
Check for:
- CSS rendering differences (screenshots)
- JavaScript API availability (console errors)
- Form behavior (autofill, validation)
- Date/time picker UI
- File upload dialogs
```

## Test Data Management

### Pattern: Test Data Setup

```
Before tests:
1. Navigate to admin/setup page
2. Create test account
3. Create test data (products, posts, etc)
4. Verify data created (snapshot/API check)

Run tests:
(Use test data)

After tests:
1. Navigate to cleanup page
2. Delete test data
3. Verify cleanup successful
```

### Pattern: Test Isolation

```
Each test should:
1. Start from known state
2. browser_navigate to start page
3. Perform test actions
4. Verify expected outcome
5. Clean up (browser_close if needed)

Don't depend on previous test state
```

## Continuous Testing Patterns

### Pattern: Scheduled Monitoring

```
Run periodically (hourly/daily):

1. browser_navigate to homepage
2. Verify page loads (no 500 errors)
3. Check console for JavaScript errors
4. Test critical user flow
5. Monitor API response times
6. Alert if failures detected
```

### Pattern: Pre-Deployment Verification

```
Before deploying changes:

1. Run full regression suite
2. Capture screenshots of key pages
3. Compare with production baseline
4. Verify no new console errors
5. Check API compatibility
6. Document any intentional changes
7. Get approval before deploying
```

## Test Documentation Template

```markdown
## Test: [Test Name]

**Purpose**: [What this test verifies]

**Preconditions**:
- [ ] Test data exists
- [ ] User not logged in / logged in
- [ ] Browser closed / fresh session

**Steps**:
1. [Action]
   - Expected: [Result]
   - Tool: browser_navigate
2. [Action]
   - Expected: [Result]
   - Tool: browser_snapshot

**Verification**:
- [ ] Console has no errors
- [ ] Network requests successful
- [ ] Expected UI state visible
- [ ] Screenshot matches baseline

**Cleanup**:
- [ ] Close browser
- [ ] Delete test data

**Pass Criteria**:
All verification steps pass

**Failure Handling**:
If fails, check:
1. Console errors
2. Network failures
3. Unexpected redirects
```

---

**Remember**: Good tests are repeatable, isolated, and well-documented!
