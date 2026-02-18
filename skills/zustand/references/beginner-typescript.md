# Zustand Beginner TypeScript Guide

This guide covers fundamental Zustand patterns with TypeScript, from basic store creation to middleware integration and
async operations.

## Introduction

Zustand is a lightweight state manager, particularly used with React. Zustand avoids reducers, context, and boilerplate.
When combined with TypeScript, developers gain strongly-typed stores with compile-time safety and IDE autocomplete
features.

## Basic Store Creation

Define state and actions using a TypeScript type, then use the `create` function with generic type parameters to ensure
type safety:

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

Here we describe state and actions using a TypeScript type. The `create<BearState>()` syntax explicitly tells TypeScript
what shape our store has.

**Note:** The double-call syntax `create<T>()((set) => ...)` is required for TypeScript. See the Advanced TypeScript
guide for details on why this is necessary.

## Using the Store in Components

Selectors enable subscriptions to specific state properties, reducing unnecessary re-renders:

```typescript
function BearCounter() {
  const bears = useBearStore((state) => state.bears)
  return <h1>{bears} around here...</h1>
}

function Controls() {
  const increase = useBearStore((state) => state.increase)
  return <button onClick={() => increase(1)}>one up</button>
}
```

TypeScript provides autocomplete for state field access within components, preventing typos and making refactoring
safer.

## Store Reset Pattern

Create a reset function to return state to initial values:

```typescript
type State = {
  salmon: number;
  tuna: number;
};

const initialState: State = {
  salmon: 1,
  tuna: 2
};

type Actions = {
  addSalmon: (qty: number) => void;
  addTuna: (qty: number) => void;
  reset: () => void;
};

const useSlice = create<State & Actions>()((set) => ({
  ...initialState,
  addSalmon: (qty: number) => set((state) => ({ salmon: state.salmon + qty })),
  addTuna: (qty: number) => set((state) => ({ tuna: state.tuna + qty })),
  reset: () => set(initialState)
}));
```

Using `typeof initialState` (through `State`) allows dynamic type reuse, making the approach safer than manual type
definitions if the state structure changes.

## Type Extraction

Extract store types for reuse in tests, utilities, and component props without manual redefinition:

```typescript
import { create } from "zustand";
import type { ExtractState } from "zustand";

const useBearStore = create<BearState>()((set) => ({
  bears: 0,
  increase: (by) => set((state) => ({ bears: state.bears + by }))
}));

type BearState = ExtractState<typeof useBearStore>;
// BearState = { bears: number, increase: (by: number) => void }
```

`ExtractState` is a built-in Zustand helper that retrieves complete store types for reuse without manual redefinition.

## Advanced Selection

### Selecting Multiple Values

When selecting multiple values, use `useShallow` to prevent re-renders when selected values remain shallowly equal:

```typescript
import { useShallow } from "zustand/react/shallow"

type BearState = {
  bears: number
  increase: (by: number) => void
  decrease: (by: number) => void
}

const useBearStore = create<BearState>()((set) => ({
  bears: 0,
  increase: (by) => set((state) => ({ bears: state.bears + by })),
  decrease: (by) => set((state) => ({ bears: state.bears - by })),
}))

// Object pick, re-renders when ANY selected value changes
function BearControls() {
  const { increase, decrease } = useBearStore(
    useShallow((state) => ({ increase: state.increase, decrease: state.decrease }))
  )

  return (
    <>
      <button onClick={() => increase(1)}>+</button>
      <button onClick={() => decrease(1)}>-</button>
    </>
  )
}
```

Without `useShallow`, a new object is created on every render, causing unnecessary re-renders even when the values
haven't changed.

### Derived State

Compute derived state from existing properties via selectors without storing redundant values:

```typescript
type BearState = {
  bears: number
  increase: (by: number) => void
}

const useBearStore = create<BearState>()((set) => ({
  bears: 0,
  increase: (by) => set((state) => ({ bears: state.bears + by })),
}))

function BearStatus() {
  const status = useBearStore((state) =>
    state.bears > 5 ? "Many bears!" : "Few bears"
  )
  return <p>{status}</p>
}
```

This pattern keeps your store lean by computing values on-demand rather than storing them.

## Middleware

### `combine` Middleware

The `combine` middleware separates state and actions for cleaner organization with automatic type inference:

```typescript
import { create } from "zustand"
import { combine } from "zustand/middleware"

const useBearStore = create(
  combine(
    { bears: 0 }, // State
    (set) => ({
      // Actions
      increase: (by: number) => set((state) => ({ bears: state.bears + by })),
    })
  )
)

// Usage
function BearCounter() {
  const bears = useBearStore((state) => state.bears)
  const increase = useBearStore((state) => state.increase)

  return (
    <>
      <h1>{bears} bears</h1>
      <button onClick={() => increase(1)}>Add bear</button>
    </>
  )
}
```

**Key benefit:** When using `combine`, TypeScript can infer the complete type automatically, so you don't need the
explicit `create<Type>()` annotation.

### `devtools` Middleware

Enable Redux DevTools integration for debugging and time-travel functionality:

```typescript
import { create } from "zustand";
import { devtools } from "zustand/middleware";

type BearState = {
  bears: number;
  increase: (by: number) => void;
};

const useBearStore = create<BearState>()(
  devtools(
    (set) => ({
      bears: 0,
      increase: (by) => set((state) => ({ bears: state.bears + by }))
    }),
    { name: "BearStore" } // Optional: custom name in DevTools
  )
);
```

