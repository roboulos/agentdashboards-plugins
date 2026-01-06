# XanoScript Filters - Complete Reference

Pipeline filters for data transformation using the pipe (`|`) operator.

**Source**: Validated from `src/sdk-lib/core/valid-filters-registry.js` - All 200+ supported Xano filters.

## Table of Contents
- [String Filters](#string-filters)
- [Array Filters](#array-filters)
- [Number Filters](#number-filters)
- [Timestamp Filters](#timestamp-filters)
- [Object Filters](#object-filters)
- [Type Conversion Filters](#type-conversion-filters)
- [Validation Filters](#validation-filters)
- [Comparison Filters](#comparison-filters)
- [Encoding Filters](#encoding-filters)
- [Hash & Crypto Filters](#hash--crypto-filters)
- [Transform Filters](#transform-filters)
- [Base Conversion Filters](#base-conversion-filters)
- [Pipe Filters](#pipe-filters)
- [Filter Aliases](#filter-aliases)
- [Common Mistakes](#common-mistakes)

---

## String Filters

Filters for string manipulation and formatting.

| Filter | Description | Example |
|--------|-------------|---------|
| `to_lower` | Convert to lowercase | `$email\|to_lower` |
| `to_upper` | Convert to uppercase | `$name\|to_upper` |
| `capitalize` | Capitalize first letter | `$text\|capitalize` |
| `to_ascii` | Convert to ASCII | `$text\|to_ascii` |
| `escape_html` | Escape HTML characters | `$html\|escape_html` |
| `unescape_html` | Unescape HTML | `$escaped\|unescape_html` |
| `word_count` | Count words | `$text\|word_count` |
| `explode` | Split string into array | `$csv\|explode:","` |
| `implode` | Join array to string | `$array\|implode:", "` |
| `regex_replace` | Replace with regex | `$text\|regex_replace:"/[0-9]/":"X"` |
| `regex_extract` | Extract with regex | `$text\|regex_extract:"/[A-Z]+/"` |
| `regex_extract_all` | Extract all matches | `$text\|regex_extract_all:"/[0-9]/"` |
| `url_parse` | Parse URL | `$url\|url_parse` |
| `url_addarg` | Add URL parameter | `$url\|url_addarg:"key":"value"` |
| `url_delarg` | Delete URL parameter | `$url\|url_delarg:"key"` |
| `url_setarg` | Set URL parameter | `$url\|url_setarg:"key":"value"` |
| `escape` | Escape special chars | `$text\|escape` |
| `addslashes` | Add slashes | `$text\|addslashes` |
| `nl2br` | Newlines to `<br>` | `$text\|nl2br` |
| `snake_case` | Convert to snake_case | `$text\|snake_case` |
| `camel_case` | Convert to camelCase | `$text\|camel_case` |
| `pascal_case` | Convert to PascalCase | `$text\|pascal_case` |
| `kebab_case` | Convert to kebab-case | `$text\|kebab_case` |
| `trim` | Trim whitespace | `$input\|trim` |
| `ltrim` | Trim left | `$text\|ltrim` |
| `rtrim` | Trim right | `$text\|rtrim` |
| `strlen` | Get string length | `$text\|strlen` |
| `substr` | Extract substring | `$text\|substr:0:10` |
| `replace` | Replace text | `$text\|replace:"old":"new"` |
| `contains` | Check if contains | `$text\|contains:"search"` |
| `starts_with` | Check if starts with | `$text\|starts_with:"prefix"` |
| `ends_with` | Check if ends with | `$text\|ends_with:"suffix"` |
| `pad_left` | Pad left | `$num\|pad_left:5:"0"` |
| `pad_right` | Pad right | `$num\|pad_right:5:"0"` |

---

## Array Filters

Filters for working with arrays and collections.

| Filter | Description | Example |
|--------|-------------|---------|
| `count` | Get array length | `$items\|count` |
| `join` | Join array to string | `$tags\|join:", "` |
| `push` | Add item to end | `$array\|push:$item` |
| `pop` | Remove last item | `$array\|pop` |
| `shift` | Remove first item | `$array\|shift` |
| `unshift` | Add item to start | `$array\|unshift:$item` |
| `first` | Get first element | `$items\|first` |
| `last` | Get last element | `$items\|last` |
| `at` | Get element at index | `$array\|at:2` |
| `slice` | Extract portion | `$array\|slice:0:5` |
| `index_of` | Find index | `$array\|index_of:$value` |
| `map` | Transform each item | `$users\|map:'$item.name'` |
| `filter` | Filter by condition | `$items\|filter:'$item.status == "active"'` |
| `reduce` | Reduce to value | `$numbers\|reduce:'$acc + $item':0` |
| `sort` | Sort array | `$numbers\|sort` |
| `sort_by` | Sort by field | `$users\|sort_by:"created_at"` |
| `reverse` | Reverse array | `$items\|reverse` |
| `unique` | Remove duplicates | `$array\|unique` |
| `flatten` | Flatten nested arrays | `$nested\|flatten` |
| `append` | Append array | `$array1\|append:$array2` |
| `diff` | Array difference | `$array1\|diff:$array2` |
| `diff_assoc` | Diff with keys | `$array1\|diff_assoc:$array2` |
| `entries` | Get key-value pairs | `$object\|entries` |
| `every` | Check if all match | `$items\|every:'$item > 0'` |
| `find` | Find first match | `$items\|find:'$item.id == 5'` |
| `findIndex` | Find index of match | `$items\|findIndex:'$item.id == 5'` |
| `filter_empty` | Remove empty values | `$array\|filter_empty` |
| `merge_recursive` | Merge recursively | `$obj1\|merge_recursive:$obj2` |
| `shuffle` | Random shuffle | `$array\|shuffle` |
| `index_by` | Index by field | `$users\|index_by:"id"` |
| `intersect` | Array intersection | `$array1\|intersect:$array2` |
| `intersect_assoc` | Intersect with keys | `$array1\|intersect_assoc:$array2` |
| `pick` | Pick fields | `$object\|pick:["id", "name"]` |
| `unpick` | Exclude fields | `$object\|unpick:["password"]` |
| `range` | Create range | `range:1:10` |
| `remove` | Remove by value | `$array\|remove:$value` |
| `safe_array` | Ensure array | `$value\|safe_array` |
| `prepend` | Prepend value | `$array\|prepend:$item` |

---

## Number Filters

Filters for numeric operations.

| Filter | Description | Example |
|--------|-------------|---------|
| `round` | Round number | `$price\|round:2` |
| `floor` | Round down | `$value\|floor` |
| `ceil` | Round up | `$value\|ceil` |
| `abs` | Absolute value | `$num\|abs` |
| `number_format` | Format number | `$price\|number_format:2:".":","`  |
| `min` | Get minimum | `$array\|min` |
| `max` | Get maximum | `$array\|max` |
| `add` | Add numbers | `$num\|add:5` |
| `subtract` | Subtract numbers | `$num\|subtract:3` |
| `multiply` | Multiply numbers | `$num\|multiply:2` |
| `divide` | Divide numbers | `$num\|divide:4` |
| `bitwise_and` | Bitwise AND | `$num\|bitwise_and:15` |
| `bitwise_or` | Bitwise OR | `$num\|bitwise_or:8` |
| `bitwise_xor` | Bitwise XOR | `$num\|bitwise_xor:7` |
| `bitwise_not` | Bitwise NOT | `$num\|bitwise_not` |

---

## Timestamp Filters

Filters for date and timestamp operations.

| Filter | Description | Example |
|--------|-------------|---------|
| `transform_timestamp` | Format timestamp | `$created_at\|transform_timestamp:"Y-m-d H:i:s"` |
| `format_timestamp` | Format timestamp | `$date\|format_timestamp:"Y-m-d"` |
| `parse_timestamp` | Parse to timestamp | `$date_string\|parse_timestamp` |
| `add_secs_to_timestamp` | Add seconds | `now\|add_secs_to_timestamp:3600` |
| `add_ms_to_timestamp` | Add milliseconds | `now\|add_ms_to_timestamp:1000` |
| `to_days` | Convert to days | `$seconds\|to_days` |
| `to_hours` | Convert to hours | `$seconds\|to_hours` |
| `to_minutes` | Convert to minutes | `$seconds\|to_minutes` |
| `to_seconds` | Convert to seconds | `$ms\|to_seconds` |
| `to_ms` | Convert to milliseconds | `$seconds\|to_ms` |
| `to_timestamp` | Convert to timestamp | `$date\|to_timestamp` |

**Date Format Codes:**
- `Y` - Year (4 digits)
- `m` - Month (01-12)
- `d` - Day (01-31)
- `H` - Hour (00-23)
- `i` - Minutes (00-59)
- `s` - Seconds (00-59)

---

## Object Filters

Filters for object/dictionary manipulation.

| Filter | Description | Example |
|--------|-------------|---------|
| `keys` | Get object keys | `$object\|keys` |
| `values` | Get object values | `$object\|values` |
| `merge` | Merge objects | `$obj1\|merge:$obj2` |
| `json_encode` | Convert to JSON | `$object\|json_encode` |
| `json_decode` | Parse JSON | `$json_string\|json_decode` |
| `get` | Get nested value | `$object\|get:"user.name"` |
| `has` | Check if key exists | `$object\|has:"email"` |

---

## Type Conversion Filters

Filters for type conversion.

| Filter | Description | Example |
|--------|-------------|---------|
| `to_text` | Convert to string | `$number\|to_text` |
| `to_int` | Convert to integer | `$value\|to_int` |
| `to_decimal` | Convert to decimal | `$value\|to_decimal` |
| `to_bool` | Convert to boolean | `$value\|to_bool` |

---

## Validation Filters

Filters for validation checks.

| Filter | Description | Example |
|--------|-------------|---------|
| `is_email` | Check if valid email | `$input\|is_email` |
| `is_url` | Check if valid URL | `$input\|is_url` |
| `is_numeric` | Check if numeric | `$value\|is_numeric` |
| `is_empty` | Check if empty | `$value\|is_empty` |
| `is_array` | Check if array | `$value\|is_array` |
| `is_bool` | Check if boolean | `$value\|is_bool` |
| `is_decimal` | Check if decimal | `$value\|is_decimal` |
| `is_int` | Check if integer | `$value\|is_int` |
| `is_null` | Check if null | `$value\|is_null` |
| `is_object` | Check if object | `$value\|is_object` |
| `is_text` | Check if text | `$value\|is_text` |

---

## Comparison Filters

Filters for comparison operations.

| Filter | Description | Example |
|--------|-------------|---------|
| `equals` | Check equality | `$value\|equals:5` |
| `not_equals` | Check inequality | `$value\|not_equals:0` |
| `greater_than` | Check if greater | `$value\|greater_than:10` |
| `less_than` | Check if less | `$value\|less_than:100` |
| `greater_or_equal` | Check if >= | `$value\|greater_or_equal:5` |
| `less_or_equal` | Check if <= | `$value\|less_or_equal:50` |
| `between` | Check if between | `$value\|between:1:10` |
| `in` | Check if in array | `$value\|in:$array` |
| `not_in` | Check if not in | `$value\|not_in:$array` |
| `even` | Check if even | `$number\|even` |
| `odd` | Check if odd | `$number\|odd` |
| `not` | Logical NOT | `$bool\|not` |

---

## Encoding Filters

Filters for encoding and decoding.

| Filter | Description | Example |
|--------|-------------|---------|
| `base64_encode` | Encode Base64 | `$text\|base64_encode` |
| `base64_decode` | Decode Base64 | `$encoded\|base64_decode` |
| `url_encode` | URL encode | `$text\|url_encode` |
| `url_decode` | URL decode | `$encoded\|url_decode` |
| `base64_encode_urlsafe` | Base64 URL-safe | `$text\|base64_encode_urlsafe` |
| `base64_decode_urlsafe` | Decode URL-safe | `$encoded\|base64_decode_urlsafe` |
| `url_encode_rfc3986` | RFC3986 encode | `$text\|url_encode_rfc3986` |
| `url_decode_rfc3986` | RFC3986 decode | `$encoded\|url_decode_rfc3986` |

---

## Hash & Crypto Filters

Filters for hashing and cryptography.

| Filter | Description | Example |
|--------|-------------|---------|
| `md5` | MD5 hash | `$text\|md5` |
| `sha1` | SHA1 hash | `$text\|sha1` |
| `sha256` | SHA256 hash | `$text\|sha256` |
| `sha512` | SHA512 hash | `$text\|sha512` |
| `uuid` | Generate UUID | `uuid` |
| `uuid4` | Generate UUID v4 | `uuid4` |
| `random` | Random string | `random:16` |
| `create_uid` | Create unique ID | `create_uid` |
| `encrypt` | Encrypt data | `$data\|encrypt:$key` |
| `decrypt` | Decrypt data | `$encrypted\|decrypt:$key` |
| `hmac_sha1` | HMAC SHA1 | `$data\|hmac_sha1:$secret` |
| `hmac_sha256` | HMAC SHA256 | `$data\|hmac_sha256:$secret` |
| `hmac_sha384` | HMAC SHA384 | `$data\|hmac_sha384:$secret` |
| `hmac_sha512` | HMAC SHA512 | `$data\|hmac_sha512:$secret` |

---

## Transform Filters

Filters for data transformation.

| Filter | Description | Example |
|--------|-------------|---------|
| `csv_create` | Create CSV | `$array\|csv_create` |
| `csv_decode` | Parse CSV | `$csv_string\|csv_decode` |
| `csv_parse` | Parse CSV | `$csv_string\|csv_parse` |
| `yaml_encode` | Encode YAML | `$data\|yaml_encode` |
| `yaml_decode` | Parse YAML | `$yaml\|yaml_decode` |
| `xml_decode` | Parse XML | `$xml\|xml_decode` |
| `lambda` | Create lambda | `lambda:'$x * 2'` |
| `to_expr` | Convert to expression | `$value\|to_expr` |

---

## Base Conversion Filters

Filters for number base conversion.

| Filter | Description | Example |
|--------|-------------|---------|
| `bindec` | Binary to decimal | `$binary\|bindec` |
| `decbin` | Decimal to binary | `$num\|decbin` |
| `dechex` | Decimal to hex | `$num\|dechex` |
| `decoct` | Decimal to octal | `$num\|decoct` |
| `hexdec` | Hex to decimal | `$hex\|hexdec` |
| `octdec` | Octal to decimal | `$oct\|octdec` |
| `bin2hex` | Binary to hex | `$binary\|bin2hex` |
| `hex2bin` | Hex to binary | `$hex\|hex2bin` |
| `base_convert` | Convert base | `$num\|base_convert:10:16` |

---

## Pipe Filters

Filters for object/array manipulation with pipe syntax.

| Filter | Description | Example |
|--------|-------------|---------|
| `set` | Set property | `$obj\|set:"key":$value` |
| `set_conditional` | Set if condition | `$obj\|set_conditional:"key":$value:$condition` |
| `set_ifnotempty` | Set if not empty | `$obj\|set_ifnotempty:"key":$value` |
| `set_ifnotnull` | Set if not null | `$obj\|set_ifnotnull:"key":$value` |
| `unset` | Remove property | `$obj\|unset:"key"` |
| `concat` | Concatenate | `$str1\|concat:$str2` |
| `first_notempty` | First non-empty | `first_notempty:$val1:$val2:$val3` |
| `first_notnull` | First non-null | `first_notnull:$val1:$val2:$val3` |

---

## Filter Aliases

Common aliases that map to actual filter names:

| Alias | Actual Filter |
|-------|---------------|
| `lower`, `lowercase` | `to_lower` |
| `upper`, `uppercase` | `to_upper` |
| `trimStart` | `ltrim` |
| `trimEnd` | `rtrim` |
| `len`, `length` | `strlen` |
| `substring` | `substr` |
| `startsWith` | `starts_with` |
| `endsWith` | `ends_with` |
| `padStart` | `pad_left` |
| `padEnd` | `pad_right` |
| `size` | `count` |
| `includes` | `contains` |
| `indexOf` | `index_of` |
| `sortBy` | `sort_by` |
| `format` | `number_format` |
| `sub` | `subtract` |
| `mul` | `multiply` |
| `toString`, `toText` | `to_text` |
| `toInt` | `to_int` |
| `toDecimal` | `to_decimal` |
| `toBool` | `to_bool` |

---

## Common Mistakes

Filters that **don't exist** in XanoScript (use alternatives):

| Invalid Filter | Use Instead |
|----------------|-------------|
| `uppercase_string` | `to_upper` |
| `lowercase_string` | `to_lower` |
| `hash_password` | Automatic on password fields |
| `title_case` | Not available |
| `date_format` | `format_timestamp` |
| `from_json` | `json_decode` |
| `to_json` | `json_encode` |
| `coalesce` | Use conditionals or `first_notnull` |
| `default` | Use conditionals |
| `toNumber` | `to_int` or `to_decimal` |
| `truncate` | `substr` |
| `strip_tags` | Not available |
| `currency` | `number_format` with concat |
| `each` | `map` |
| `where` | `filter` |
| `pluck` | `map` with property access |
| `compact` | `filter_empty` |
| `uniq` | `unique` |

---

## Chaining Filters

Combine multiple filters using the pipe operator:

```json
{
  "operations": [
    {"method": "var", "args": ["email", "$input.email|trim|to_lower"]},
    {"method": "var", "args": ["active_names", "$users|filter:'$item.status == \"active\"'|map:'$item.name'|join:\", \""]},
    {"method": "var", "args": ["total", "$items|map:'$item.price'|reduce:'$acc + $item':0|round:2"]},
    {"method": "var", "args": ["formatted_date", "now|add_secs_to_timestamp:86400|transform_timestamp:\"Y-m-d H:i:s\""]}
  ]
}
```

---

## Critical Patterns

### Time Operations
```json
{"method": "var", "args": ["created", "now"]},
{"method": "var", "args": ["expires", "now|add_secs_to_timestamp:2592000"]},
{"method": "var", "args": ["formatted", "now|transform_timestamp:\"Y-m-d H:i:s\""]}
```

### Array Manipulation
```json
{"method": "var", "args": ["active", "$users|filter:'$item.status == \"active\"'"]},
{"method": "var", "args": ["names", "$users|map:'$item.name'|join:\", \""]},
{"method": "var", "args": ["total", "$items|map:'$item.price'|reduce:'$acc + $item':0"]}
```

### Object Building
```json
{"method": "var", "args": ["data", "{}|set:\"name\":$name|set:\"email\":$email|set:\"created\":now"]}
```

---

**For SDK methods, see:** [sdk-methods-core.md](sdk-methods-core.md)
**For operators, see:** [xanoscript-operators.md](xanoscript-operators.md)
