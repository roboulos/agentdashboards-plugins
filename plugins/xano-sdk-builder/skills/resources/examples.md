# Xano SDK Builder Examples

Battle-tested production patterns for common Xano SDK use cases.

## Quick Examples

### Simple GET Endpoint

```json
{
  "operations": [
    {"method": "requiresAuth", "args": ["user"]},
    {"method": "dbGet", "args": ["user", {"id": "$auth.user.id"}, "user"]},
    {"method": "response", "args": [{"user": "$user"}]}
  ]
}
```

### POST with Validation

```json
{
  "operations": [
    {"method": "precondition", "args": ["$input.email != \"\"", "Email required", 400]},
    {"method": "precondition", "args": ["$input.password != \"\"", "Password required", 400]},
    {"method": "dbAdd", "args": ["user", {"email": "$input.email", "password": "$input.password"}, "user"]},
    {"method": "response", "args": [{"user": "$user"}]}
  ]
}
```

### External API Call

```json
{
  "operations": [
    {"method": "apiRequest", "args": [
      "https://api.stripe.com/v1/checkout/sessions",
      "POST",
      {
        "headers": {
          "Authorization": "Bearer $env.STRIPE_SECRET_KEY",
          "Content-Type": "application/x-www-form-urlencoded"
        },
        "params": {
          "mode": "payment",
          "success_url": "$input.success_url",
          "cancel_url": "$input.cancel_url"
        }
      },
      "result"
    ]},
    {"method": "var", "args": ["status", "$result.response.status"]},
    {"method": "var", "args": ["body", "$result.response.result"]},
    {"method": "conditional", "args": ["$status >= 400"]},
    {"method": "throw", "args": ["API_ERROR", "$body.error.message"]},
    {"method": "endConditional"},
    {"method": "response", "args": [{"session": "$body"}]}
  ]
}
```

### Database Query with Filters

```json
{
  "operations": [
    {"method": "dbQuery", "args": ["user", {
      "search": "status == \"active\" && role == \"admin\"",
      "sort": {"created_at": "desc"},
      "page": 1,
      "per_page": 20
    }, "users"]},
    {"method": "response", "args": [{"users": "$users"}]}
  ]
}
```

### Conditional Logic

```json
{
  "operations": [
    {"method": "dbGet", "args": ["user", {"id": "$input.user_id"}, "user"]},
    {"method": "conditional", "args": ["$user.role == \"admin\""]},
    {"method": "var", "args": ["access", "full"]},
    {"method": "else"},
    {"method": "var", "args": ["access", "limited"]},
    {"method": "endConditional"},
    {"method": "response", "args": [{"access": "$access", "user": "$user"}]}
  ]
}
```

## For Complete Method Documentation

See the SDK method reference files:
- [sdk-methods-core.md](sdk-methods-core.md)
- [sdk-methods-database.md](sdk-methods-database.md)
- [sdk-methods-control-flow.md](sdk-methods-control-flow.md)
- [sdk-methods-api.md](sdk-methods-api.md)
- [sdk-methods-security.md](sdk-methods-security.md)
- [xanoscript-filters.md](xanoscript-filters.md)
- [xanoscript-operators.md](xanoscript-operators.md)

See [SKILL.md](SKILL.md) for complete navigation guide.
