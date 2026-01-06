# Curl Testing Patterns

## The Golden Rule

**ALWAYS use single quotes around URLs and JSON data to avoid shell escaping issues.**

---

## Basic Templates

### GET Request

```bash
curl -s 'https://INSTANCE.xano.io/api:GROUP_ID/endpoint?param=value'
```

### POST Request (Most Common)

```bash
curl -s -X POST 'https://INSTANCE.xano.io/api:GROUP_ID/endpoint' \
  -H 'Content-Type: application/json' \
  -d '{"field": "value"}'
```

### POST with Multiple Fields

```bash
curl -s -X POST 'https://x2nu-xcjc-vhax.agentdashboards.xano.io/api:Lrekz_3S/my-endpoint' \
  -H 'Content-Type: application/json' \
  -d '{
    "page": 1,
    "per_page": 500,
    "user_id": 123
  }'
```

---

## Authenticated Requests

### With Bearer Token

```bash
curl -s -X POST 'https://INSTANCE.xano.io/api:GROUP_ID/protected-endpoint' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '{"data": "value"}'
```

### With Environment Variable Token

```bash
curl -s -X POST 'https://INSTANCE.xano.io/api:GROUP_ID/endpoint' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $XANO_META_TOKEN_V1" \
  -d '{"page": 1}'
```

**Note:** Use double quotes around the header when using env vars.

---

## Pretty Print Response

### Using Python

```bash
curl -s -X POST 'https://INSTANCE.xano.io/api:GROUP_ID/endpoint' \
  -H 'Content-Type: application/json' \
  -d '{"page": 1}' | python3 -m json.tool
```

### Using jq (if installed)

```bash
curl -s -X POST 'https://INSTANCE.xano.io/api:GROUP_ID/endpoint' \
  -H 'Content-Type: application/json' \
  -d '{"page": 1}' | jq
```

---

## Common Mistakes

### Wrong: Double quotes cause escaping issues

```bash
# FAILS - shell tries to interpret $, {, etc.
curl -s -X POST "https://..." -d "{"page": 1}"
```

### Wrong: Missing Content-Type

```bash
# FAILS - Xano rejects without Content-Type
curl -s -X POST 'https://...' -d '{"page": 1}'
```

### Wrong: Compact JSON with special chars

```bash
# MAY FAIL - shell escaping issues
curl -s -X POST 'url' -d '{"prompt":"Hello! How are you?"}'
```

### Right: Multi-line for complex JSON

```bash
# WORKS - Multi-line format avoids escaping issues
curl -s -X POST 'https://INSTANCE.xano.io/api:GROUP_ID/endpoint' \
  -H 'Content-Type: application/json' \
  -d '{
    "prompt": "Hello! How are you?",
    "model": "gpt-4"
  }'
```

---

## Inspecting V1 Tables (Migration Pattern)

Create a reusable endpoint to check source table structure:

```bash
# Call the inspect endpoint with table ID
curl -s -X POST 'https://x2nu-xcjc-vhax.agentdashboards.xano.io/api:Lrekz_3S/inspect-v1-table' \
  -H 'Content-Type: application/json' \
  -d '{"table_id": 109}'
```

This returns one record showing all field names - essential before building migration mappings.

---

## Debugging Tips

### Check if endpoint exists

```bash
# If you get 404, endpoint name might be wrong
curl -s 'https://INSTANCE.xano.io/api:GROUP_ID/wrong-name'
# Returns: {"code":"ERROR_CODE_NOT_FOUND"...}
```

### Check response headers

```bash
curl -s -i 'https://INSTANCE.xano.io/api:GROUP_ID/endpoint'
```

### Suppress curl progress

```bash
curl -s ...  # -s = silent (no progress bar)
```

### Show errors only

```bash
curl -s ... 2>/dev/null  # Suppress stderr
```
