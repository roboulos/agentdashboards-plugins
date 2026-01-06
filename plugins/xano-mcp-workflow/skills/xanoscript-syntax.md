# XanoScript Syntax Reference

## Variables

### Declaring Variables

```xanoscript
// Variables use $ prefix in stack block
var $my_var {
  value = "string value"
}

var $count {
  value = 0
}

var $is_active {
  value = true
}
```

### Referencing Variables

```xanoscript
// Reference with $
var $greeting {
  value = "Hello, "|concat:$name
}

// Input parameters
var $user_page {
  value = $input.page
}

// Nested access
var $first_item {
  value = $items.0
}

var $user_email {
  value = $api_result.response.result.user.email
}
```

### Updating Variables

```xanoscript
var.update $count {
  value = $count|add:1
}
```

---

## Control Flow

### Conditional (NOT if/endif)

```xanoscript
// CORRECT
conditional {
  if ($body == false) {
    throw {
      name = "API_TIMEOUT"
      value = "API call timed out"
    }
  }
}

// Also correct with else
conditional {
  if ($status >= 400) {
    throw {
      name = "API_ERROR"
      value = $body.error.message
    }
  }
  else {
    var $data {
      value = $body.result
    }
  }
}
```

### ForEach (camelCase!)

```xanoscript
// CORRECT - forEach / endForEach (not foreach)
foreach ($items) {
  each as $item {
    db.add my_table {
      data = {
        name: $item.name
        email: $item.email
      }
    } as $new_record

    var.update $count {
      value = $count|add:1
    }
  }
}
```

---

## API Requests

### Basic Pattern

```xanoscript
var $auth_header {
  value = "Authorization: Bearer "|concat:$env.API_KEY
}

var $my_headers {
  value = []|push:$auth_header
}

api.request {
  url = $url
  method = "POST"
  headers = $my_headers    // Pass variable, NOT inline array
  params = $request_body   // Use "params" NOT "body"
  timeout = 120
} as $api_result
```

### Accessing Response

```xanoscript
// Response structure
// $api_result.response.status = HTTP status code
// $api_result.response.result = Response body

var $status {
  value = $api_result.response.status
}

var $body {
  value = $api_result.response.result
}

// ALWAYS check for timeout before accessing nested fields
conditional {
  if ($body == false) {
    throw {
      name = "API_TIMEOUT"
      value = "API call timed out"
    }
  }
}

// Now safe to access
var $items {
  value = $body.items
}
```

---

## Database Operations

### Query

```xanoscript
db.query users {
  filters = {
    status: "active"
    created_at: {
      ">": $min_date
    }
  }
  sort = {
    created_at: "desc"
  }
  page = 1
  per_page = 100
} as $users
```

### Add Record

```xanoscript
db.add users {
  data = {
    name: $input.name
    email: $input.email
    created_at: now
  }
} as $new_user
```

### Edit Record

```xanoscript
db.edit users {
  id = $user_id
  data = {
    status: "updated"
    updated_at: now
  }
} as $updated_user
```

---

## Endpoint Structure

### Complete Endpoint Template

```xanoscript
query "my-endpoint" verb=POST {
  input {
    int page
    text search {
      nullable = true
    }
  }

  stack {
    var $per_page {
      value = 500
    }

    // ... your logic here ...
  }

  response = {
    success: true
    data: $result
    count: $items|count
  }
}
```

### Key Points

1. **Input block** - Define parameters
2. **Stack block** - All your logic (variables, db ops, api calls)
3. **Response block** - Use `response = {}` NOT `return {}`

---

## Common Filters

```xanoscript
// String operations
$str|concat:" suffix"
$str|to_upper
$str|to_lower
$str|trim

// Array operations
$arr|count
$arr|first
$arr|last
$arr|push:$new_item

// Object operations
$obj|set:"key":$value
$obj.nested.field

// Math
$num|add:5
$num|multiply:2

// Timestamp
now                          // Current timestamp
now|add_secs_to_timestamp:3600  // Add 1 hour
```

---

## Authentication

### Require Auth

```xanoscript
stack {
  auth.require   // User must be authenticated

  // After auth, use 'id' (not $id, not $authToken)
  var $user_id {
    value = id
  }
}
```

### Current Time

```xanoscript
// Use 'now' (not $now) - it's a special keyword like 'id'
var $created_at {
  value = now
}

db.add logs {
  data = {
    timestamp: now
    user_id: id
  }
}
```
