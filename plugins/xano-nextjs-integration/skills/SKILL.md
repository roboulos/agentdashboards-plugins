---
name: xano-nextjs-integration
description: Expert guidance for Xano ↔ Next.js integration architecture. Use when building Next.js components that consume Xano APIs, designing data flows between frontend and Xano backend, structuring service layers, handling authentication/state management, or deciding what logic belongs in Xano vs Next.js. Covers component-to-service patterns, API client design, state synchronization, type safety across boundaries, and debugging integration issues.
---

# Xano ↔ Next.js Integration Expert

## Purpose

Optimize the relationship between **Next.js frontend** and **Xano backend** where:
- **Xano** owns: APIs, routes, database, business logic, validations
- **Next.js** owns: UI components, state management, API client
- **Integration** = How data flows between them efficiently

## Core Principle: Clean Separation

```
┌─────────────────────────────────┐
│     Next.js Frontend            │
│  ┌──────────────────────────┐   │
│  │  React Components        │   │
│  │  (render, interact)      │   │
│  └────────────┬─────────────┘   │
│               │                  │
│  ┌────────────▼─────────────┐   │
│  │  Service Layer (Hooks)   │   │
│  │  (fetch, transform data) │   │
│  └────────────┬─────────────┘   │
│               │                  │
│  ┌────────────▼─────────────┐   │
│  │  API Client              │   │
│  │  (http calls to Xano)    │   │
│  └────────────┬─────────────┘   │
└───────────────┼──────────────────┘
                │ HTTP/JSON
┌───────────────▼──────────────────┐
│  Xano Backend                    │
│  ┌──────────────────────────┐    │
│  │  API Endpoints           │    │
│  │  Routes (REST endpoints) │    │
│  └────────────┬─────────────┘    │
│               │                   │
│  ┌────────────▼─────────────┐    │
│  │  Business Logic          │    │
│  │  (validation, rules)     │    │
│  └────────────┬─────────────┘    │
│               │                   │
│  ┌────────────▼─────────────┐    │
│  │  Database                │    │
│  │  (Xano data)             │    │
│  └──────────────────────────┘    │
└─────────────────────────────────┘
```

---

## When to Use This Skill

Activate when:
- Building Next.js components that call Xano APIs
- Designing how data flows between frontend and backend
- Deciding where logic belongs (Next.js vs Xano)
- Setting up API client patterns
- Managing state synchronized with Xano
- Debugging data flow issues
- Optimizing fetch/caching strategies
- Handling authentication tokens
- TypeScript types across the boundary

---

## 🚨 Critical Rules

### Rule 1: No Next.js API Routes
```
❌ WRONG: Creating /api/users.ts in Next.js
✅ RIGHT: All APIs live in Xano, Next.js calls them
```

**Why**: Single source of truth. Xano owns all business logic.

### Rule 2: Xano is Authoritative
```
❌ WRONG: Frontend validates email, then sends to Xano
✅ RIGHT: Xano validates email, returns error if invalid
```

**Why**: Frontend validation is UX only. Xano validation is security.

### Rule 3: Service Layer Pattern Required
```
❌ WRONG: React component directly calls fetch()
✅ RIGHT: Component uses hook → Hook uses service → Service calls Xano
```

**Why**: Testable, reusable, consistent error handling.

### Rule 4: Type Safety Across Boundary
```
❌ WRONG: API returns any, component assumes structure
✅ RIGHT: Xano types defined, generated/imported in Next.js
```

**Why**: Catch bugs before runtime.

---

## Standard Integration Patterns

### Pattern 1: Simple Data Fetch

```typescript
// 1. Define hook (service layer)
function useUser(userId: string) {
  return useSuspenseQuery({
    queryKey: ['user', userId],
    queryFn: () => xanoClient.get(`/users/${userId}`)
  });
}

// 2. Use in component
export function UserCard({ userId }: Props) {
  const { data: user } = useUser(userId);
  return <div>{user.name}</div>;
}
```

**Flow**: Component → Hook (service) → xanoClient → Xano

### Pattern 2: Form Submission

```typescript
// 1. Service function
async function submitContactForm(data: ContactForm) {
  try {
    const response = await xanoClient.post('/contact', data);
    return { success: true, data: response };
  } catch (error) {
    return {
      success: false,
      error: error.message,
      validationErrors: error.response?.data?.errors
    };
  }
}

// 2. Component with mutation
export function ContactForm() {
  const [submit, { isPending }] = useMutation({
    mutationFn: submitContactForm
  });

  return (
    <form onSubmit={async (e) => {
      e.preventDefault();
      const result = await submit(formData);
      if (!result.success) showErrors(result.validationErrors);
    }}>
      {/* form fields */}
    </form>
  );
}
```

**Flow**: Component form → Mutation → Service → xanoClient → Xano

### Pattern 3: State Synchronization

```typescript
// 1. Query for current state
const { data: todos } = useQuery({
  queryKey: ['todos'],
  queryFn: () => xanoClient.get('/todos')
});

// 2. Mutation that updates
const { mutate: addTodo } = useMutation({
  mutationFn: (todo: NewTodo) => xanoClient.post('/todos', todo),
  onSuccess: () => {
    // Revalidate query (TanStack Query auto-refetches)
    queryClient.invalidateQueries({ queryKey: ['todos'] });
  }
});

// 3. Component uses both
export function TodoList() {
  return (
    <>
      {todos?.map(t => <TodoItem key={t.id} todo={t} />)}
      <AddTodoForm onAdd={addTodo} />
    </>
  );
}
```

