# Zustand Advanced TypeScript Guide

This guide covers advanced TypeScript patterns with Zustand including type inference mechanics, slices pattern, custom
middleware development, and vanilla stores.

## Why Manual Type Annotation is Required

### Basic Usage Pattern

TypeScript requires explicit type annotation with Zustand's `create` function:

```typescript
import { create } from "zustand";

type BearState = {
  bears: number;
  increase: (by: number) => void;
};

const useBearStore = create<BearState>()((set) => ({
  bears: 0,
  increase: (by) => set((state) => ({ bears: state.bears + by }))
}));
```

Note the pattern: `create<BearState>()((set) => ...)` with the double function call.

### Understanding Type Invariance

The state generic `T` in Zustand's `create` function is **invariant**, meaning TypeScript cannot infer the type
automatically. This occurs because `T` appears in both input and output positions in the function signature, creating
ambiguity that forces manual specification.

**Why this matters:**

```typescript
// TypeScript cannot infer T here because:
// 1. T is used as input (what you pass to set)
// 2. T is used as output (what the store returns)
// 3. This bidirectional usage makes inference impossible
const useStore = create((set) => ({ ... })) // ❌ Type inference fails
```

The double-call pattern `create<T>()((set) => ...)` solves this by:

1. First call: `create<T>()` - Explicitly provides the type
2. Second call: `(set) => ...` - Implements the store with that type

### Alternative: Using `combine`

The `combine` middleware allows inference without explicit typing:

```typescript
import { create } from "zustand";
import { combine } from "zustand/middleware";

const useBearStore = create(
  combine(
    { bears: 0 }, // State (inferred as { bears: number })
    (set) => ({
      increase: (by: number) => set((state) => ({ bears: state.bears + by }))
    })
  )
);
// Type is automatically inferred: { bears: number, increase: (by: number) => void }
```

**How `combine` enables inference:**

- Separates state definition from actions
- State types are inferred from initial values
- Action types are inferred from function signatures
- No manual type annotation needed

**When to use each approach:**

✅ Use `create<T>()()` when:

- You want explicit type definitions
- Complex types need clear documentation
- Type reuse across multiple stores

✅ Use `combine` when:

- Simple stores with straightforward types
- You prefer type inference over explicit types
- Less boilerplate is desired

## Middleware Integration

### Applying Middleware

Apply middlewares directly inside `create` for contextual inference:

```typescript
import { create } from "zustand";
import { devtools, persist } from "zustand/middleware";

type BearState = {
  bears: number;
  increase: (by: number) => void;
};

const useBearStore = create<BearState>()(
  devtools(
    persist(
      (set) => ({
        bears: 0,
        increase: (by) => set((state) => ({ bears: state.bears + by }))
      }),
      { name: "bear-storage" }
    ),
    { name: "BearStore" }
  )
);
```

### Middleware Ordering

Place `devtools` as the outermost middleware to prevent type parameter loss when other middlewares mutate `setState`:

✅ **Correct order:**

```typescript
create<T>()(
  devtools(
    persist(
      (set) => ({ ... }),
      { name: "storage" }
    )
  )
)
```

❌ **Problematic order:**

```typescript
create<T>()(
  persist(
    devtools(
      (set) => ({ ... })
    ),
    { name: "storage" }
  )
)
// May lose type information in setState
```

### Common Middleware Combinations

**DevTools + Persist:**

```typescript
create<State>()(
  devtools(
    persist(
      (set) => ({ ... }),
      { name: "storage-key" }
    ),
    { name: "DevToolsName" }
  )
)
```

**Combine + DevTools + Persist:**

```typescript
create(
  devtools(
    persist(
      combine({ count: 0 }, (set) => ({
        increment: () => set((state) => ({ count: state.count + 1 }))
      })),
      { name: "storage-key" }
    )
  )
);
```

## State Extraction Patterns

### Using `ExtractState`

Extract store types outside declarations for reuse:

```typescript
import { create } from "zustand";
import type { ExtractState } from "zustand";

const useBearStore = create<BearState>()((set) => ({
  bears: 0,
  increase: (by) => set((state) => ({ bears: state.bears + by }))
}));

// Extract the complete store type
type BearState = ExtractState<typeof useBearStore>;
// Result: { bears: number, increase: (by: number) => void }
```

**Use cases:**

```typescript
// Component props
type BearCounterProps = {
  initialBears?: BearState["bears"];
};

// Helper functions
function formatBearCount(state: BearState): string {
  return `${state.bears} bears`;
}

// Testing
const mockState: BearState = {
  bears: 5,
  increase: jest.fn()
};
```

## Slices Pattern

Compose multiple state slices for organizing large stores:

### Defining Slices

