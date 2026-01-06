# SDK Data Structure Methods

Array, object, and math manipulation methods for working with data structures.

## Table of Contents
- [Math Operations](#math-operations)
- [Arrays](#arrays)
- [Objects](#objects)

---

## Math Operations

**8 methods** for mathematical operations on variables. ✅ **ALL VERIFIED WORKING** - Tested 2025-01-13

| Method | Status | Params | Returns | Purpose |
|--------|--------|--------|---------|---------|
| `mathAdd(varName,value)` | ✅ VERIFIED | varName:string, value:number | this | Add to variable |
| `mathSubtract(varName,value)` | ✅ VERIFIED | varName:string, value:number | this | Subtract from variable |
| `mathMultiply(varName,value)` | ✅ VERIFIED | varName:string, value:number | this | Multiply variable |
| `mathDivide(varName,value)` | ✅ VERIFIED | varName:string, value:number | this | Divide variable |
| `mathMod(varName,value)` | ✅ EXISTS | varName:string, value:number | this | Modulus operation |
| `mathBitwiseAnd(varName,value)` | ✅ VERIFIED | varName:string, value:number | this | Bitwise AND |
| `mathBitwiseOr(varName,value)` | ✅ VERIFIED | varName:string, value:number | this | Bitwise OR |
| `mathBitwiseXor(varName,value)` | ✅ VERIFIED | varName:string, value:number | this | Bitwise XOR |

### Examples

**Basic Math Operations:**
```json
{
  "operations": [
    {"method": "var", "args": ["counter", 0]},
    {"method": "mathAdd", "args": ["counter", 5]},
    {"method": "mathSubtract", "args": ["counter", 2]},
    {"method": "mathMultiply", "args": ["counter", 10]},
    {"method": "mathDivide", "args": ["counter", 3]},
    {"method": "response", "args": [{"result": "$counter"}]}
  ]
}
```

**Generated XanoScript:**
```xanoscript
var counter {
  value = 0
}
math.add counter {
  value = 5
}
math.sub counter {
  value = 2
}
math.mul counter {
  value = 10
}
math.div counter {
  value = 3
}
response = {result: $counter}
```

**Bitwise Operations:**
```json
{
  "operations": [
    {"method": "var", "args": ["flags", 5]},
    {"method": "mathBitwiseAnd", "args": ["flags", 3]},
    {"method": "mathBitwiseOr", "args": ["flags", 8]},
    {"method": "mathBitwiseXor", "args": ["flags", 2]},
    {"method": "response", "args": [{"flags": "$flags"}]}
  ]
}
```

**Generated XanoScript:**
```xanoscript
var flags {
  value = 5
}
math.bitwise.and flags {
  value = 3
}
math.bitwise.or flags {
  value = 8
}
math.bitwise.xor flags {
  value = 2
}
response = {flags: $flags}
```

**Use Cases:**
- Incrementing counters (votes, views, likes)
- Calculating totals and subtotals
- Computing percentages and ratios
- Bit manipulation for flags and permissions
- Mathematical transformations

**IMPORTANT:**
- All math operations modify the variable in-place
- Use full method names: `mathSubtract`, `mathMultiply`, `mathDivide` (not mathSub, mathMul, mathDiv)
- Variable must exist before performing math operations
- Operations execute in order (not mathematical precedence)

---

## Arrays

**17 methods** for array manipulation. ✅ **ALL VERIFIED REAL** - All array methods exist and work in SDK Builder.

### Basic Operations (5 methods)

| Method | Status | Params | Returns | Purpose |
|--------|--------|--------|---------|---------|
| `arrayPush(arrayVar,value)` | ✅ VERIFIED | arrayVar:string, value:any | this | Push item to array |
| `arrayPop(arrayVar,alias)` | ✅ VERIFIED | arrayVar:string, alias:string | this | Pop from array |
| `arrayShift(arrayVar,alias)` | ✅ VERIFIED | arrayVar:string, alias:string | this | Shift from array |
| `arrayUnshift(arrayVar,value)` | ✅ VERIFIED | arrayVar:string, value:any | this | Unshift item to array |
| `arrayMerge(arrayVar,value)` | ✅ VERIFIED | arrayVar:string, value:any | this | Merge array |

### Search/Filter (6 methods)

| Method | Status | Params | Returns | Purpose |
|--------|--------|--------|---------|---------|
| `arrayFind(arrayVar,condition,alias)` | ✅ VERIFIED | arrayVar:string, condition:string, alias:string | this | Find item in array |
| `arrayFindIndex(arrayVar,condition,alias)` | ✅ VERIFIED | arrayVar:string, condition:string, alias:string | this | Find index in array |
| `arrayHas(arrayVar,condition,alias)` | ✅ VERIFIED | arrayVar:string, condition:string, alias:string | this | Check array contains item |
| `arrayFilter(arrayVar,condition,alias)` | ✅ VERIFIED | arrayVar:string, condition:string, alias:string | this | Filter array items |
| `arrayFilterCount(arrayVar,condition,alias)` | ✅ VERIFIED | arrayVar:string, condition:string, alias:string | this | Count filtered items |
| `arrayEvery(arrayVar,condition,alias)` | ✅ VERIFIED | arrayVar:string, condition:string, alias:string | this | Check all items match condition |

### Transform (1 method)

| Method | Status | Params | Returns | Purpose |
|--------|--------|--------|---------|---------|
| `arrayMap(arrayVar,transformExpr,alias)` | ✅ VERIFIED 2025-01-13 | arrayVar:string, transformExpr:string, alias:string | this | Transform each element |

#### `arrayMap()` - Transform Array Elements

**Description:** Apply a transformation expression to each element in an array.

**Parameters:**
- `arrayVar` (string) - Variable name containing array
- `transformExpr` (string) - Expression using `$this` to transform each element
- `alias` (string) - Variable to store result

**Example:**
```json
{
  "method": "arrayMap",
  "args": ["users", "$this.email", "emails"]
}
```

**Generated XanoScript:**
```xanoscript
array.map (users) as emails {
  value = $this.email
}
```

**Use Cases:**
- Extract specific fields from objects (e.g., get all emails from user objects)
- Transform values (multiply numbers, format dates, convert types)
- Create derived data from existing arrays
- Convert data structures

### Grouping (2 methods)

| Method | Status | Params | Returns | Purpose |
|--------|--------|--------|---------|---------|
| `arrayPartition(arrayVar,condition,alias)` | ✅ VERIFIED 2025-01-13 | arrayVar:string, condition:string, alias:string | this | Split into true/false groups |
| `arrayGroupBy(arrayVar,keyExpr,alias)` | ✅ VERIFIED 2025-01-13 | arrayVar:string, keyExpr:string, alias:string | this | Group by key expression |

#### `arrayPartition()` - Split Array by Condition

**Description:** Split an array into two groups based on a boolean condition.

**Parameters:**
- `arrayVar` (string) - Variable name containing array
- `condition` (string) - Boolean expression using `$this`
- `alias` (string) - Variable to store result (object with `true` and `false` keys)

**Example:**
```json
{
  "method": "arrayPartition",
  "args": ["numbers", "$this > 0", "partitioned"]
}
```

**Generated XanoScript:**
```xanoscript
array.partition (numbers) if (`$this > 0`) as partitioned
```

**Result Structure:**
```json
{
  "true": [1, 2, 3],
  "false": [-1, -2, 0]
}
```

**Use Cases:**
- Separate active/inactive records
- Split valid/invalid data
- Categorize into two groups
- Filter with remainder tracking

#### `arrayGroupBy()` - Group Array by Key

**Description:** Group array elements by a key expression into an object.

**Parameters:**
- `arrayVar` (string) - Variable name containing array
- `keyExpr` (string) - Expression using `$this` to extract grouping key
- `alias` (string) - Variable to store result (object with keys = group values)

**Example:**
```json
{
  "method": "arrayGroupBy",
  "args": ["orders", "$this.customer_id", "by_customer"]
}
```

**Generated XanoScript:**
```xanoscript
array.group_by (orders) as by_customer {
  key = $this.customer_id
}
```

**Result Structure:**
```json
{
  "customer_1": [{"order": 1}, {"order": 2}],
  "customer_2": [{"order": 3}]
}
```

**Use Cases:**
- Group orders by customer
- Organize data by category/status
- Aggregate by dimension
- Create lookup tables

### Set Operations (3 methods)

| Method | Status | Params | Returns | Purpose |
|--------|--------|--------|---------|---------|
| `arrayDiff(arrayA,arrayB,alias)` | ✅ VERIFIED 2025-01-13 | arrayA:string, arrayB:string, alias:string | this | Elements in A not in B |
| `arrayIntersect(arrayA,arrayB,alias)` | ✅ VERIFIED 2025-01-13 | arrayA:string, arrayB:string, alias:string | this | Elements in both arrays |
| `arrayUnion(arrayA,arrayB,alias)` | ✅ VERIFIED 2025-01-13 | arrayA:string, arrayB:string, alias:string | this | Combine with deduplication |

#### `arrayDiff()` - Array Difference

**Description:** Get elements in arrayA that are NOT in arrayB.

**Parameters:**
- `arrayA` (string) - First array variable
- `arrayB` (string) - Second array variable
- `alias` (string) - Variable to store result

**Example:**
```json
{
  "method": "arrayDiff",
  "args": ["all_ids", "processed_ids", "remaining"]
}
```

**Generated XanoScript:**
```xanoscript
array.diff all_ids processed_ids as remaining
```

**Use Cases:**
- Find unprocessed items
- Get missing records
- Calculate remaining work
- Set difference operations

#### `arrayIntersect()` - Array Intersection

**Description:** Get elements that exist in BOTH arrays.

**Parameters:**
- `arrayA` (string) - First array variable
- `arrayB` (string) - Second array variable
- `alias` (string) - Variable to store result

**Example:**
```json
{
  "method": "arrayIntersect",
  "args": ["user_tags", "filter_tags", "matching"]
}
```

**Generated XanoScript:**
```xanoscript
array.intersect user_tags filter_tags as matching
```

**Use Cases:**
- Find common elements
- Match criteria
- Filter overlaps
- Set intersection

#### `arrayUnion()` - Array Union

**Description:** Combine two arrays and remove duplicates.

**Parameters:**
- `arrayA` (string) - First array variable
- `arrayB` (string) - Second array variable
- `alias` (string) - Variable to store result

**Example:**
```json
{
  "method": "arrayUnion",
  "args": ["existing_tags", "new_tags", "all_tags"]
}
```

**Generated XanoScript:**
```xanoscript
array.union existing_tags new_tags as all_tags
```

**Use Cases:**
- Merge lists with deduplication
- Combine unique values
- Consolidate data
- Set union operations

### Examples

⚠️ **IMPORTANT:** Array methods (`arrayFilter`, `arrayFind`, `arrayHas`, etc.) use `$this` as the iterator variable, not `$item`.

```json
{
  "operations": [
    {"method": "arrayPush", "args": ["items", {"id": 1, "name": "Item"}]},
    {"method": "arrayFilter", "args": ["users", "$this.status == \"active\"", "active_users"]},
    {"method": "arrayFind", "args": ["users", "$this.id == 5", "user"]},
    {"method": "arrayHas", "args": ["items", "$this.id == $input.id", "has_item"]}
  ]
}
```

**Note:** Pipeline filters like `|filter:` and `|map:` use `$item`, and forEach loops use custom variable names.

---

## Objects

**14 methods** documented, but ⚠️ **ONLY 3 ARE REAL** - Most should use filters instead.

### ✅ Real Object Methods (Use These)

| Method | Status | Params | Returns | Purpose |
|--------|--------|--------|---------|---------|
| `objectKeys(objectVar,alias?)` | ✅ REAL | objectVar:string, alias?:string | this | Get object keys |
| `objectValues(objectVar,alias?)` | ✅ REAL | objectVar:string, alias?:string | this | Get object values |
| `objectEntries(objectVar,alias?)` | ✅ REAL | objectVar:string, alias?:string | this | Get object entries |

### ❌ Fake Object Methods (Use Filters Instead)

| Method | Status | Filter Alternative |
|--------|--------|-------------------|
| `objectCreate(fields,alias?)` | ❌ FAKE | Use `var obj { value = {} }` |
| `objectGet(objectVar,key,alias?)` | ❌ FAKE | Use `$obj\|get:"key"` or `$obj.key` |
| `objectSet(objectVar,key,value,alias?)` | ❌ FAKE | Use `$obj\|set:"key":$value` |
| `objectMerge(object1,object2,alias?)` | ❌ FAKE | Use `$obj\|merge:$other` |
| `objectHas(objectVar,key,alias?)` | ❌ FAKE | Use `$obj\|has:"key"` |
| `objectDelete(objectVar,key,alias?)` | ❌ FAKE | Use `$obj\|unset:"key"` |
| `objectClear(objectVar,alias?)` | ❌ FAKE | Use `var obj { value = {} }` |
| `objectSize(objectVar,alias?)` | ❌ FAKE | Use `$obj\|keys\|count` |
| `objectFilter(objectVar,condition,alias?)` | ❌ FAKE | Use `$obj\|filter:'condition'` |
| `objectMap(objectVar,mapping,alias?)` | ❌ FAKE | Use `$obj\|map:'expression'` |
| `objectReduce(objectVar,accumulator,expression,alias?)` | ❌ FAKE | Use `$obj\|reduce:'expression'` |

### Examples

**✅ Using Real Methods:**
```json
{
  "operations": [
    {"method": "objectKeys", "args": ["user", "keys"]},
    {"method": "objectValues", "args": ["user", "values"]},
    {"method": "objectEntries", "args": ["user", "entries"]}
  ]
}
```

**✅ Using Filters (Recommended for other operations):**
```json
{
  "operations": [
    {"method": "var", "args": ["user", "{}|set:\"name\":\"John\"|set:\"age\":30"]},
    {"method": "var", "args": ["username", "$user|get:\"name\""]},
    {"method": "var", "args": ["has_email", "$user|has:\"email\""]},
    {"method": "var", "args": ["merged", "$user|merge:$updates"]}
  ]
}
```

---

**Total Methods in this File: 39**
- 8 Math Operations (all verified working)
- 17 Array methods (all verified working, including 6 advanced methods added 2025-01-13)
- 3 Real Object methods (objectKeys, objectValues, objectEntries)
- 11 Fake Object methods (use filters instead)

**Array Methods Breakdown:**
- Basic Operations: 5 methods (push, pop, shift, unshift, merge)
- Search/Filter: 6 methods (find, findIndex, has, filter, filterCount, every)
- Transform: 1 method (map)
- Grouping: 2 methods (partition, groupBy)
- Set Operations: 3 methods (diff, intersect, union)

**Verification Status:**
- ✅ All 17 array methods verified working 2025-01-13
- ✅ 6 advanced array methods (map, partition, groupBy, diff, intersect, union) added and verified 2025-01-13

For workflow guidance, see [workflow.md](workflow.md)
