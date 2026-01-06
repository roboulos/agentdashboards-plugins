# XanoScript Operators

Operators available in XanoScript for conditionals, comparisons, and expressions.

## Table of Contents
- [Comparison Operators](#comparison-operators)
- [Logical Operators](#logical-operators)
- [Arithmetic Operators](#arithmetic-operators)
- [String Operators](#string-operators)

---

## Comparison Operators

Used in conditionals and filter expressions.

| Operator | Description | Example |
|----------|-------------|---------|
| `==` | Equals | `$status == "active"` |
| `!=` | Not equals | `$role != "admin"` |
| `>` | Greater than | `$age > 18` |
| `<` | Less than | `$price < 100` |
| `>=` | Greater than or equal | `$score >= 90` |
| `<=` | Less than or equal | `$count <= 10` |

### Examples

```json
{
  "operations": [
    {"method": "conditional", "args": ["$user.age >= 18"]},
    {"method": "conditional", "args": ["$price > 0 && $price < 100"]},
    {"method": "arrayFilter", "args": ["users", "$this.status == \"active\"", "active_users"]}
  ],
  "note": "arrayFilter uses $this as iterator variable"
}
```

---

## Logical Operators

Combine multiple conditions.

| Operator | Description | Example |
|----------|-------------|---------|
| `&&` | AND | `$age > 18 && $status == "active"` |
| `\|\|` | OR | `$role == "admin" \|\| $role == "editor"` |
| `!` | NOT | `!$disabled` |

### Examples

```json
{
  "operations": [
    {"method": "conditional", "args": ["$user.role == \"admin\" && $user.status == \"active\""]},
    {"method": "conditional", "args": ["$payment_method == \"card\" || $payment_method == \"paypal\""]},
    {"method": "conditional", "args": ["!$user.banned"]},
    {"method": "conditional", "args": ["($age >= 18 && $age < 65) || $has_senior_discount"]}
  ]
}
```

---

## Arithmetic Operators

Used in expressions and calculations. These create NEW values, not modify existing variables.

| Operator | Description | Example |
|----------|-------------|---------|
| `+` | Addition | `$price + $tax` |
| `-` | Subtraction | `$total - $discount` |
| `*` | Multiplication | `$price * $quantity` |
| `/` | Division | `$total / $count` |
| `%` | Modulus | `$number % 2` |

### Examples

```json
{
  "operations": [
    {"method": "var", "args": ["total", "$price * $quantity"]},
    {"method": "var", "args": ["final_price", "$total - ($total * 0.1)"]},
    {"method": "var", "args": ["average", "$sum / $count"]}
  ]
}
```

### ⚠️ Operators vs Math Methods

**Operators** (`+`, `-`, etc.) and **math methods** serve DIFFERENT purposes:

| Feature | Operators (`+`, `-`, `*`, `/`) | Math Methods (`mathAdd`, `mathSubtract`) |
|---------|-------------------------------|------------------------------------------|
| **Purpose** | Create new values in expressions | Modify variables IN PLACE |
| **Usage** | `var result { value = $a + $b }` | `math.add counter { value = 5 }` |
| **Effect** | Returns new value | Mutates existing variable |
| **When to use** | Calculations, expressions | Incrementing counters, accumulating totals |

**Example:**
```json
{
  "operations": [
    // ✅ Use operators for expressions
    {"method": "var", "args": ["total", "$price + $tax + $shipping"]},

    // ✅ Use math methods for in-place mutations
    {"method": "var", "args": ["counter", 0]},
    {"method": "mathAdd", "args": ["counter", 1]},
    {"method": "mathAdd", "args": ["counter", 1]},
    // counter is now 2
  ]
}
```

See [sdk-methods-core.md](sdk-methods-core.md) for complete math method documentation.

---

## String Operators

String concatenation and manipulation.

| Operator | Description | Example |
|----------|-------------|---------|
| `~` | Concatenation (deprecated) | `"Hello " ~ $name` |
| `+` | Concatenation (works but not recommended) | `"Hello " + $name` |

### Examples

```json
{
  "deprecated": {"method": "var", "args": ["full_name", "$first_name ~ \" \" ~ $last_name"]},
  "recommended": {"method": "var", "args": ["full_name", "$first_name|concat:\" \"|concat:$last_name"]},
  "note": "Use |concat: filter for string concatenation instead of operators"
}
```

**Best Practice:** Use `|concat:` filter for string concatenation instead of operators. See [xanoscript-filters.md](xanoscript-filters.md).

---

## Common Patterns

### Null Checking

```json
{
  "operations": [
    {"method": "conditional", "args": ["$value == null || $value == \"\""]},
    {"method": "conditional", "args": ["$value != null"]}
  ]
}
```

### Range Checking

```json
{
  "operations": [
    {"method": "conditional", "args": ["$age >= 18 && $age <= 65"]},
    {"method": "expectToBeWithin", "args": ["$age", 18, 65, "valid_age"]}
  ]
}
```

### Type Checking

```json
{
  "operations": [
    {"method": "conditional", "args": ["$flag == true"]},
    {"method": "conditional", "args": ["$flag == false"]},
    {"method": "conditional", "args": ["$count > 0"]},
    {"method": "conditional", "args": ["$status == \"active\""]}
  ]
}
```

---

**For data transformation, see:** [xanoscript-filters.md](xanoscript-filters.md)
**For SDK methods, see:** [sdk-methods-core.md](sdk-methods-core.md)