```typescript
import { create, StateCreator } from "zustand";

// Fish slice
type FishSlice = {
  fishes: number;
  addFish: () => void;
};

const createFishSlice: StateCreator<BearSlice & FishSlice, [], [], FishSlice> = (set) => ({
  fishes: 0,
  addFish: () => set((state) => ({ fishes: state.fishes + 1 }))
});

// Bear slice
type BearSlice = {
  bears: number;
  addBear: () => void;
  eatFish: () => void;
};

const createBearSlice: StateCreator<BearSlice & FishSlice, [], [], BearSlice> = (set) => ({
  bears: 0,
  addBear: () => set((state) => ({ bears: state.bears + 1 })),
  eatFish: () => set((state) => ({ fishes: state.fishes - 1 }))
});

// Combine slices
const useBoundStore = create<BearSlice & FishSlice>()((...a) => ({
  ...createBearSlice(...a),
  ...createFishSlice(...a)
}));
```

**Key points:**

- Each slice defines its portion of the state
- `StateCreator` types ensure slice compatibility
- Slices can reference each other's state (e.g., `eatFish` modifies `fishes`)
- Final store combines all slices

### Slices with Middleware

Add middleware to the combined store:

```typescript
import { devtools } from "zustand/middleware";

const useBoundStore = create<BearSlice & FishSlice>()(
  devtools(
    (...a) => ({
      ...createBearSlice(...a),
      ...createFishSlice(...a)
    }),
    { name: "BoundStore" }
  )
);
```

### Benefits of Slices

✅ **Advantages:**

- Logical separation of concerns
- Easier to test individual slices
- Better code organization for large stores
- Slices can be reused across stores

**When to use slices:**

- Large stores with multiple domains
- Need to share slice logic between stores
- Team working on different features

**When to avoid slices:**

- Small, simple stores
- No logical separation of state
- Adds unnecessary complexity

## Dynamic Replace Flag Handling

Handle runtime-determined replace flags with proper typing:

```typescript
type BearState = {
  bears: number;
  increase: (by: number) => void;
};

const useBearStore = create<BearState>()((set) => ({
  bears: 0,
  increase: (by) => set((state) => ({ bears: state.bears + by }))
}));

// Type-safe dynamic setState
const replaceFlag = true; // Could be determined at runtime
const args = [{ bears: 5 }, replaceFlag] as Parameters<typeof useBearStore.setState>;

useBearStore.setState(...args);
```

**Why this matters:**

- `setState` accepts optional second parameter (replace flag)
- Runtime logic may determine whether to replace or merge
- Type assertion ensures parameter types are correct

## Custom Middleware Authoring

### Non-Mutating Middleware

Middleware that doesn't alter store structure:

```typescript
import { StateCreator, StoreMutatorIdentifier } from "zustand";

type Logger = <
  T,
  Mps extends [StoreMutatorIdentifier, unknown][] = [],
  Mcs extends [StoreMutatorIdentifier, unknown][] = []
>(
  f: StateCreator<T, Mps, Mcs>,
  name?: string
) => StateCreator<T, Mps, Mcs>;

type LoggerImpl = <T>(f: StateCreator<T, [], []>, name?: string) => StateCreator<T, [], []>;

const loggerImpl: LoggerImpl = (f, name) => (set, get, store) => {
  const loggedSet: typeof set = (...a) => {
    set(...a);
    console.log(...(name ? [`${name}:`] : []), get());
  };
  store.setState = loggedSet;

  return f(loggedSet, get, store);
};

export const logger = loggerImpl as unknown as Logger;
```

**Usage:**

```typescript
const useBearStore = create<BearState>()(
  logger(
    (set) => ({
      bears: 0,
      increase: (by) => set((state) => ({ bears: state.bears + by }))
    }),
    "BearStore"
  )
);
```

### Store-Mutating Middleware

Middleware that adds properties to the store requires `StoreMutators` module declaration:

```typescript
import { StateCreator, StoreMutatorIdentifier } from "zustand";

type Resetable = <
  T,
  Mps extends [StoreMutatorIdentifier, unknown][] = [],
  Mcs extends [StoreMutatorIdentifier, unknown][] = []
>(
  f: StateCreator<T, Mps, Mcs>
) => StateCreator<T, Mps, [["resetable", unknown], ...Mcs]>;

type ResetableImpl = <T>(f: StateCreator<T, [], []>) => StateCreator<T, [], []>;

const resetableImpl: ResetableImpl = (f) => (set, get, store) => {
  // Add reset method to store
  (store as { reset?: () => void }).reset = () => {
    const initialState = f(set, get, store);
    set(initialState, true);
  };
  return f(set, get, store);
};

export const resetable = resetableImpl as unknown as Resetable;

// Declare module augmentation
declare module "zustand" {
  interface StoreMutators<S, A> {
    resetable: Write<Cast<S, object>, { reset: () => void }>;
  }
}
```

**Important:** Module augmentation **must** use `interface` (not `type`) for TypeScript's declaration merging to work
correctly.

**Usage:**

```typescript
const useStore = create<State>()(
  resetable((set) => ({
    count: 0,
    increment: () => set((state) => ({ count: state.count + 1 }))
  }))
);

// Now store has reset method
useStore.getState().reset();
```

## Vanilla Stores

Create TypeScript-safe vanilla stores (non-React) with bounded `useStore` hooks:

