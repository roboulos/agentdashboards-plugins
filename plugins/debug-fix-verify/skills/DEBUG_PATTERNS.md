# Debug Logging Patterns

Library of proven debug logging patterns for different scenarios.

---

## Table of Contents

1. [Function Entry/Exit Patterns](#function-entryexit-patterns)
2. [Conditional Logic Patterns](#conditional-logic-patterns)
3. [Data Transformation Patterns](#data-transformation-patterns)
4. [Error Handling Patterns](#error-handling-patterns)
5. [Integration Point Patterns](#integration-point-patterns)
6. [Loop and Iteration Patterns](#loop-and-iteration-patterns)
7. [State Management Patterns](#state-management-patterns)
8. [Performance Debugging Patterns](#performance-debugging-patterns)

---

## Function Entry/Exit Patterns

### Basic Entry Log

```typescript
export async function handler(params: any, context: any) {
  console.log('[HandlerName] === FUNCTION ENTRY ===');
  console.log('[HandlerName] Params:', JSON.stringify(params, null, 2));
  console.log('[HandlerName] Context:', {
    authenticated: context.authenticated,
    userId: context.userId,
    timestamp: new Date().toISOString()
  });

  // function logic
}
```

### Entry with Type Validation

```typescript
export async function handler(params: any, context: any) {
  console.log('[HandlerName] Entry - Type checking params');
  console.log('[HandlerName] params type:', typeof params);
  console.log('[HandlerName] params is array?', Array.isArray(params));
  console.log('[HandlerName] params keys:', Object.keys(params || {}));

  // function logic
}
```

### Exit Log

```typescript
export async function handler(params: any, context: any) {
  // function logic

  const result = await someOperation();

  console.log('[HandlerName] === FUNCTION EXIT ===');
  console.log('[HandlerName] Returning:', JSON.stringify(result, null, 2));
  console.log('[HandlerName] Return type:', typeof result);
  console.log('[HandlerName] Success:', !result.error);

  return result;
}
```

### Entry/Exit with Timing

```typescript
export async function handler(params: any, context: any) {
  const startTime = Date.now();
  console.log('[HandlerName] Start time:', startTime);

  // function logic

  const endTime = Date.now();
  console.log('[HandlerName] End time:', endTime);
  console.log('[HandlerName] Duration:', endTime - startTime, 'ms');

  return result;
}
```

---

## Conditional Logic Patterns

### Simple If/Else

```typescript
console.log('[Handler] Checking condition:', { value, expected });

if (value === expected) {
  console.log('[Handler] ✓ CONDITION TRUE - Taking IF branch');
  // if logic
} else {
  console.log('[Handler] ✗ CONDITION FALSE - Taking ELSE branch');
  // else logic
}

console.log('[Handler] After conditional block');
```

### Multiple Conditions

```typescript
console.log('[Handler] Evaluating multiple conditions:', {
  condition1: condition1,
  condition2: condition2,
  condition3: condition3
});

if (condition1) {
  console.log('[Handler] Branch 1: condition1 = true');
} else if (condition2) {
  console.log('[Handler] Branch 2: condition2 = true');
} else if (condition3) {
  console.log('[Handler] Branch 3: condition3 = true');
} else {
  console.log('[Handler] Branch 4: all conditions false');
}
```

### Complex Boolean Logic

```typescript
const check1 = value > 10;
const check2 = status === 'active';
const check3 = hasPermission;

console.log('[Handler] Boolean checks:', {
  check1: check1,
  check2: check2,
  check3: check3
});

const finalCondition = check1 && check2 && check3;
console.log('[Handler] Final condition (AND):', finalCondition);

if (finalCondition) {
  console.log('[Handler] All conditions met');
} else {
  console.log('[Handler] At least one condition failed');
  console.log('[Handler] Failed checks:', {
    check1Failed: !check1,
    check2Failed: !check2,
    check3Failed: !check3
  });
}
```

### Switch Statement

```typescript
console.log('[Handler] Switch on value:', value);

switch (value) {
  case 'option1':
    console.log('[Handler] Case: option1');
    break;
  case 'option2':
    console.log('[Handler] Case: option2');
    break;
  default:
    console.log('[Handler] Case: default (value =', value, ')');
}

console.log('[Handler] After switch');
```

### Ternary with Logging

```typescript
console.log('[Handler] Ternary evaluation:', { condition, ifTrue, ifFalse });

const result = condition
  ? (console.log('[Handler] Ternary: TRUE path'), ifTrue)
  : (console.log('[Handler] Ternary: FALSE path'), ifFalse);

console.log('[Handler] Ternary result:', result);
```

---

## Data Transformation Patterns

### Object Mapping

```typescript
console.log('[Transform] Input data:', inputData);

const mapped = inputData.map((item, index) => {
  console.log(`[Transform] Processing item ${index}:`, item);

  const transformed = {
    id: item.id,
    name: item.name?.toUpperCase()
  };

  console.log(`[Transform] Item ${index} transformed:`, transformed);
  return transformed;
});

console.log('[Transform] Final mapped result:', mapped);
```

### Array Filtering

```typescript
console.log('[Filter] Input array length:', data.length);
console.log('[Filter] Filter criteria:', criteria);

const filtered = data.filter((item, index) => {
  const passes = item.status === criteria;
  console.log(`[Filter] Item ${index}:`, { item, passes });
  return passes;
});

console.log('[Filter] Filtered array length:', filtered.length);
console.log('[Filter] Items removed:', data.length - filtered.length);
```

### Data Reduction

```typescript
console.log('[Reduce] Input array:', array);
console.log('[Reduce] Initial value:', initialValue);

const result = array.reduce((acc, item, index) => {
  console.log(`[Reduce] Step ${index}:`, {
    accumulator: acc,
    currentItem: item,
    newAccumulator: acc + item
  });
  return acc + item;
}, initialValue);

console.log('[Reduce] Final result:', result);
```

### Object Destructuring

```typescript
console.log('[Destructure] Input object:', inputObj);

const { field1, field2, nested: { deepField } } = inputObj;

console.log('[Destructure] Extracted values:', {
  field1,
  field2,
  deepField
});

console.log('[Destructure] Missing fields:', {
  field1Missing: field1 === undefined,
  field2Missing: field2 === undefined,
  deepFieldMissing: deepField === undefined
});
```

### Type Conversion

```typescript
console.log('[Convert] Original value:', value);
console.log('[Convert] Original type:', typeof value);

const converted = String(value);

console.log('[Convert] Converted value:', converted);
console.log('[Convert] Converted type:', typeof converted);
console.log('[Convert] Conversion successful:', typeof converted === 'string');
```

---

## Error Handling Patterns

### Try/Catch Block

```typescript
console.log('[ErrorHandle] Attempting risky operation');

try {
  console.log('[ErrorHandle] Inside try block');
  const result = await riskyOperation();
  console.log('[ErrorHandle] Operation succeeded:', result);
  return result;
} catch (error: any) {
  console.log('[ErrorHandle] ❌ ERROR CAUGHT');
  console.log('[ErrorHandle] Error message:', error.message);
  console.log('[ErrorHandle] Error stack:', error.stack);
  console.log('[ErrorHandle] Error details:', {
    name: error.name,
    cause: error.cause,
    context: { params, state }
  });
  throw error;
}
```

### Error with Fallback

```typescript
try {
  console.log('[Handler] Primary operation');
  result = await primaryOperation();
  console.log('[Handler] Primary succeeded');
} catch (error) {
  console.log('[Handler] Primary failed, trying fallback');
  console.log('[Handler] Primary error:', error.message);

  try {
    result = await fallbackOperation();
    console.log('[Handler] Fallback succeeded');
  } catch (fallbackError) {
    console.log('[Handler] Fallback also failed:', fallbackError.message);
    throw fallbackError;
  }
}
```

### Validation Errors

```typescript
console.log('[Validate] Validating input:', input);

const errors: string[] = [];

if (!input.field1) {
  console.log('[Validate] ✗ field1 missing');
  errors.push('field1 required');
} else {
  console.log('[Validate] ✓ field1 present:', input.field1);
}

if (input.field2 < 0) {
  console.log('[Validate] ✗ field2 negative:', input.field2);
  errors.push('field2 must be positive');
} else {
  console.log('[Validate] ✓ field2 valid:', input.field2);
}

console.log('[Validate] Validation errors:', errors);

if (errors.length > 0) {
  console.log('[Validate] Validation FAILED');
  throw new Error(`Validation failed: ${errors.join(', ')}`);
}

console.log('[Validate] Validation PASSED');
```

---

## Integration Point Patterns

### API Request/Response

```typescript
console.log('[API] Preparing request');
console.log('[API] Endpoint:', endpoint);
console.log('[API] Method:', method);
console.log('[API] Headers:', headers);
console.log('[API] Body:', JSON.stringify(body, null, 2));

console.log('[API] Sending request...');
const response = await fetch(endpoint, { method, headers, body });

console.log('[API] Response received');
console.log('[API] Status:', response.status);
console.log('[API] Status text:', response.statusText);
console.log('[API] Headers:', Object.fromEntries(response.headers.entries()));

const data = await response.json();
console.log('[API] Response data:', JSON.stringify(data, null, 2));

if (!response.ok) {
  console.log('[API] ❌ Request failed');
  throw new Error(`API error: ${response.status}`);
}

console.log('[API] ✓ Request successful');
```

### Database Query

```typescript
console.log('[DB] Executing query');
console.log('[DB] Query:', query);
console.log('[DB] Params:', params);

const startTime = Date.now();
const result = await db.query(query, params);
const duration = Date.now() - startTime;

console.log('[DB] Query completed in', duration, 'ms');
console.log('[DB] Rows affected:', result.rowCount);
console.log('[DB] Result:', JSON.stringify(result.rows, null, 2));
```

### External Service Call

```typescript
console.log('[Service] Calling external service:', serviceName);
console.log('[Service] Input:', input);

try {
  const result = await externalService.call(input);
  console.log('[Service] Success');
  console.log('[Service] Result:', result);
  return result;
} catch (error: any) {
  console.log('[Service] ❌ Failed');
  console.log('[Service] Error:', error.message);

  // Check for specific error types
  if (error.code === 'TIMEOUT') {
    console.log('[Service] Error type: TIMEOUT');
  } else if (error.code === 'AUTH') {
    console.log('[Service] Error type: AUTHENTICATION');
  } else {
    console.log('[Service] Error type: UNKNOWN');
  }

  throw error;
}
```

---

## Loop and Iteration Patterns

### For Loop

```typescript
console.log('[Loop] Starting for loop, items:', items.length);

for (let i = 0; i < items.length; i++) {
  console.log(`[Loop] Iteration ${i}/${items.length - 1}`);
  console.log(`[Loop] Item ${i}:`, items[i]);

  // process item
  const result = processItem(items[i]);
  console.log(`[Loop] Item ${i} result:`, result);
}

console.log('[Loop] For loop completed');
```

### While Loop

```typescript
console.log('[While] Starting while loop');
let iteration = 0;

while (condition) {
  console.log(`[While] Iteration ${iteration}`, { condition });

  // loop logic

  iteration++;
  console.log(`[While] After iteration ${iteration}, condition now:`, condition);

  if (iteration > 100) {
    console.log('[While] ⚠️ Safety break - too many iterations');
    break;
  }
}

console.log('[While] While loop completed after', iteration, 'iterations');
```

### Async Iteration

```typescript
console.log('[AsyncLoop] Processing items asynchronously');

for (const item of items) {
  console.log('[AsyncLoop] Starting:', item.id);

  try {
    await processAsync(item);
    console.log('[AsyncLoop] ✓ Completed:', item.id);
  } catch (error) {
    console.log('[AsyncLoop] ✗ Failed:', item.id, error.message);
  }
}

console.log('[AsyncLoop] All items processed');
```

---

## State Management Patterns

### State Updates

```typescript
console.log('[State] Current state:', currentState);
console.log('[State] Update action:', action);

const newState = {
  ...currentState,
  [action.field]: action.value
};

console.log('[State] New state:', newState);
console.log('[State] Changed fields:', {
  field: action.field,
  oldValue: currentState[action.field],
  newValue: newState[action.field]
});
```

### State Transitions

```typescript
console.log('[Transition] Current:', currentState);
console.log('[Transition] Event:', event);

let newState;

switch (event.type) {
  case 'START':
    newState = 'in_progress';
    console.log('[Transition] START -> in_progress');
    break;
  case 'COMPLETE':
    newState = 'completed';
    console.log('[Transition] COMPLETE -> completed');
    break;
  default:
    newState = currentState;
    console.log('[Transition] Unknown event, staying in:', currentState);
}

console.log('[Transition] Final state:', newState);
```

---

## Performance Debugging Patterns

### Operation Timing

```typescript
const opStart = Date.now();
console.log('[Perf] Operation start:', opStart);

await operation();

const opEnd = Date.now();
const duration = opEnd - opStart;

console.log('[Perf] Operation end:', opEnd);
console.log('[Perf] Duration:', duration, 'ms');

if (duration > 1000) {
  console.log('[Perf] ⚠️ Slow operation (>1s)');
}
```

### Memory Usage

```typescript
const memBefore = process.memoryUsage();
console.log('[Memory] Before:', {
  heapUsed: Math.round(memBefore.heapUsed / 1024 / 1024) + 'MB',
  external: Math.round(memBefore.external / 1024 / 1024) + 'MB'
});

await operation();

const memAfter = process.memoryUsage();
console.log('[Memory] After:', {
  heapUsed: Math.round(memAfter.heapUsed / 1024 / 1024) + 'MB',
  external: Math.round(memAfter.external / 1024 / 1024) + 'MB'
});

console.log('[Memory] Delta:', {
  heapUsed: Math.round((memAfter.heapUsed - memBefore.heapUsed) / 1024 / 1024) + 'MB'
});
```

### Batching Optimization

```typescript
console.log('[Batch] Items to process:', items.length);
const batchSize = 10;
console.log('[Batch] Batch size:', batchSize);

for (let i = 0; i < items.length; i += batchSize) {
  const batch = items.slice(i, i + batchSize);
  console.log(`[Batch] Processing batch ${Math.floor(i/batchSize) + 1}:`, {
    from: i,
    to: i + batch.length,
    size: batch.length
  });

  const batchStart = Date.now();
  await processBatch(batch);
  const batchDuration = Date.now() - batchStart;

  console.log(`[Batch] Batch completed in ${batchDuration}ms`);
}
```

---

## General Best Practices

1. **Prefix with context:** `[FunctionName]` or `[Component]`
2. **Structure your logs:** Use objects for complex data
3. **Log both paths:** If and else branches
4. **Number steps:** For complex flows
5. **Include types:** Log `typeof` and `Array.isArray()`
6. **Timestamp critical events:** Use `Date.now()` or `new Date().toISOString()`
7. **JSON.stringify objects:** Makes nested data readable
8. **Log errors completely:** Message, stack, context
9. **Mark outcomes:** Use ✓, ✗, ⚠️ for visual scanning
10. **Remove when done:** Debug logs are temporary