**Flow**: Component reads query → User interacts → Mutation to Xano → Query invalidated → UI re-syncs

---

## Key Concepts

### Service Layer (Hooks)
The bridge between components and API client.

**Responsibilities**:
- Transform API responses for component use
- Handle loading/error states
- Cache data (via TanStack Query)
- Retry logic
- Type conversions

**Pattern**:
```typescript
// hooks/useUsers.ts
export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const data = await xanoClient.get('/users');
      // Transform if needed
      return data.map(u => ({ ...u, fullName: `${u.first} ${u.last}` }));
    }
  });
}
```

### API Client
Thin wrapper around fetch that handles:
- Base URL
- Authentication headers
- Error standardization
- Request/response interceptors

**Pattern**:
```typescript
// lib/xanoClient.ts
const xanoClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_XANO_URL,
  withCredentials: true
});

xanoClient.interceptors.request.use((config) => {
  const token = getAuthToken();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default xanoClient;
```

### Type Safety Across Boundary
Define types for Xano responses in Next.js.

**Pattern**:
```typescript
// types/xano.ts
export interface User {
  id: string;
  email: string;
  name: string;
  createdAt: string;
}

export interface CreateUserRequest {
  email: string;
  name: string;
  password: string;
}

export interface UserResponse {
  success: boolean;
  data?: User;
  error?: string;
  validationErrors?: Record<string, string[]>;
}
```

---

## Debugging Guide

See [resources/debugging-integration.md](resources/debugging-integration.md) for:
- Data not appearing in component
- API calls failing silently
- State not syncing
- Type mismatches
- Authentication issues
- Performance problems

---

## Common Mistakes

### ❌ Mistake 1: Logic in Components
```typescript
// WRONG - Business logic in React
export function OrderTotal({ items }: Props) {
  const total = items.reduce((sum, item) => {
    const discount = item.price > 100 ? 0.1 : 0;
    return sum + (item.price * (1 - discount));
  }, 0);
  return <div>{total}</div>;
}
```

**Better**: Xano calculates total, Next.js just displays it
```typescript
// RIGHT
export function OrderTotal({ orderId }: Props) {
  const { data: order } = useOrder(orderId);
  return <div>{order.total}</div>;
}
```

### ❌ Mistake 2: Direct fetch() Calls
```typescript
// WRONG - Scattered fetch calls
export function UserProfile() {
  useEffect(() => {
    fetch('/api/user').then(r => r.json()).then(setUser);
  }, []);
}
```

**Better**: Use service layer hook
```typescript
// RIGHT
export function UserProfile() {
  const { data: user } = useCurrentUser();
  return <div>{user.name}</div>;
}
```

### ❌ Mistake 3: Frontend Validation as Security
```typescript
// WRONG - Only frontend validation
if (password.length < 8) return; // Then send to Xano
```

**Better**: Let Xano validate
```typescript
// RIGHT - Frontend for UX, Xano for security
if (password.length < 8) setError('Password too short'); // UX feedback
// But also send to Xano, which validates again
```

---

## Architecture Decisions

### Decision 1: Where does filtering live?

| Scenario | Answer | Why |
|----------|--------|-----|
| Complex filters, database-level performance | Xano | Can index, optimize queries |
| Simple UI-level filters | Next.js | Faster feedback, no API call |
| Multi-tenant data filtering | Xano | Security - prevent data leaks |

### Decision 2: Where does transformation live?

| Scenario | Answer | Why |
|----------|--------|-----|
| Date formatting for display | Next.js | UI-specific |
| Currency conversion | Xano | Consistent across all clients |
| Field mapping | Both | Validate in Xano, transform in Next.js for display |

### Decision 3: Where does caching live?

| Data Type | Cache Location | TTL |
|-----------|----------------|-----|
| User profile | Browser (TanStack) | 5 mins |
| Product catalog | Browser + Xano | 1 hour |
| Real-time notifications | Memory only | Don't cache |

---

## Reference Files

### [resources/data-flow-patterns.md](resources/data-flow-patterns.md)
Detailed data flow examples:
- Simple CRUD operations
- Complex workflows
- Real-time synchronization
- Optimistic updates
- Error recovery

### [resources/component-service-patterns.md](resources/component-service-patterns.md)
Component ↔ Service layer patterns:
- Query patterns (fetching data)
- Mutation patterns (changing data)
- State management integration
- Loading states
- Error boundaries

### [resources/debugging-integration.md](resources/debugging-integration.md)
Debugging guide:
- Network request inspection
- Type debugging
- State synchronization issues
- Authentication problems
- Performance optimization

### [resources/advanced-patterns.md](resources/advanced-patterns.md)
Advanced topics:
- Optimistic updates
- Batch operations
- Streaming responses
- WebSocket considerations
- Rate limiting

---

## Quick Decision Tree

**Q: Where should this logic go?**

```
Does it access the database?
├─ YES → Xano
└─ NO → Could be either

Does it check permissions?
├─ YES → Xano (security)
└─ NO → Continue

Does it need to work offline?
├─ YES → Next.js (service worker)
└─ NO → Continue

Is it UI-specific (formatting, display)?
├─ YES → Next.js
└─ NO → Xano

Is it a business rule?
├─ YES → Xano
└─ NO → Next.js
```

---

**Remember**:
- **Xano** = Single source of truth for business logic
- **Next.js** = Single source of truth for UI logic
- **Integration** = Service layer bridges the gap
- **Type Safety** = Prevents bugs at the boundary

**Skill Status**: ACTIVE ✅
**Line Count**: < 500 ✅
**Progressive Disclosure**: Reference files for detailed patterns ✅