The DevTools middleware lets you:

- Inspect state changes in Redux DevTools
- Time-travel through state history
- Debug state updates with named actions

### `persist` Middleware

Maintain state in localStorage across page refreshes:

```typescript
import { create } from "zustand";
import { persist } from "zustand/middleware";

type BearState = {
  bears: number;
  increase: (by: number) => void;
};

const useBearStore = create<BearState>()(
  persist(
    (set) => ({
      bears: 0,
      increase: (by) => set((state) => ({ bears: state.bears + by }))
    }),
    {
      name: "bear-storage" // localStorage key
    }
  )
);
```

**Advanced persist options:**

```typescript
const useBearStore = create<BearState>()(
  persist(
    (set) => ({
      bears: 0,
      fish: 0,
      increase: (by) => set((state) => ({ bears: state.bears + by }))
    }),
    {
      name: "bear-storage",
      // Only persist specific fields
      partialize: (state) => ({ bears: state.bears }),
      // Use sessionStorage instead
      storage: createJSONStorage(() => sessionStorage)
    }
  )
);
```

### Combining Multiple Middlewares

Stack middlewares together (place `devtools` outermost for best type inference):

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

**Best practice:** Place `devtools` as the outermost middleware to prevent type parameter loss when other middlewares
mutate `setState`.

## Asynchronous Operations

Actions support async/await patterns for API calls, with TypeScript enforcing correct response type structures:

```typescript
type DataState = {
  data: Data[]
  isLoading: boolean
  error: Error | null
  fetch: () => Promise<void>
}

type Data = {
  id: string
  name: string
}

const useDataStore = create<DataState>()((set) => ({
  data: [],
  isLoading: false,
  error: null,
  fetch: async () => {
    set({ isLoading: true, error: null })
    try {
      const response = await fetch("https://api.example.com/data")
      const data: Data[] = await response.json()
      set({ data, isLoading: false })
    } catch (error) {
      set({ error: error as Error, isLoading: false })
    }
  },
}))

// Usage in component
function DataList() {
  const { data, isLoading, error, fetch } = useDataStore()

  React.useEffect(() => {
    fetch()
  }, [fetch])

  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error: {error.message}</div>

  return (
    <ul>
      {data.map((item) => (
        <li key={item.id}>{item.name}</li>
      ))}
    </ul>
  )
}
```

**Pattern breakdown:**

1. Set `isLoading: true` before async operation
2. Try/catch block for error handling
3. Update state with data or error
4. Set `isLoading: false` in both success and error cases

## Multiple Stores

Create domain-specific stores for better organization in larger applications:

```typescript
// stores/auth.ts
type AuthState = {
  user: User | null
  login: (user: User) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()((set) => ({
  user: null,
  login: (user) => set({ user }),
  logout: () => set({ user: null }),
}))

// stores/ui.ts
type UIState = {
  sidebarOpen: boolean
  toggleSidebar: () => void
}

export const useUIStore = create<UIState>()((set) => ({
  sidebarOpen: false,
  toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
}))

// Usage in components
function App() {
  const user = useAuthStore((state) => state.user)
  const sidebarOpen = useUIStore((state) => state.sidebarOpen)

  return (
    <div>
      {user && <p>Welcome, {user.name}</p>}
      {sidebarOpen && <Sidebar />}
    </div>
  )
}
```

**Benefits of multiple stores:**

- Separation of concerns
- Smaller, focused stores
- Easier to test and maintain
- Better code organization

## Custom Equality Functions

Use `createWithEqualityFn` for custom equality checking to optimize re-renders:

```typescript
import { createWithEqualityFn } from "zustand/traditional";
import { shallow } from "zustand/shallow";

type BearState = {
  bears: number;
  increase: (by: number) => void;
};

const useBearStore = createWithEqualityFn<BearState>()(
  (set) => ({
    bears: 0,
    increase: (by) => set((state) => ({ bears: state.bears + by }))
  }),
  shallow // Use shallow equality by default
);
```

This allows you to specify how Zustand should compare state values to determine if components should re-render.

## Best Practices Summary

**DO:**

- Use explicit type annotations: `create<State>()()`
- Select only needed values: `useStore((state) => state.value)`
- Use `useShallow` for multiple values
- Separate state and actions with `combine`
- Keep stores focused on specific domains
- Use middleware for debugging and persistence
- Handle async operations with proper loading/error states

**DON'T:**

- Don't select entire state: `const state = useStore()`
- Don't mutate state directly
- Don't forget to handle loading/error states in async operations
- Don't create one massive store for everything
- Don't use `interface` for state types (use `type` instead)

## TypeScript Tips

**Type extraction:**

```typescript
type State = ExtractState<typeof useStore>;
```

**Typed actions:**

```typescript
type Actions = {
  increment: () => void
  decrement: () => void
}
const useStore = create<State & Actions>()((set) => ...)
```

**Inferred types with combine:**

```typescript
// No explicit type needed
const useStore = create(combine({ count: 0 }, (set) => ({ ... })))
```

This guide covers the fundamental patterns for using Zustand with TypeScript. For advanced patterns like slices, custom
middleware, and vanilla stores, see the Advanced TypeScript guide.
