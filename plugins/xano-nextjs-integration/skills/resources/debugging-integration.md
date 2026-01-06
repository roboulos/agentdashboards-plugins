# Debugging Integration Issues

Comprehensive guide to diagnosing and fixing Xano ↔ Next.js integration problems.

## Table of Contents

1. [Data Not Appearing](#data-not-appearing)
2. [API Calls Failing](#api-calls-failing)
3. [State Not Syncing](#state-not-syncing)
4. [Type Mismatches](#type-mismatches)
5. [Authentication Issues](#authentication-issues)
6. [Performance Problems](#performance-problems)

---

## Data Not Appearing

### Symptom: Component Shows Loading Forever

**Debug Checklist**:

1. **Check Network Tab**
   ```
   Open DevTools → Network tab
   Look for API requests:
   ✅ Request made
   ❌ Request not made
   ✅ 200 status
   ❌ 404/500 status
   ```

2. **Check Console Errors**
   ```typescript
   // In component
   const { data, error, isLoading } = useUser(userId);

   // Add logging
   console.log('Query state:', { data, error, isLoading });
   ```

3. **Verify Hook is Enabled**
   ```typescript
   // WRONG - Hook disabled, never fetches
   const { data } = useQuery({
     queryKey: ['user', userId],
     queryFn: () => userService.getUser(userId),
     enabled: false // ❌ This prevents fetching!
   });

   // RIGHT - Always enabled
   const { data } = useQuery({
     queryKey: ['user', userId],
     queryFn: () => userService.getUser(userId),
     enabled: !!userId // ✅ Only enable when userId exists
   });
   ```

4. **Check API Response**
   ```
   DevTools → Network → Click API request
   → Response tab
   Should show JSON data from Xano
   ```

5. **Verify Query Key Consistency**
   ```typescript
   // WRONG - Different query keys
   useQuery({
     queryKey: ['user', userId], // Key 1
     ...
   });

   // Later, trying to update:
   queryClient.invalidateQueries({ queryKey: ['users'] }); // Key 2
   // ❌ Different key, won't invalidate

   // RIGHT - Consistent keys
   useQuery({
     queryKey: ['user', userId],
     ...
   });
   queryClient.invalidateQueries({ queryKey: ['user', userId] });
   ```

### Common Causes

| Cause | Fix |
|-------|-----|
| Query disabled (enabled: false) | Check enabled condition |
| Wrong query key | Verify queryKey consistency |
| API not returning data | Check Xano endpoint response |
| CORS error | Check Xano CORS configuration |
| Wrong API URL | Verify NEXT_PUBLIC_XANO_URL |

---

## API Calls Failing

### Symptom: Error in Console, 4xx/5xx Status

**Debug Steps**:

**Step 1: Check HTTP Status**
```
DevTools → Network tab
Look at status code:
- 400 = Bad request (wrong data sent)
- 401 = Unauthorized (auth token missing/invalid)
- 403 = Forbidden (permission denied)
- 404 = Not found (wrong endpoint)
- 500 = Server error (Xano bug)
```

**Step 2: Check Request Details**
```
DevTools → Network → Click request
→ Request tab:
  - Verify method (GET, POST, etc)
  - Verify URL (correct endpoint?)
  - Verify headers (auth token present?)
  - Verify body (correct data format?)
```

**Step 3: Check Response**
```
DevTools → Response tab:
Look for error message from Xano
Example: { "error": "Email already exists", "code": "DUPLICATE_EMAIL" }
```

**Step 4: Add Error Logging**
```typescript
export function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: async () => {
      try {
        const response = await userService.getUser(userId);
        console.log('✅ User fetch success:', response);
        return response;
      } catch (error) {
        console.error('❌ User fetch failed:', {
          status: error.response?.status,
          message: error.response?.data?.message,
          url: error.config?.url
        });
        throw error;
      }
    }
  });
}
```

**Step 5: Test Directly**
```bash
# Test API with curl
curl -X GET https://your-xano-url/api/users/123 \
  -H "Authorization: Bearer YOUR_TOKEN"

# Check response
```

### 400 Bad Request

**Common Causes**:
- Required field missing
- Wrong data type
- Invalid format

**Fix**:
```typescript
// Check what Xano expects
const validatedData = {
  email: 'john@example.com', // ✅ Email string
  name: 'John', // ✅ String
  age: 30 // ✅ Number (not string)
};

// Verify before sending
console.log('Sending:', validatedData);
const response = await xanoClient.post('/users', validatedData);
```

---

### 401 Unauthorized

**Common Causes**:
- Auth token missing
- Token expired
- Token invalid

**Fix**:
```typescript
// Check if token exists
const token = localStorage.getItem('authToken');
console.log('Auth token:', token ? '✅ exists' : '❌ missing');

// Check token in request
xanoClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
    console.log('✅ Authorization header set');
  } else {
    console.warn('⚠️ No auth token found');
  }
  return config;
});
```

---

### 404 Not Found

**Common Causes**:
- Wrong endpoint URL
- Typo in route
- Endpoint doesn't exist

**Fix**:
```typescript
// Log the actual URL being called
xanoClient.interceptors.request.use((config) => {
  console.log('API Call:', config.method.toUpperCase(), config.url);
  return config;
});

// Verify URL matches Xano endpoint
// Xano: /api/v1/users/{id}
// Next.js: xanoClient.get(`/users/${userId}`)
// ❌ Missing /api/v1 prefix?
```

---

### 500 Server Error

**Common Causes**:
- Bug in Xano endpoint
- Database connection error
- Xano service down

**Fix**:
```typescript
// Check Xano status
// 1. Verify Xano is running
// 2. Check Xano logs for errors
// 3. Simplify request (remove optional fields)
// 4. Test with different data
```

---

## State Not Syncing

### Symptom: Data Changed in Xano, Component Doesn't Update

**Debug Steps**:

**Step 1: Verify Mutation Invalidation**
```typescript
// WRONG - Doesn't invalidate
const { mutate } = useMutation({
  mutationFn: (data) => updateUser(data),
  onSuccess: () => {
    showSuccess('Updated');
    // ❌ Forgot to invalidate query
  }
});

// RIGHT - Invalidates and refetches
const { mutate } = useMutation({
  mutationFn: (data) => updateUser(data),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['users'] });
    showSuccess('Updated');
  }
});
```

**Step 2: Check Query Key Matching**
```typescript
// Define hook with key
function useUsers() {
  return useQuery({
    queryKey: ['users'], // Key is ['users']
    queryFn: () => userService.getUsers()
  });
}

// Invalidate with SAME key
queryClient.invalidateQueries({ queryKey: ['users'] }); // ✅ Matches

// ❌ Won't work - different key
queryClient.invalidateQueries({ queryKey: ['user'] });
```

**Step 3: Manual Refetch**
```typescript
export function useUsers() {
  const query = useQuery({
    queryKey: ['users'],
    queryFn: () => userService.getUsers()
  });

  // Manually refetch when needed
  const handleRefresh = () => query.refetch();

  return { ...query, refetch: handleRefresh };
}

// In component
const { data, refetch } = useUsers();
return <button onClick={refetch}>Refresh</button>;
```

---

## Type Mismatches

### Symptom: TypeScript Errors About API Response

**Debug Steps**:

**Step 1: Define Xano Response Types**
```typescript
// types/xano.ts
export interface User {
  id: string;
  name: string;
  email: string;
  createdAt: string;
}

export interface UserResponse {
  success: boolean;
  data: User;
}
```

**Step 2: Type Service Functions**
```typescript
// WRONG - No types
export async function getUser(userId: string) {
  const response = await xanoClient.get(`/users/${userId}`);
  return response.data; // ❌ Type is 'any'
}

// RIGHT - With types
export async function getUser(userId: string): Promise<User> {
  const response = await xanoClient.get<User>(`/users/${userId}`);
  return response.data; // ✅ Type is 'User'
}
```

**Step 3: Type Hooks**
```typescript
// Automatically typed from service function
export function useUser(userId: string) {
  return useQuery<User, Error>({
    queryKey: ['user', userId],
    queryFn: () => userService.getUser(userId) // ✅ Returns User
  });
}

// Component gets types automatically
const { data: user } = useUser(userId);
// user.name ✅ available
// user.invalid ❌ TypeScript error
```

---

## Authentication Issues

### Symptom: 401 Error on Protected Routes

**Debug Checklist**:

1. **Verify Token Storage**
```typescript
// Check if token exists
console.log('Token:', localStorage.getItem('authToken'));

// Check token format
const token = localStorage.getItem('authToken');
console.log('Token starts with Bearer?', token?.startsWith('eyJ'));
```

2. **Verify Token Inclusion**
```typescript
xanoClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  console.log('Request to:', config.url);
  console.log('Authorization header:', config.headers.Authorization);
  return config;
});
```

3. **Check Token Expiration**
```typescript
// Decode JWT to check expiration
function isTokenExpired(token: string) {
  const decoded = JSON.parse(atob(token.split('.')[1]));
  return decoded.exp * 1000 < Date.now();
}

const token = localStorage.getItem('authToken');
if (token && isTokenExpired(token)) {
  console.warn('⚠️ Token expired');
  // Refresh token or redirect to login
}
```

---

## Performance Problems

### Symptom: Slow API Responses, Many Network Requests

**Debug Steps**:

**Step 1: Check Request Count**
```
DevTools → Network tab
Are you making too many requests?

Signs of problems:
- Same API called multiple times
- Waterfall of requests (one depends on previous)
- Requests > 10 for single page
```

**Step 2: Check Caching**
```typescript
// WRONG - No caching
function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => userService.getUser(userId),
    staleTime: 0 // ❌ Always refetch
  });
}

// RIGHT - With caching
function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => userService.getUser(userId),
    staleTime: 5 * 60 * 1000 // ✅ Cache for 5 minutes
  });
}
```

**Step 3: Check for N+1 Problem**
```typescript
// WRONG - Fetches each user individually
function UserList({ userIds }: Props) {
  return (
    <div>
      {userIds.map(id => (
        <UserItem key={id} userId={id} /> // ❌ Calls useUser for each
      ))}
    </div>
  );
}

// RIGHT - Fetch all at once
function UserList({ userIds }: Props) {
  const { data: users } = useUsers(); // Single request for all
  return (
    <div>
      {userIds.map(id => {
        const user = users?.find(u => u.id === id);
        return <UserItem key={id} user={user} />;
      })}
    </div>
  );
}
```

**Step 4: Check Response Size**
```
DevTools → Network → Click request
→ Size: Should be reasonable
- User object: < 5KB
- List of 100 users: < 100KB

If larger:
- Ask Xano to return fewer fields
- Implement pagination
- Implement lazy loading
```

---

## Debug Toolkit

### Browser DevTools Checklist

```
□ Network tab open?
  □ Requests showing?
  □ Status codes correct?
  □ Response content correct?
  □ Headers correct (Auth token)?

□ Console for errors?
  □ No red error messages?
  □ No yellow warnings?
  □ Custom logs showing expected values?

□ React DevTools?
  □ Component receiving correct props?
  □ Query state correct (data, isPending, error)?
  □ Mutation state correct?
```

### Logging Strategy

```typescript
// Create debug logger
const DEBUG = true;

function log(...args: any[]) {
  if (DEBUG) console.log('[DEBUG]', ...args);
}

function logError(...args: any[]) {
  if (DEBUG) console.error('[ERROR]', ...args);
}

// Use in service
export async function getUser(userId: string) {
  log('Fetching user:', userId);
  try {
    const response = await xanoClient.get(`/users/${userId}`);
    log('✅ Got user:', response.data);
    return response.data;
  } catch (error) {
    logError('❌ Failed to get user:', error);
    throw error;
  }
}
```

---

**Remember**: Always check the network tab first - that's where the truth lives!
