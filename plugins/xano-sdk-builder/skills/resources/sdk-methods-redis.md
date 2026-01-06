# SDK Redis Methods

Redis operations for caching, key-value storage, lists, sets, hashes, and rate limiting.

## Table of Contents
- [Basic Key-Value](#basic-key-value)
- [Numbers](#numbers)
- [Hashes](#hashes)
- [Lists](#lists)
- [Sets](#sets)
- [Advanced](#advanced)

---

## Basic Key-Value

**10 methods** for basic Redis string operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `redisGet(key,alias?)` | key:string, alias?:string | this | Get value |
| `redisSet(key,value,ttl?,alias?)` | key:string, value:any, ttl?:number, alias?:string | this | Set value with TTL |
| `redisDelete(keys,alias?)` | keys:string\|string[], alias?:string | this | Delete key(s) |
| `redisDel(keys,alias?)` | keys:string\|string[], alias?:string | this | Alias for `.redisDelete()` |
| `redisExists(key,alias?)` | key:string, alias?:string | this | Check key exists |
| `redisKeys(pattern,alias?)` | pattern:string, alias?:string | this | Find keys by pattern |
| `redisExpire(key,seconds,alias?)` | key:string, seconds:number, alias?:string | this | Set key expiration |
| `redisTtl(key,alias?)` | key:string, alias?:string | this | Get remaining TTL |
| `redisSetex(key,seconds,value,alias?)` | key:string, seconds:number, value:any, alias?:string | this | Set with expiration |
| `redisSetnx(key,value,alias?)` | key:string, value:any, alias?:string | this | Set if not exists |

### Examples

```json
{
  "operations": [
    {"method": "redisSet", "args": ["session:$user_id", "$session_data", 3600, "result"]},
    {"method": "redisGet", "args": ["session:$user_id", "session"]},
    {"method": "redisExists", "args": ["cache:$key", "exists"]}
  ]
}
```

---

## Numbers

**4 methods** for numeric operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `redisIncr(key,by?,alias?)` | key:string, by?:number, alias?:string | this | Increment |
| `redisDecr(key,by?,alias?)` | key:string, by?:number, alias?:string | this | Decrement |
| `redisIncrBy(key,amount,alias?)` | key:string, amount:number, alias?:string | this | Increment by amount |
| `redisDecrBy(key,amount,alias?)` | key:string, amount:number, alias?:string | this | Decrement by amount |

### Examples

```json
{
  "operations": [
    {"method": "redisIncr", "args": ["page:views:$page_id", 1, "views"]},
    {"method": "redisIncrBy", "args": ["user:points:$user_id", 100, "points"]}
  ]
}
```

---

## Hashes

**4 methods** for hash operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `redisHget(key,field,alias?)` | key:string, field:string, alias?:string | this | Get hash field |
| `redisHset(key,field,value)` | key:string, field:string, value:any | this | Set hash field |
| `redisHdel(key,field)` | key:string, field:string\|string[] | this | Delete hash field |
| `redisHgetall(key,alias?)` | key:string, alias?:string | this | Get all hash fields |

### Examples

```json
{
  "operations": [
    {"method": "redisHset", "args": ["user:$user_id", "email", "$email"]},
    {"method": "redisHget", "args": ["user:$user_id", "email", "email"]},
    {"method": "redisHgetall", "args": ["user:$user_id", "user_data"]}
  ]
}
```

---

## Lists

**6 methods** for list operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `redisLpush(key,value,alias?)` | key:string, value:any, alias?:string | this | Push to list head |
| `redisRpush(key,value,alias?)` | key:string, value:any, alias?:string | this | Push to list tail |
| `redisLpop(key,alias?)` | key:string, alias?:string | this | Pop from head |
| `redisRpop(key,alias?)` | key:string, alias?:string | this | Pop from tail |
| `redisLlen(key,alias?)` | key:string, alias?:string | this | Get list length |
| `redisRange(list,start,end,alias)` | list:string, start:number, end:number, alias:string | this | Get range of items |

### Examples

```json
{
  "operations": [
    {"method": "redisRpush", "args": ["queue:jobs", "$job_data", "length"]},
    {"method": "redisLpop", "args": ["queue:jobs", "job"]},
    {"method": "redisRange", "args": ["recent:items", 0, 10, "items"]}
  ]
}
```

---

## Sets

**3 methods** for set operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `redisSadd(key,value,alias?)` | key:string, value:any\|any[], alias?:string | this | Add to set |
| `redisSrem(key,value,alias?)` | key:string, value:any\|any[], alias?:string | this | Remove from set |
| `redisSmembers(key,alias?)` | key:string, alias?:string | this | Get all set members |

### Examples

```json
{
  "operations": [
    {"method": "redisSadd", "args": ["users:online", "$user_id", "added"]},
    {"method": "redisSmembers", "args": ["users:online", "online_users"]}
  ]
}
```

---

## Advanced

**5 methods** for advanced operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `redisRatelimit(key,limit,window,alias?)` | key:string, limit:number, window:number, alias?:string | this | Rate limiting |
| `redisAppend(key,value,alias?)` | key:string, value:any, alias?:string | this | Append to string |
| `redisStrlen(key,alias?)` | key:string, alias?:string | this | String length |
| `redisFlushAll(alias?)` | alias?:string | this | Clear all Redis data |
| `redisRateLimit(key,max,ttl,errorMessage?)` | key:string, max:number, ttl:number, errorMessage?:string | this | Rate limit enforcement |

### Examples

```json
{
  "operations": [
    {"method": "redisRatelimit", "args": ["api:$user_id", 100, 60, "rate_limit"]},
    {"method": "redisAppend", "args": ["log:$session_id", "New log entry\n", "length"]}
  ]
}
```

---

**Total Methods in this File: 32**

For workflow guidance, see [workflow.md](workflow.md)
