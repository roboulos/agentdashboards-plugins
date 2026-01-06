# SDK Security & Authentication Methods

JWT tokens, password handling, cryptography, permissions, rate limiting, and session management.

## Table of Contents
- [Token Management](#token-management)
- [Password Handling](#password-handling)
- [Cryptography](#cryptography)
- [Permissions & Rate Limiting](#permissions--rate-limiting)
- [JWT/JWE/JWS](#jwtjwejws)

---

## Token Management

**4 methods** for JWT and auth token creation/verification.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `createToken(payload,expiry,alias)` | payload:Record, expiry:number, alias:string | this | Create JWT token |
| `verifyToken(token)` | token:string | this | Verify JWT token (returns result, no alias) |
| `verifyAuthToken(token,alias)` | token:string, alias:string | this | Verify auth token |
| `createAuthToken(table,userId,options?)` | table:string, userId:string\|number, options?:AuthTokenOptions | this | Create auth session token |

**CRITICAL:** `.createAuthToken()` uses `table` parameter (not `dbtable`)

### Examples

```json
{
  "operations": [
    {"method": "createToken", "args": [{"user_id": "$user.id"}, 3600, "token"]},
    {"method": "verifyToken", "args": ["$input.token"]},
    {"method": "createAuthToken", "args": ["user", "$user.id", {}, "auth_token"]}
  ]
}
```

---

## Password Handling

**4 methods** for password verification and generation.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `verifyPassword(input,hash,alias)` | input:string, hash:string, alias:string | this | Verify password against hash |
| `checkPassword(textPassword,hashPassword,alias)` | textPassword:string, hashPassword:string, alias:string | this | Alias for `.verifyPassword()` |
| `createPassword(options?,alias?)` | options?:SecurityOptions, alias?:string | this | Generate secure password |
| `generatePass(length?,as?)` | length?:number, as?:string | this | Generate password string |

**CRITICAL:** Password hashing methods (`hashPassword()`, `passwordHash()`) are NOT SUPPORTED. Use the `|sha256` filter instead:

```json
{
  "operations": [
    {"method": "var", "args": ["hashed_password", "$input.password|sha256"]}
  ]
}
```

### Examples

```json
{
  "operations": [
    {"method": "verifyPassword", "args": ["$input.password", "$user.password", "valid"]},
    {"method": "createPassword", "args": [{"length": 16}, "new_password"]}
  ]
}
```

---

## Cryptography

**8 methods** for encryption, UUIDs, and key generation.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `createUuid(alias)` | alias:string | this | Create UUID (v4) |
| `generateUuid(version?,as?)` | version?:string, as?:string | this | Generate UUID (specific version) |
| `createSecretKey(bits?,format?,alias?)` | bits?:number, format?:string, alias?:string | this | Create secret key |
| `createRSAKey(bits?,format?,alias?)` | bits?:number, format?:string, alias?:string | this | Create RSA key pair |
| `createRsaKey(bits?,format?,alias?)` | bits?:number, format?:string, alias?:string | this | Alias for `.createRSAKey()` |
| `createCurveKey(curve?,format?,alias?)` | curve?:string, format?:string, alias?:string | this | Create elliptic curve key |
| `encrypt(data,algorithm,key,iv,alias?)` | data:string, algorithm:string, key:string, iv:string, alias?:string | this | Encrypt data |
| `decrypt(data,algorithm,key,iv,alias?)` | data:string, algorithm:string, key:string, iv:string, alias?:string | this | Decrypt data |

### Examples

```json
{
  "operations": [
    {"method": "createUuid", "args": ["request_id"]},
    {"method": "createSecretKey", "args": [256, "hex", "secret"]},
    {"method": "encrypt", "args": ["$sensitive_data", "aes-256-cbc", "$key", "$iv", "encrypted"]}
  ]
}
```

---

## Hashing & HMAC

**XanoScript provides filters for hashing and HMAC signatures.**

### Password Hashing

Use the `|sha256` filter for password hashing:

```json
{
  "operations": [
    {"method": "var", "args": ["hashed_password", "$input.password|sha256"]},
    {"method": "dbAdd", "args": ["users", {"email": "$input.email", "password": "$hashed_password"}, "user"]}
  ]
}
```

### HMAC Signatures (Webhook Validation)

Use the `|hmac_sha256:$secret` filter for HMAC-SHA256 signatures. This is essential for validating webhooks from services like Stripe, GitHub, Slack, etc.

```json
{
  "operations": [
    {"comment": "Validate webhook signature from external service"},
    {"method": "var", "args": ["expected_sig", "$input.raw_body|hmac_sha256:$env.WEBHOOK_SECRET"]},
    {"method": "precondition", "args": ["$expected_sig == $input.signature", "Invalid webhook signature", 401]}
  ]
}
```

### XanoScript Webhook Validation Pattern

```xanoscript
// Get the raw request body and signature header
input { $raw_body: text, $signature: text }

// Calculate expected signature using secret
var $expected {
  value = $input.raw_body|hmac_sha256:$env.WEBHOOK_SECRET
}

// Compare signatures (constant-time comparison recommended)
precondition {
  expression = $expected == $input.signature
  message = "Invalid webhook signature"
  code = 401
}

// If we get here, signature is valid - process the webhook
var $payload { value = $input.raw_body|from_json }
```

**Available hash filters:**
- `|sha256` - SHA-256 hash (use for password hashing)
- `|sha512` - SHA-512 hash
- `|md5` - MD5 hash (not recommended for security)
- `|hmac_sha256:$secret` - HMAC-SHA256 signature
- `|hmac_sha512:$secret` - HMAC-SHA512 signature

---

## Permissions & Rate Limiting

**6 methods** for permissions, rate limiting, and session validation.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `checkPermissions(permissions,options?)` | permissions:string\|string[]\|Record, options?:Record | this | Check user permissions |
| `rateLimiting(options?)` | options?:RateLimitOptions | this | Apply rate limiting |
| `rateLimit(options?)` | options?:RateLimitOptions | this | Alias for `.rateLimiting()` |
| `validateSession(options?)` | options?:Record | this | Validate user session |
| `refreshAuthToken(options?)` | options?:Record | this | Refresh auth token |
| `revokeAuthToken(options?)` | options?:Record | this | Revoke auth token |

### Examples

```json
{
  "operations": [
    {"method": "checkPermissions", "args": [["admin", "editor"], {}]},
    {"method": "rateLimiting", "args": [{"requests": 100, "window": 60}]},
    {"method": "validateSession", "args": [{}]}
  ]
}
```

---

## JWT/JWE/JWS

**6 methods** for JWE/JWS encoding/decoding and random number generation.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `jweEncode(payload,key,as?)` | payload:any, key:string, as?:string | this | JWE encode |
| `jweDecode(token,key,as?)` | token:string, key:string, as?:string | this | JWE decode |
| `jwsEncode(payload,key,as?)` | payload:any, key:string, as?:string | this | JWS encode |
| `jwsDecode(token,key,as?)` | token:string, key:string, as?:string | this | JWS decode |
| `randomNumber(min,max,alias)` | min:number, max:number, alias:string | this | Generate random number |
| `randomBytes(length,alias)` | length:number, alias:string | this | Generate random bytes |

### Examples

```json
{
  "operations": [
    {"method": "jweEncode", "args": [{"data": "$sensitive"}, "$env.JWE_KEY", "encrypted"]},
    {"method": "jwsEncode", "args": [{"data": "$payload"}, "$env.JWS_KEY", "signed"]},
    {"method": "randomNumber", "args": [1, 100, "random_num"]}
  ]
}
```

---

**Total Methods in this File: 26**

**Verification Status:**
- Last verified: 2025-01-13
- Methods removed: `hashPassword()`, `passwordHash()` (not supported)
- Parameter fixes: `verifyToken()` (1 param only), `rateLimiting()` (use `requests` not `max`)

For workflow guidance, see [workflow.md](workflow.md)
