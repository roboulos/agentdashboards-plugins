# Data Flow Patterns

Complete examples of how data flows between Next.js components and Xano.

## Table of Contents

1. [Simple CRUD](#simple-crud)
2. [Complex Workflows](#complex-workflows)
3. [Real-Time Synchronization](#real-time-synchronization)
4. [Optimistic Updates](#optimistic-updates)
5. [Error Recovery](#error-recovery)

---

## Simple CRUD

### Pattern: Read (GET)

**Xano**: Endpoint `/api/users/{id}`
```xano
// Returns user object
{
  "id": "123",
  "name": "John",
  "email": "john@example.com"
}
```

**Next.js**: Hook to fetch
```typescript
// hooks/useUser.ts
export function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => xanoClient.get(`/users/${userId}`)
  });
}
```

**Next.js**: Component uses hook
```typescript
export function UserProfile({ userId }: Props) {
  const { data: user, isPending, error } = useUser(userId);

  if (isPending) return <Skeleton />;
  if (error) return <ErrorDisplay error={error} />;

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}
```

**Data Flow**:
```
Component → useQuery → xanoClient → HTTP GET /users/123 → Xano
Xano → queries db → returns { id, name, email } → xanoClient
xanoClient → TanStack Query caches → useQuery hook → Component re-renders
```

---

### Pattern: Create (POST)

**Xano**: Endpoint `/api/users`
```xano
// Receives:
{
  "name": "Jane",
  "email": "jane@example.com",
  "password": "hashedPassword"
}

// Returns:
{
  "success": true,
  "data": {
    "id": "456",
    "name": "Jane",
    "email": "jane@example.com"
  }
}
```

**Next.js**: Service function
```typescript
// services/userService.ts
export async function createUser(data: CreateUserRequest) {
  const response = await xanoClient.post('/users', data);
  return response.data;
}
```

**Next.js**: Component with mutation
```typescript
export function CreateUserForm() {
  const queryClient = useQueryClient();
  const mutation = useMutation({
    mutationFn: createUser,
    onSuccess: (newUser) => {
      // Invalidate users list so it refetches
      queryClient.invalidateQueries({ queryKey: ['users'] });
      showSuccess(`Created ${newUser.name}`);
    },
    onError: (error) => {
      showError(error.message);
    }
  });

  return (
    <form onSubmit={(e) => {
      e.preventDefault();
      mutation.mutate(formData);
    }}>
      {/* form fields */}
      {mutation.isPending && <Spinner />}
    </form>
  );
}
```

**Data Flow**:
```
Form input → Component state → onSubmit → mutation.mutate(formData)
→ mutationFn calls createUser() → xanoClient.post('/users', data)
→ HTTP POST to Xano → Xano validates, saves to db → returns { id, ... }
→ onSuccess callback → invalidateQueries(['users'])
→ TanStack Query auto-refetches users list
→ useUsers() hook gets new data → component re-renders with new user
```

---

### Pattern: Update (PUT)

**Xano**: Endpoint `/api/users/{id}`
```xano
// Receives partial update
{ "name": "John Updated" }

// Returns updated object
{ "id": "123", "name": "John Updated", ... }
```

**Next.js**: Service function
```typescript
export async function updateUser(userId: string, updates: Partial<User>) {
  const response = await xanoClient.put(`/users/${userId}`, updates);
  return response.data;
}
```

**Next.js**: Component with mutation
```typescript
export function EditUserForm({ userId }: Props) {
  const { data: user } = useUser(userId);
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: (updates: Partial<User>) => updateUser(userId, updates),
    onSuccess: (updated) => {
      // Update specific query
      queryClient.setQueryData(['user', userId], updated);
      showSuccess('User updated');
    }
  });

  return (
    <form onSubmit={(e) => {
      e.preventDefault();
      mutation.mutate(changedFields);
    }}>
      {/* edit form */}
    </form>
  );
}
```

---

### Pattern: Delete (DELETE)

**Xano**: Endpoint `/api/users/{id}`
```xano
DELETE /users/123
// Returns
{ "success": true, "message": "User deleted" }
```

**Next.js**: Service function
```typescript
export async function deleteUser(userId: string) {
  await xanoClient.delete(`/users/${userId}`);
}
```

**Next.js**: Component
```typescript
export function UserActions({ userId }: Props) {
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: () => deleteUser(userId),
    onSuccess: () => {
      // Remove from all cached lists
      queryClient.invalidateQueries({ queryKey: ['users'] });
      navigate('/users');
    }
  });

  return (
    <button
      onClick={() => {
        if (confirm('Delete this user?')) {
          mutation.mutate();
        }
      }}
    >
      Delete
    </button>
  );
}
```

---

## Complex Workflows

### Pattern: Multi-Step Process

**Scenario**: User creates an order with items, which triggers:
1. Validate items in stock
2. Create order in database
3. Reduce inventory
4. Send confirmation email
5. Return order with items

**Xano**: Single endpoint handles everything
```xano
POST /api/orders
Body: {
  "items": [
    { "productId": "1", "quantity": 2 },
    { "productId": "2", "quantity": 1 }
  ]
}

Returns: {
  "orderId": "ORD-123",
  "items": [...],
  "total": 99.99,
  "status": "confirmed"
}
```

**Next.js**: Service layer abstracts complexity
```typescript
export async function createOrder(items: OrderItem[]) {
  try {
    const response = await xanoClient.post('/orders', { items });
    return {
      success: true,
      order: response.data
    };
  } catch (error) {
    return {
      success: false,
      error: error.response?.data?.message || 'Failed to create order',
      validationErrors: error.response?.data?.validation
    };
  }
}
```

**Next.js**: Component doesn't care about complexity
```typescript
export function CheckoutForm() {
  const [createOrder, { isPending }] = useMutation({
    mutationFn: createOrder,
    onSuccess: (result) => {
      if (result.success) {
        navigate(`/orders/${result.order.orderId}`);
      } else {
        showErrors(result.validationErrors);
      }
    }
  });

  return (
    <form onSubmit={() => createOrder(cartItems)}>
      <button disabled={isPending}>
        {isPending ? 'Processing...' : 'Place Order'}
      </button>
    </form>
  );
}
```

**Data Flow**:
```
User clicks "Place Order"
→ mutation.mutate(cartItems)
→ xanoClient.post('/orders', items)
→ Xano:
   - Validates items in stock
   - Creates order record
   - Updates inventory
   - Sends email
   - Returns complete order data
→ onSuccess callback
→ Navigate to confirmation page
```

---

### Pattern: Dependent Queries

**Scenario**:
1. Fetch user's account
2. Based on user.customerId, fetch orders
3. Based on first order, fetch tracking

**Xano**: Three separate endpoints
- `/api/me` → Current user
- `/api/customers/{id}/orders` → User's orders
- `/api/orders/{id}/tracking` → Tracking info

**Next.js**: Dependent hooks
```typescript
// Fetch current user
const { data: user, isPending: userLoading } = useCurrentUser();

// Only fetch orders after we have user
const { data: orders, isPending: ordersLoading } = useQuery({
  queryKey: ['orders', user?.customerId],
  queryFn: () => xanoClient.get(`/customers/${user.customerId}/orders`),
  enabled: !!user?.customerId // Don't fetch until user loaded
});

// Only fetch tracking after we have first order
const firstOrderId = orders?.[0]?.id;
const { data: tracking } = useQuery({
  queryKey: ['tracking', firstOrderId],
  queryFn: () => xanoClient.get(`/orders/${firstOrderId}/tracking`),
  enabled: !!firstOrderId
});

// Component waits for all data
export function Dashboard() {
  if (userLoading || ordersLoading) return <Skeleton />;

  return (
    <div>
      <h1>Welcome {user.name}</h1>
      <OrderList orders={orders} />
      {tracking && <TrackingInfo tracking={tracking} />}
    </div>
  );
}
```

**Data Flow**:
```
Component mounts
→ useCurrentUser() fetches /me → returns user
→ useQuery(enabled: !!user) detects user loaded
→ Fetches /customers/user.customerId/orders → returns orders
→ useQuery(enabled: !!firstOrderId) detects first order
→ Fetches /orders/firstOrderId/tracking → returns tracking
→ All queries complete → Component renders with all data
```

---

## Real-Time Synchronization

### Pattern: Polling

**Use case**: Need latest data but don't want WebSocket

**Xano**: Regular endpoint
```xano
GET /api/orders/ORD-123
Returns current order status
```

**Next.js**: Query with refetch interval
```typescript
export function useOrderStatus(orderId: string) {
  return useQuery({
    queryKey: ['order', orderId],
    queryFn: () => xanoClient.get(`/orders/${orderId}`),
    refetchInterval: 5000 // Refetch every 5 seconds
  });
}

// Component gets auto-updates
export function OrderStatus({ orderId }: Props) {
  const { data: order } = useOrderStatus(orderId);

  return (
    <div>
      <h2>Order {order.id}</h2>
      <p>Status: {order.status}</p>
      {/* Auto-updates every 5 seconds */}
    </div>
  );
}
```

---

### Pattern: Event-Based Sync

**Use case**: Need immediate updates when data changes

**Xano**: Endpoint that returns changed items
```xano
GET /api/changes?since={timestamp}
Returns items changed since last check
```

**Next.js**: Manual refetch on focus
```typescript
export function useOrderWithRefreshOnFocus(orderId: string) {
  const query = useQuery({
    queryKey: ['order', orderId],
    queryFn: () => xanoClient.get(`/orders/${orderId}`)
  });

  // Refetch when window regains focus
  useEffect(() => {
    const handleFocus = () => query.refetch();
    window.addEventListener('focus', handleFocus);
    return () => window.removeEventListener('focus', handleFocus);
  }, [query]);

  return query;
}
```

---

## Optimistic Updates

### Pattern: Show changes immediately

**Scenario**: User toggles favorite. Show immediately, rollback if fails.

```typescript
export function useToggleFavorite(productId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async () => {
      // Call Xano
      await xanoClient.post(`/products/${productId}/favorite`);
    },
    onMutate: async () => {
      // Cancel any in-flight queries
      await queryClient.cancelQueries({ queryKey: ['product', productId] });

      // Get previous data
      const previous = queryClient.getQueryData(['product', productId]);

      // Optimistically update
      queryClient.setQueryData(['product', productId], (old: any) => ({
        ...old,
        isFavorite: !old.isFavorite
      }));

      return { previous };
    },
    onError: (err, vars, context) => {
      // Rollback on error
      if (context?.previous) {
        queryClient.setQueryData(['product', productId], context.previous);
      }
      showError('Failed to update favorite');
    },
    onSuccess: () => {
      // Revalidate to get true server state
      queryClient.invalidateQueries({ queryKey: ['product', productId] });
    }
  });
}
```

**User Experience**:
```
Click favorite button
↓ (instant)
Heart icon fills (optimistic)
↓
API call to Xano
↓
Success: Confirmed (stays filled)
Error: Rollback (heart unfills) + show error message
```

---

## Error Recovery

### Pattern: Retry with exponential backoff

```typescript
export const xanoClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_XANO_URL
});

// Retry logic for failed requests
xanoClient.interceptors.response.use(null, async (error) => {
  const config = error.config;

  // Don't retry non-retryable requests
  if (!config || config.retryCount === undefined) {
    config.retryCount = 0;
  }

  config.retryCount += 1;

  // Don't retry more than 3 times
  if (config.retryCount > 3) {
    return Promise.reject(error);
  }

  // Only retry on network errors or 5xx
  if (!error.response || error.response.status >= 500) {
    // Exponential backoff: 1s, 2s, 4s
    const delay = Math.pow(2, config.retryCount - 1) * 1000;
    await new Promise(resolve => setTimeout(resolve, delay));
    return xanoClient(config);
  }

  return Promise.reject(error);
});
```

---

**Remember**: Data flows through service layers, not directly from components. This keeps everything testable and maintainable!