```typescript
import { createStore, useStore } from "zustand"

type BearState = {
  bears: number
  increase: (by: number) => void
}

const bearStore = createStore<BearState>()((set) => ({
  bears: 0,
  increase: (by) => set((state) => ({ bears: state.bears + by })),
}))

// React integration with bounded hook
function useBearStore(): BearState
function useBearStore<T>(selector: (state: BearState) => T): T
function useBearStore<T>(selector?: (state: BearState) => T) {
  return useStore(bearStore, selector!)
}

// Usage in components
function BearCounter() {
  const bears = useBearStore((state) => state.bears)
  return <h1>{bears} bears</h1>
}

// Usage outside React
console.log(bearStore.getState().bears)
bearStore.getState().increase(1)
```

**Benefits of vanilla stores:**

- Use store outside React components
- Server-side state management
- Integration with non-React code
- More control over store lifecycle

## Middleware Mutator Reference

Each middleware carries specific mutator signatures for TypeScript:

| Middleware              | Mutator Signature                          |
| ----------------------- | ------------------------------------------ |
| `devtools`              | `["zustand/devtools", never]`              |
| `persist`               | `["zustand/persist", YourPersistedState]`  |
| `immer`                 | `["zustand/immer", never]`                 |
| `subscribeWithSelector` | `["zustand/subscribeWithSelector", never]` |
| `redux`                 | `["zustand/redux", YourAction]`            |

**Usage in middleware composition:**

```typescript
import { StateCreator } from "zustand";

type MySlice = {
  // ... your state
};

type MySliceCreator = StateCreator<MySlice, [["zustand/devtools", never], ["zustand/persist", MySlice]], [], MySlice>;
```

The mutator signatures help TypeScript understand which middlewares are applied and how they transform the store type.

## Advanced Type Patterns

### Conditional Actions Based on State

```typescript
type State = {
  mode: "read" | "write";
  data: string;
};

type Actions = {
  setMode: (mode: State["mode"]) => void;
  // Action only valid in write mode
  write: (data: string) => void;
};

const useStore = create<State & Actions>()((set, get) => ({
  mode: "read",
  data: "",
  setMode: (mode) => set({ mode }),
  write: (data) => {
    if (get().mode !== "write") {
      console.warn("Cannot write in read mode");
      return;
    }
    set({ data });
  }
}));
```

### Computed Properties with Getters

```typescript
type State = {
  firstName: string;
  lastName: string;
};

type Getters = {
  fullName: () => string;
};

type Actions = {
  setFirstName: (name: string) => void;
  setLastName: (name: string) => void;
};

const useStore = create<State & Getters & Actions>()((set, get) => ({
  firstName: "",
  lastName: "",
  fullName: () => `${get().firstName} ${get().lastName}`,
  setFirstName: (name) => set({ firstName: name }),
  setLastName: (name) => set({ lastName: name })
}));

// Usage
const fullName = useStore((state) => state.fullName());
```

### Generic Stores

Create reusable generic store factories:

```typescript
type ListState<T> = {
  items: T[];
  add: (item: T) => void;
  remove: (id: string) => void;
};

function createListStore<T extends { id: string }>() {
  return create<ListState<T>>()((set) => ({
    items: [],
    add: (item) => set((state) => ({ items: [...state.items, item] })),
    remove: (id) => set((state) => ({ items: state.items.filter((item) => item.id !== id) }))
  }));
}

// Usage
type Todo = { id: string; text: string; done: boolean };
const useTodoStore = createListStore<Todo>();

type User = { id: string; name: string; email: string };
const useUserStore = createListStore<User>();
```

## Best Practices Summary

✅ **DO:**

- Use explicit type annotation: `create<T>()()`
- Place `devtools` as outermost middleware
- Use `combine` for simpler type inference
- Use slices pattern for large stores
- Extract types with `ExtractState` for reuse
- Use `StateCreator` for slice typing
- Use vanilla stores for non-React code

❌ **DON'T:**

- Don't forget the double-call pattern: `create<T>()()`
- Don't place `devtools` inside other middlewares
- Don't use `interface` for state types (use `type` instead)
  - **Exception:** Module augmentation must use `interface`
- Don't create overly complex generic stores unnecessarily
- Don't mutate state in middleware unless intentional

## Troubleshooting

**Type inference not working:**

```typescript
// ❌ Missing explicit type
const useStore = create((set) => ({ count: 0 }))

// ✅ Add explicit type
const useStore = create<State>()((set) => ({ count: 0 }))

// ✅ Or use combine
const useStore = create(combine({ count: 0 }, (set) => ({ ... })))
```

**Middleware type errors:**

```typescript
// ❌ Wrong middleware order
create<T>()(persist(devtools(...)))

// ✅ Correct middleware order
create<T>()(devtools(persist(...)))
```

**Slice type errors:**

```typescript
// ❌ Incomplete StateCreator types
const createSlice: StateCreator<MySlice> = (set) => ({ ... })

// ✅ Complete StateCreator types
const createSlice: StateCreator<
  BearSlice & FishSlice,
  [],
  [],
  MySlice
> = (set) => ({ ... })
```

This guide covers advanced TypeScript patterns with Zustand. These techniques enable type-safe, scalable state
management for complex applications.
