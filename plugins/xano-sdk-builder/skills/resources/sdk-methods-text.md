# SDK Text & String Methods

String operations, manipulation, checking, and transformation methods.

## Table of Contents
- [Text Filters vs Methods](#text-filters-vs-methods)
- [String Checking](#string-checking)
- [String Manipulation](#string-manipulation)

---

## Text Filters vs Methods

**IMPORTANT:** Most text operations in XanoScript use **FILTERS**, not methods.

### ✅ Real Text Methods (4 methods total)

These are the ONLY text methods that exist as SDK methods:

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `textTrim(textVar)` | textVar:string | this | Trim whitespace |
| `textContains(textVar,searchValue,alias)` | textVar:string, searchValue:string, alias:string | this | Check contains (case-sensitive) |
| `textStartsWith(textVar,searchValue,alias)` | textVar:string, searchValue:string, alias:string | this | Check starts with |
| `textEndsWith(textVar,searchValue,alias)` | textVar:string, searchValue:string, alias:string | this | Check ends with |

### ✅ Use Filters For Everything Else

All other text operations should use XanoScript filter syntax:

| Operation | Filter Syntax | Example |
|-----------|---------------|---------|
| **Concatenate** | `$text\|add:"more"` | `{"method": "var", "args": ["full", "$first\|add:\" \"\|add:$last"]}` |
| **Split** | `$text\|split:","` | `{"method": "var", "args": ["array", "$csv\|split:\",\""]}` |
| **Replace** | `$text\|replace:"old":"new"` | `{"method": "var", "args": ["fixed", "$text\|replace:\"bug\":\"feature\""]}` |
| **Uppercase** | `$text\|to_upper` | `{"method": "var", "args": ["upper", "$name\|to_upper"]}` |
| **Lowercase** | `$text\|to_lower` | `{"method": "var", "args": ["lower", "$name\|to_lower"]}` |
| **Length** | `$text\|strlen` | `{"method": "var", "args": ["len", "$input.text\|strlen"]}` |
| **Substring** | `$text\|substr:0:10` | `{"method": "var", "args": ["short", "$text\|substr:0:100"]}` |

### Examples

**✅ Using Real Methods:**
```json
{
  "operations": [
    {"method": "textTrim", "args": ["input_text"]},
    {"method": "textContains", "args": ["email", "@gmail.com", "is_gmail"]},
    {"method": "textStartsWith", "args": ["url", "https://", "is_secure"]},
    {"method": "textEndsWith", "args": ["filename", ".pdf", "is_pdf"]}
  ]
}
```

**Generated XanoScript:**
```xanoscript
text.trim input_text
text.contains (input_text) search="@gmail.com" as is_gmail
text.starts_with (url) search="https://" as is_secure
text.ends_with (filename) search=".pdf" as is_pdf
```

**✅ Using Filters (For Other Operations):**
```json
{
  "operations": [
    {"method": "var", "args": ["full_name", "$input.first\|add:\" \"\|add:$input.last"]},
    {"method": "var", "args": ["upper_name", "$input.name\|to_upper"]},
    {"method": "var", "args": ["new_email", "$input.email\|replace:\"@old.com\":\"@new.com\""]},
    {"method": "var", "args": ["tags", "$input.tags\|split:\",\""]},
    {"method": "var", "args": ["preview", "$input.text\|substr:0:100"]},
    {"method": "var", "args": ["length", "$input.text\|strlen"]}
  ]
}
```

**Generated XanoScript:**
```xanoscript
var full_name {
  value = $input.first|add:" "|add:$input.last
}
var upper_name {
  value = $input.name|to_upper
}
var new_email {
  value = $input.email|replace:"@old.com":"@new.com"
}
var tags {
  value = $input.tags|split:","
}
var preview {
  value = $input.text|substr:0:100
}
var length {
  value = $input.text|strlen
}
```

### Use Cases

**Text Methods (Use when you need to):**
- Remove whitespace from user input
- Check if string contains specific text
- Validate string prefixes/suffixes
- Simple boolean checks

**Text Filters (Use for most operations):**
- String concatenation and building
- Text transformation (uppercase, lowercase)
- String replacement and formatting
- Splitting strings into arrays
- Extracting substrings
- Getting string length

---

## String Checking

**Additional checking methods** (case-insensitive variants):

| Method | Status | Params | Returns | Purpose |
|--------|--------|--------|---------|---------|
| `textIContains(textVar,searchValue,alias)` | ✅ REAL | textVar:string, searchValue:string, alias:string | this | Check contains (case-insensitive) |
| `textIStartsWith(textVar,searchValue,alias)` | ✅ REAL | textVar:string, searchValue:string, alias:string | this | Check starts with (case-insensitive) |
| `textIEndsWith(textVar,searchValue,alias)` | ✅ REAL | textVar:string, searchValue:string, alias:string | this | Check ends with (case-insensitive) |

⚠️ **Note:** These methods currently have SDK implementation bugs. Use filter alternatives until fixed:

```json
{
  "operations": [
    {"method": "var", "args": ["is_gmail", "$input.email|contains:\"@gmail.com\""]},
    {"method": "var", "args": ["is_john", "$input.name|istarts_with:\"john\""]}
  ]
}
```

---

## String Manipulation

**Additional real manipulation methods:**

| Method | Status | Params | Returns | Purpose |
|--------|--------|--------|---------|---------|
| `textAppend(textVar,appendValue)` | ✅ REAL | textVar:string, appendValue:string | this | Append to string (2 params max) |
| `textPrepend(textVar,prependValue)` | ✅ REAL | textVar:string, prependValue:string | this | Prepend to string |
| `textLtrim(textVar)` | ✅ REAL | textVar:string | this | Trim left whitespace |
| `textRtrim(textVar)` | ✅ REAL | textVar:string | this | Trim right whitespace |

### Examples

```json
{
  "operations": [
    {"method": "textTrim", "args": ["input_text"]},
    {"method": "textAppend", "args": ["message", " - Added text"]},
    {"method": "textPrepend", "args": ["name", "Mr. "]}
  ]
}
```

---

**Total Methods in this File: 4 core + 7 additional = 11 methods**

**Architecture Note:**
- ✅ **4 core text methods** exist as SDK methods (trim, contains, startsWith, endsWith)
- ✅ **7 additional methods** for variations and manipulation
- ⚠️ **7 operations** that were previously documented as methods should use filters instead

**Verification Status:**
- ✅ Verified 2025-01-13
- Core methods confirmed working: `textTrim()`, `textContains()`, `textStartsWith()`, `textEndsWith()`
- Filter alternatives documented for all other text operations

For workflow guidance, see [workflow.md](workflow.md)
