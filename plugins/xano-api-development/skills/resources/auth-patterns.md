# Authentication Patterns

Authentication and authorization strategies for Xano applications.

---

## Table of Contents

- [Xano Built-in Auth](#xano-built-in-auth)
- [Custom Auth Patterns](#custom-auth-patterns)
- [RBAC Implementation](#rbac-implementation)
- [Token Management](#token-management)
- [Security Best Practices](#security-best-practices)

---

## Xano Built-in Auth

### Using Xano's Auth System

Xano provides built-in authentication with JWT tokens.

**Database Tables (Auto-Created):**
```
xano_user
├── id
├── email
├── password (hashed automatically)
├── created_at
└── ... (customizable)
```

### Registration Endpoint

```javascript
// Endpoint: POST /auth/register
endpoint
  .input('email', 'email')
  .input('password', 'text')
  .input('name', 'text')

  // Validate password strength
  .precondition('$password.length >= 8', 'Password must be 8+ characters', 400)

  // Create user (Xano hashes password automatically)
  .authAddUser({
    email: '$email',
    password: '$password',
    name: '$name'
  })

  // Return user + token
  .respond({
    user: {
      id: '$user.id',
      email: '$user.email',
      name: '$user.name'
    },
    authToken: '$user.authToken'
  });
```

### Login Endpoint

```javascript
// Endpoint: POST /auth/login
endpoint
  .input('email', 'email')
  .input('password', 'text')

  // Attempt login (Xano validates password)
  .authLogin('$email', '$password')

  // Return user + token
  .respond({
    user: {
      id: '$authUser.id',
      email: '$authUser.email',
      name: '$authUser.name'
    },
    authToken: '$authToken'
  });
```

### Protected Endpoints

```javascript
// Endpoint: GET /me
endpoint
  // Require authentication
  .requireAuth()

  // Access authenticated user via $auth
  .respond({
    user: {
      id: '$auth.user.id',
      email: '$auth.user.email',
      name: '$auth.user.name'
    }
  });
```

### Logout Endpoint

```javascript
// Endpoint: POST /auth/logout
endpoint
  .requireAuth()
  .authLogout()
  .respond({message: 'Logged out successfully'});
```

---

## Custom Auth Patterns

### Email Verification

```
Table: email_verifications
├── id
├── user_id (FK → xano_user.id)
├── token (unique)
├── verified (boolean)
├── expires_at
└── created_at
```

**Send Verification:**
```javascript
// After registration
endpoint
  .authAddUser({email: '$email', password: '$password'})

  // Generate verification token
  .var('token', /* generate random token */)

  .create('email_verifications', {
    user_id: '$user.id',
    token: '$token',
    verified: false,
    expires_at: '$now + 86400'  // 24 hours
  })

  // Send email
  .call('send_verification_email', {
    email: '$email',
    token: '$token'
  })

  .respond({
    message: 'Check email for verification link',
    user_id: '$user.id'
  });
```

**Verify Email:**
```javascript
// Endpoint: GET /auth/verify/{token}
endpoint
  .input('token', 'text')

  // Find verification
  .queryOne('email_verifications', {
    token: '$token',
    verified: false,
    expires_at: {$gt: '$now'}
  })

  .precondition('$verification != null', 'Invalid or expired token', 400)

  // Mark user as verified
  .update('xano_user', '$verification.user_id', {
    email_verified: true
  })

  // Mark verification as used
  .update('email_verifications', '$verification.id', {
    verified: true
  })

  .respond({message: 'Email verified successfully'});
```

### Password Reset

```
Table: password_resets
├── id
├── user_id (FK → xano_user.id)
├── token (unique, indexed)
├── used (boolean)
├── expires_at (indexed)
└── created_at
```

**Request Reset:**
```javascript
// Endpoint: POST /auth/forgot-password
endpoint
  .input('email', 'email')

  // Find user
  .queryOne('xano_user', {email: '$email'})

  .conditional('$user != null')
    .then((e) => {
      // Generate reset token
      e.var('token', /* random token */)

      // Create reset record
      e.create('password_resets', {
        user_id: '$user.id',
        token: '$token',
        used: false,
        expires_at: '$now + 3600'  // 1 hour
      })

      // Send email
      e.call('send_password_reset_email', {
        email: '$email',
        token: '$token'
      })
    })
  .endConditional()

  // Always return success (don't leak user existence)
  .respond({message: 'If email exists, reset link sent'});
```

**Reset Password:**
```javascript
// Endpoint: POST /auth/reset-password
endpoint
  .input('token', 'text')
  .input('new_password', 'text')

  // Validate password
  .precondition('$new_password.length >= 8', 'Password too short', 400)

  // Find valid reset token
  .queryOne('password_resets', {
    token: '$token',
    used: false,
    expires_at: {$gt: '$now'}
  })

  .precondition('$reset != null', 'Invalid or expired token', 400)

  // Update password
  .authUpdatePassword('$reset.user_id', '$new_password')

  // Mark token as used
  .update('password_resets', '$reset.id', {used: true})

  .respond({message: 'Password updated successfully'});
```

---

## RBAC Implementation

### Role-Based Access Control

**Database Schema:**
```
roles
├── id
├── name (enum: admin, manager, user)
└── permissions (json)

xano_user (extended)
├── id
├── email
├── password
├── role_id (FK → roles.id)
└── ...
```

### Assign Roles

```javascript
// Endpoint: POST /users/{id}/role
endpoint
  .input('id', 'number')
  .input('role_id', 'number')

  .requireAuth()

  // Check if current user is admin
  .precondition('$auth.user.role.name == "admin"', 'Admin only', 403)

  // Update user role
  .update('xano_user', '$id', {role_id: '$role_id'})

  .respond({message: 'Role updated'});
```

### Check Permissions

```javascript
// Function: check_permission
function_endpoint
  .input('user_id', 'number')
  .input('permission', 'text')

  // Get user with role
  .queryOne('xano_user', {id: '$user_id'})
  .queryOne('roles', {id: '$user.role_id'})

  // Check if permission exists in role
  .var('has_permission', '$role.permissions.includes($permission)')

  .conditional('!$has_permission')
    .then((e) => {
      e.throw('FORBIDDEN', 'Insufficient permissions', 403)
    })
  .endConditional()

  .return({allowed: true});
```

**Usage:**
```javascript
// Endpoint: DELETE /products/{id}
endpoint
  .input('id', 'number')
  .requireAuth()

  // Check permission
  .call('check_permission', {
    user_id: '$auth.user.id',
    permission: 'products:delete'
  })

  // Proceed with delete
  .delete('products', '$id')
  .respond({message: 'Product deleted'});
```

### Multi-Tenant RBAC

**Schema:**
```
organizations
├── id
├── name
└── ...

organization_members
├── id
├── organization_id (FK)
├── user_id (FK)
├── role (enum: owner, admin, member)
└── ...

projects
├── id
├── organization_id (FK)
└── ...
```

**Check Org Access:**
```javascript
// Function: check_org_access
function_endpoint
  .input('user_id', 'number')
  .input('organization_id', 'number')
  .input('required_role', 'text')  // owner, admin, member

  // Get membership
  .queryOne('organization_members', {
    user_id: '$user_id',
    organization_id: '$organization_id'
  })

  .precondition('$membership != null', 'Not a member', 403)

  // Define role hierarchy
  .var('role_levels', {owner: 3, admin: 2, member: 1})
  .var('user_level', '$role_levels[$membership.role]')
  .var('required_level', '$role_levels[$required_role]')

  .precondition('$user_level >= $required_level', 'Insufficient role', 403)

  .return({allowed: true});
```

**Usage:**
```javascript
// Endpoint: PATCH /projects/{id}
endpoint
  .input('id', 'number')
  .requireAuth()

  // Get project
  .queryOne('projects', {id: '$id'})

  // Check org access (requires admin)
  .call('check_org_access', {
    user_id: '$auth.user.id',
    organization_id: '$project.organization_id',
    required_role: 'admin'
  })

  // Update project
  .update('projects', '$id', {name: '$name'})
  .respond({project: '$project'});
```

---

## Token Management

### Refresh Tokens

**Schema:**
```
refresh_tokens
├── id
├── user_id (FK → xano_user.id, indexed)
├── token (unique, indexed)
├── expires_at (indexed)
├── revoked (boolean, indexed)
└── created_at
```

**Generate Refresh Token:**
```javascript
// Endpoint: POST /auth/login
endpoint
  .input('email', 'email')
  .input('password', 'text')

  .authLogin('$email', '$password')

  // Create refresh token (30 days)
  .var('refresh_token', /* generate token */)
  .create('refresh_tokens', {
    user_id: '$authUser.id',
    token: '$refresh_token',
    expires_at: '$now + 2592000',  // 30 days
    revoked: false
  })

  .respond({
    user: '$authUser',
    authToken: '$authToken',         // Short-lived (1 hour)
    refreshToken: '$refresh_token'   // Long-lived (30 days)
  });
```

**Refresh Access Token:**
```javascript
// Endpoint: POST /auth/refresh
endpoint
  .input('refresh_token', 'text')

  // Validate refresh token
  .queryOne('refresh_tokens', {
    token: '$refresh_token',
    revoked: false,
    expires_at: {$gt: '$now'}
  })

  .precondition('$token != null', 'Invalid refresh token', 401)

  // Generate new access token
  .authLoginById('$token.user_id')

  .respond({
    authToken: '$authToken',
    refreshToken: '$refresh_token'  // Keep same refresh token
  });
```

### API Keys

**Schema:**
```
api_keys
├── id
├── user_id (FK → xano_user.id)
├── key (unique, indexed)
├── name (e.g., "Production API Key")
├── scopes (json array, e.g., ["read", "write"])
├── last_used (datetime)
├── expires_at (datetime)
├── revoked (boolean)
└── created_at
```

**Create API Key:**
```javascript
// Endpoint: POST /api-keys
endpoint
  .input('name', 'text')
  .input('scopes', 'array')

  .requireAuth()

  // Generate key
  .var('key', /* generate secure random key */)

  .create('api_keys', {
    user_id: '$auth.user.id',
    key: '$key',
    name: '$name',
    scopes: '$scopes',
    expires_at: '$now + 31536000',  // 1 year
    revoked: false
  })

  .respond({
    key: '$key',
    name: '$name',
    message: 'Save this key, it won\'t be shown again'
  });
```

**Validate API Key:**
```javascript
// Function: validate_api_key
function_endpoint
  .input('api_key', 'text')
  .input('required_scope', 'text')

  // Find key
  .queryOne('api_keys', {
    key: '$api_key',
    revoked: false,
    expires_at: {$gt: '$now'}
  })

  .precondition('$key != null', 'Invalid API key', 401)

  // Check scope
  .precondition('$key.scopes.includes($required_scope)', 'Insufficient scope', 403)

  // Update last used
  .update('api_keys', '$key.id', {last_used: '$now'})

  .return({user_id: '$key.user_id', key: '$key'});
```

---

## Security Best Practices

### Password Requirements

```javascript
// Function: validate_password_strength
function_endpoint
  .input('password', 'text')

  .var('min_length', 8)
  .var('has_uppercase', '$password.match(/[A-Z]/) != null')
  .var('has_lowercase', '$password.match(/[a-z]/) != null')
  .var('has_number', '$password.match(/[0-9]/) != null')
  .var('has_special', '$password.match(/[!@#$%^&*]/) != null')

  .precondition('$password.length >= $min_length', 'Password too short', 400)
  .precondition('$has_uppercase', 'Need uppercase letter', 400)
  .precondition('$has_lowercase', 'Need lowercase letter', 400)
  .precondition('$has_number', 'Need number', 400)

  .return({valid: true});
```

### Rate Limiting

**Schema:**
```
rate_limits
├── id
├── identifier (e.g., IP address or user_id)
├── endpoint (e.g., "/auth/login")
├── attempts (number)
├── window_start (datetime)
└── blocked_until (datetime, nullable)
```

**Check Rate Limit:**
```javascript
// Function: check_rate_limit
function_endpoint
  .input('identifier', 'text')  // IP or user ID
  .input('endpoint', 'text')
  .input('max_attempts', 'number', {default: 5})
  .input('window_seconds', 'number', {default: 300})  // 5 min

  // Get or create rate limit record
  .queryOne('rate_limits', {
    identifier: '$identifier',
    endpoint: '$endpoint'
  })

  .conditional('$record == null')
    .then((e) => {
      e.create('rate_limits', {
        identifier: '$identifier',
        endpoint: '$endpoint',
        attempts: 1,
        window_start: '$now'
      })
    })
  .else((e) => {
    // Check if window expired
    e.conditional('$now - $record.window_start > $window_seconds')
      .then((e) => {
        // Reset window
        e.update('rate_limits', '$record.id', {
          attempts: 1,
          window_start: '$now',
          blocked_until: null
        })
      })
    .else((e) => {
      // Increment attempts
      e.update('rate_limits', '$record.id', {
        attempts: '$record.attempts + 1'
      })

      // Check if exceeded
      e.conditional('$record.attempts + 1 > $max_attempts')
        .then((e) => {
          e.update('rate_limits', '$record.id', {
            blocked_until: '$now + $window_seconds'
          })
          e.throw('RATE_LIMIT', 'Too many attempts', 429)
        })
      .endConditional()
    })
    .endConditional()
  })
  .endConditional()

  .return({allowed: true});
```

**Usage:**
```javascript
// Endpoint: POST /auth/login
endpoint
  .input('email', 'email')
  .input('password', 'text')

  // Check rate limit before attempting login
  .call('check_rate_limit', {
    identifier: '$email',
    endpoint: '/auth/login',
    max_attempts: 5,
    window_seconds: 300
  })

  // Proceed with login
  .authLogin('$email', '$password')
  .respond({authToken: '$authToken'});
```

### Session Management

**Track Active Sessions:**
```
user_sessions
├── id
├── user_id (FK)
├── token_hash (indexed)
├── ip_address
├── user_agent
├── last_active
└── created_at
```

**Create Session on Login:**
```javascript
endpoint
  .authLogin('$email', '$password')

  // Create session record
  .create('user_sessions', {
    user_id: '$authUser.id',
    token_hash: /* hash of authToken */,
    ip_address: '$request.ip',
    user_agent: '$request.headers.user_agent',
    last_active: '$now'
  })

  .respond({authToken: '$authToken'});
```

**Revoke All Sessions:**
```javascript
// Endpoint: POST /auth/logout-all
endpoint
  .requireAuth()

  // Delete all sessions
  .delete('user_sessions', {user_id: '$auth.user.id'})

  // Invalidate all tokens (if using custom token system)
  .authLogoutAll('$auth.user.id')

  .respond({message: 'All sessions logged out'});
```

---

## Best Practices

### Do's:
✅ Use Xano's built-in auth when possible
✅ Hash passwords (Xano does automatically)
✅ Implement email verification
✅ Use refresh tokens for long-lived sessions
✅ Rate limit authentication endpoints
✅ Track failed login attempts
✅ Implement password reset flow
✅ Use RBAC for complex permissions
✅ Revoke tokens on logout
✅ Log authentication events

### Don'ts:
❌ Don't store passwords in plain text
❌ Don't return different errors for user enumeration
❌ Don't skip email verification
❌ Don't allow unlimited login attempts
❌ Don't expose internal user IDs unnecessarily
❌ Don't use predictable token formats
❌ Don't skip HTTPS in production
❌ Don't implement your own crypto (use Xano's)

---

**Back to:** [SKILL.md](SKILL.md)
