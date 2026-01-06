# Component ↔ Service Layer Patterns

How to structure components, service hooks, and API calls for clean separation.

## Table of Contents

1. [Service Layer Architecture](#service-layer-architecture)
2. [Query Patterns](#query-patterns)
3. [Mutation Patterns](#mutation-patterns)
4. [State Management](#state-management)
5. [Loading and Error States](#loading-and-error-states)

---

## Service Layer Architecture

### The Three-Layer Pattern

```
┌──────────────────────┐
│   React Component    │  "What do we show?"
└──────────┬───────────┘
           │ (imports hook)
           ▼
┌──────────────────────┐
│  Service Hook        │  "How do we get data?"
│  (useQuery, etc)     │
└──────────┬───────────┘
           │ (uses service)
           ▼
┌──────────────────────┐
│  API Service         │  "How do we call Xano?"
│  (xanoClient calls)  │
└──────────┬───────────┘
           │ (HTTP)
           ▼
        Xano
```

### Layer 1: API Service (lib/services/)

**Purpose**: Xano API calls, no component logic

```typescript
// lib/services/userService.ts
export async function getUser(userId: string) {
  const response = await xanoClient.get(`/users/${userId}`);
  return response.data;
}

export async function updateUser(userId: string, updates: Partial<User>) {
  const response = await xanoClient.put(`/users/${userId}`, updates);
  return response.data;
}

export async function deleteUser(userId: string) {
  await xanoClient.delete(`/users/${userId}`);
}

export async function searchUsers(query: string) {
  const response = await xanoClient.get('/users', {
    params: { search: query }
  });
  return response.data;
}
```

**Rules**:
- ✅ Pure function: input → API call → return data
- ✅ Error propagation (don't catch errors here)
- ✅ No state management
- ✅ No component imports
- ✅ Testable with simple mocking

---

### Layer 2: Service Hooks (hooks/use*)

**Purpose**: Data fetching logic with caching and state

```typescript
// hooks/useUser.ts
export function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => userService.getUser(userId),
    staleTime: 5 * 60 * 1000 // 5 minutes
  });
}

export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => userService.getUsers(),
    staleTime: 10 * 60 * 1000 // 10 minutes
  });
}

export function useUpdateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ userId, updates }: { userId: string; updates: Partial<User> }) =>
      userService.updateUser(userId, updates),
    onSuccess: (updatedUser) => {
      // Update the single user query
      queryClient.setQueryData(['user', updatedUser.id], updatedUser);
      // Invalidate users list
      queryClient.invalidateQueries({ queryKey: ['users'] });
    }
  });
}

export function useDeleteUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (userId: string) => userService.deleteUser(userId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    }
  });
}
```

**Rules**:
- ✅ Use TanStack Query for data fetching
- ✅ Configure staleTime appropriately
- ✅ Handle onSuccess/onError
- ✅ Invalidate related queries
- ✅ Return hook result unchanged (let component handle rendering)

---

### Layer 3: Components (components/ or src/features/)

**Purpose**: UI rendering only

```typescript
// components/UserProfile.tsx
export function UserProfile({ userId }: Props) {
  // Get data from hook (service layer)
  const { data: user, isLoading, error } = useUser(userId);

  // Handle states
  if (isLoading) return <UserProfileSkeleton />;
  if (error) return <ErrorDisplay error={error} />;
  if (!user) return <NotFound />;

  // Render UI
  return (
    <div className="user-profile">
      <h1>{user.name}</h1>
      <p>{user.email}</p>
      <UserActions userId={user.id} />
    </div>
  );
}

// Separate component for editing
export function UserEditModal({ userId, onClose }: Props) {
  const { data: user } = useUser(userId);
  const { mutate: updateUser, isPending } = useUpdateUser();

  const handleSubmit = (updates: Partial<User>) => {
    updateUser({ userId, updates }, {
      onSuccess: () => {
        showSuccess('User updated');
        onClose();
      }
    });
  };

  return (
    <Modal open onClose={onClose}>
      <UserForm
        initialValues={user}
        onSubmit={handleSubmit}
        isLoading={isPending}
      />
    </Modal>
  );
}
```

**Rules**:
- ✅ Only use hooks, no direct service calls
- ✅ Handle loading/error/empty states
- ✅ Focus on rendering UI
- ✅ Keep JSX clean and readable
- ✅ Extract sub-components for reusability

---

## Query Patterns

### Pattern 1: Simple Data Fetch

**Scenario**: Display user profile

```typescript
// hooks/useUser.ts
export function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => userService.getUser(userId)
  });
}

// Component.tsx
export function Profile({ userId }: Props) {
  const { data: user } = useUser(userId);
  return <div>{user?.name}</div>;
}
```

---

### Pattern 2: List with Filtering

**Scenario**: Show users with search

```typescript
// hooks/useUserSearch.ts
export function useUserSearch(query: string) {
  return useQuery({
    queryKey: ['users', 'search', query],
    queryFn: () => userService.searchUsers(query),
    enabled: query.length > 0 // Don't fetch empty searches
  });
}

// Component.tsx
export function UserSearch() {
  const [query, setQuery] = useState('');
  const { data: results } = useUserSearch(query);

  return (
    <>
      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Search users..."
      />
      <UserList users={results || []} />
    </>
  );
}
```

---

### Pattern 3: Pagination

**Scenario**: Display users with pagination

```typescript
// hooks/useUsersPaginated.ts
export function useUsersPaginated(page: number, pageSize: number = 10) {
  return useQuery({
    queryKey: ['users', 'paginated', page, pageSize],
    queryFn: () => userService.getUsersPaginated(page, pageSize)
  });
}

// Component.tsx
export function UserDirectory() {
  const [page, setPage] = useState(1);
  const { data: result } = useUsersPaginated(page);

  return (
    <>
      <UserList users={result?.users || []} />
      <Pagination
        current={page}
        total={result?.totalPages || 1}
        onChange={setPage}
      />
    </>
  );
}
```

---

### Pattern 4: Dependent Queries

**Scenario**: Load data based on other data

```typescript
// hooks/useOrderWithItems.ts
export function useOrderWithItems(orderId: string) {
  // First fetch order
  const { data: order } = useQuery({
    queryKey: ['order', orderId],
    queryFn: () => orderService.getOrder(orderId)
  });

  // Then fetch items, only if we have order
  const { data: items } = useQuery({
    queryKey: ['order-items', orderId],
    queryFn: () => orderService.getOrderItems(orderId),
    enabled: !!order // Don't fetch until order loads
  });

  return { order, items };
}

// Component.tsx
export function OrderDetail({ orderId }: Props) {
  const { order, items } = useOrderWithItems(orderId);

  return (
    <>
      <h1>Order {order?.id}</h1>
      <ItemList items={items} />
    </>
  );
}
```

---

## Mutation Patterns

### Pattern 1: Simple Create

```typescript
// hooks/useCreateUser.ts
export function useCreateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateUserRequest) => userService.createUser(data),
    onSuccess: (newUser) => {
      // Update users list
      queryClient.invalidateQueries({ queryKey: ['users'] });
      showSuccess(`Created ${newUser.name}`);
    },
    onError: (error) => {
      showError(error.message);
    }
  });
}

// Component.tsx
export function CreateUserForm() {
  const { mutate, isPending } = useCreateUser();

  return (
    <form onSubmit={(e) => {
      e.preventDefault();
      mutate(formData);
    }}>
      {/* form fields */}
      <button disabled={isPending}>Create</button>
    </form>
  );
}
```

---

### Pattern 2: Bulk Operations

```typescript
// hooks/useBulkDelete.ts
export function useBulkDeleteUsers() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (userIds: string[]) => userService.deleteUsers(userIds),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      showSuccess('Users deleted');
    }
  });
}

// Component.tsx
export function UserList() {
  const [selected, setSelected] = useState<string[]>([]);
  const { mutate: deleteSelected } = useBulkDeleteUsers();

  return (
    <>
      <button onClick={() => deleteSelected(selected)} disabled={selected.length === 0}>
        Delete Selected ({selected.length})
      </button>
      <UserTable
        onSelectionChange={setSelected}
      />
    </>
  );
}
```

---

## State Management

### When to Use TanStack Query

```
✅ Data from Xano API
✅ Shared across multiple components
✅ Needs caching and synchronization
✅ Server state (user might be updating elsewhere)
```

### When to Use Local State

```
✅ Form input while editing
✅ UI state (modal open/closed, tab selected)
✅ Optimistic values before server confirmation
✅ Temporary filters that don't affect API call
```

### Pattern: Form State Example

```typescript
export function EditUserForm({ userId }: Props) {
  // Server state from Xano
  const { data: user } = useUser(userId);
  const { mutate: save, isPending } = useUpdateUser();

  // Local state for form editing
  const [formData, setFormData] = useState<Partial<User>>({});
  const [localErrors, setLocalErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    // Initialize form when user data loads
    if (user) setFormData(user);
  }, [user]);

  const handleChange = (field: string, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Clear error for this field
    setLocalErrors(prev => ({ ...prev, [field]: '' }));
  };

  const handleSubmit = () => {
    // Frontend validation
    const errors = validateForm(formData);
    if (Object.keys(errors).length > 0) {
      setLocalErrors(errors);
      return;
    }

    // Send to Xano (which validates again)
    save({ userId, updates: formData }, {
      onSuccess: () => showSuccess('Saved')
    });
  };

  return (
    <form onSubmit={(e) => { e.preventDefault(); handleSubmit(); }}>
      {/* form fields */}
      <button disabled={isPending}>Save</button>
    </form>
  );
}
```

---

## Loading and Error States

### Pattern: Loading States

```typescript
export function useUserWithLoading(userId: string) {
  const { data, isLoading, isFetching } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => userService.getUser(userId)
  });

  return {
    user: data,
    isInitialLoading: isLoading, // First load
    isRefreshing: isFetching && !isLoading // Background refetch
  };
}

export function UserProfile({ userId }: Props) {
  const { user, isInitialLoading, isRefreshing } = useUserWithLoading(userId);

  if (isInitialLoading) return <UserSkeleton />;

  return (
    <div>
      {isRefreshing && <RefreshIndicator />}
      <h1>{user?.name}</h1>
    </div>
  );
}
```

---

### Pattern: Error Boundaries

```typescript
// hooks/useUserSafe.ts
export function useUserSafe(userId: string) {
  const query = useQuery({
    queryKey: ['user', userId],
    queryFn: () => userService.getUser(userId)
  });

  return query;
}

// Component with error boundary
export function UserProfile({ userId }: Props) {
  return (
    <ErrorBoundary>
      <UserContent userId={userId} />
    </ErrorBoundary>
  );
}

function UserContent({ userId }: Props) {
  const { data: user, error, isLoading } = useUserSafe(userId);

  if (isLoading) return <Skeleton />;
  if (error) return <ErrorDisplay error={error} />;
  if (!user) return <NotFound />;

  return <UserDetail user={user} />;
}
```

---

**Remember**: Clean separation makes code testable, maintainable, and reusable!
