---
name: zustand
description: This skill should be used when the user asks to "create a Zustand store", "add Zustand", "manage global state with Zustand", "use Zustand with TypeScript", "add state management", or mentions Zustand stores, selectors, or middleware. Provides TypeScript-first state management guidance for Next.js projects.
---

# Zustand State Management

## Your Role

You are an expert in Zustand state management with TypeScript in Next.js projects. You understand Zustand's lightweight
approach to state management, TypeScript integration patterns, middleware composition, and Next.js-specific
considerations for Server and Client Components.

## Overview

Zustand is a lightweight state management library for React that avoids reducers, context, and boilerplate. It provides
a simple API based on hooks, making it ideal for managing global and local state in Next.js applications.

**When to use Zustand:**

- Global UI state (modals, sidebars, theme preferences)
- Shared application state across multiple components
- Complex state logic that doesn't belong in individual components
- State that needs to persist across navigation

**When to use React state instead:**

- Simple local component state
- Form state confined to a single component
- State that doesn't need to be shared

## Quick Start

Create a type-safe store with TypeScript:

```typescript
"use client";

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

Use in components:

```typescript
function BearCounter() {
  const bears = useBearStore((state) => state.bears)
  return <h1>{bears} bears</h1>
}

function Controls() {
  const increase = useBearStore((state) => state.increase)
  return <button onClick={() => increase(1)}>Add bear</button>
}
```

## Project Integration

### Store Location

Place stores based on scope:

**Shared across all apps (monorepo):**

```
packages/shared/stores/
└── theme.ts
```

**App-specific stores:**

```
apps/web/stores/
└── user.ts
```

**Single project:**

```
src/stores/
└── user.ts
```

### Client Component Requirement

Zustand hooks **must** be used in Client Components. Add `"use client"` directive:

```typescript
"use client"

import { useUserStore } from "@/stores/user"

export function UserButton() {
  const name = useUserStore((state) => state.name)
  return <button>{name}</button>
}
```

### Server Components

Do **not** use Zustand in Server Components. For server-side state:

- Use `async/await` to fetch data directly
- Pass data via props to Client Components
- Use URL search params for shareable state

## Core Concepts

### Store Creation with TypeScript

Always use explicit type annotation with the double-call pattern `create<T>()((set) => ...)`. TypeScript cannot infer
the type automatically because the state generic is invariant.

### TypeScript Convention: Use `type`

Define state using `type` (not `interface`) per project conventions:

**DO:**

```typescript
type UserState = {
  user: User | null;
  login: (user: User) => void;
  logout: () => void;
};
```

**DON'T:**

```typescript
interface UserState {
  user: User | null;
  login: (user: User) => void;
  logout: () => void;
}
```

**Exception:** Module augmentation requires `interface`:

```typescript
declare module "zustand" {
  interface StoreMutators {
    // Must use interface for module augmentation with Zustand
  }
}
```

### Selectors

Select only what you need to minimize re-renders. Use `useShallow` when selecting multiple values to prevent unnecessary
re-renders when objects are shallowly equal.

**See `./references/BEGINNER_TYPESCRIPT.md`** for detailed selector patterns and `useShallow` usage.

### State Updates

Zustand supports partial updates `set({ key: value })`, functional updates `set((state) => ({ ... }))`, and full
replacement `set(state, true)`.

## Common Patterns

Zustand excels at:

- **Global UI state** - Modals, sidebars, theme preferences
- **Async actions** - API calls with loading/error states
- **Store reset** - Return to initial state
- **Multiple stores** - Domain-specific state separation

**See `./references/BEGINNER_TYPESCRIPT.md`** for complete pattern implementations with code examples.

## Middleware

Zustand provides middleware for enhanced functionality:

- **`combine`** - Automatic type inference by separating state and actions
- **`devtools`** - Redux DevTools integration for debugging
- **`persist`** - localStorage/sessionStorage persistence

Middleware can be stacked together. Place `devtools` as the outermost middleware for best type inference.

**See `./references/BEGINNER_TYPESCRIPT.md`** for detailed middleware usage, configuration options, and composition
patterns.

## Best Practices

### DO

- Use explicit type annotation: `create<State>()((set) => ...)`
- Select only what you need: `useStore((state) => state.value)`
- Use `useShallow` for multiple values
- Keep stores focused on specific domains
- Use `combine` for automatic type inference
- Add `"use client"` directive in Client Components

### DON'T

- Don't use Zustand in Server Components
- Don't select entire state: `const state = useStore()`
- Don't use `interface` for state types (use `type` instead)
- Don't mutate state directly (use immutable updates)
- Don't forget the double-call pattern: `create<T>()()`

### Testing

For testing Zustand stores, consult `./references/TESTING.md` for complete Vitest setup, automatic state reset
configuration, and testing patterns.

## React 19 Compatibility

Zustand is fully compatible with React 19. No special configuration needed for Next.js 15+ / React 19 setups.

## Additional Resources

For detailed implementations and advanced patterns, consult the reference files:

**`./references/BEGINNER_TYPESCRIPT.md`**

- Complete pattern implementations with code examples
- Middleware configuration (`combine`, `devtools`, `persist`)
- Type extraction, selectors, async operations
- Multiple stores organization

**`./references/ADVANCED_TYPESCRIPT.md`**

- Type inference mechanics and why `create<T>()()` is required
- Slices pattern for large stores
- Custom middleware authoring
- Vanilla stores (non-React usage)
- Store mutators and advanced TypeScript patterns

**`./references/TESTING.md`**

- Testing Zustand stores with Vitest
- Automatic state reset setup
- Component and store testing patterns
- Best practices and troubleshooting

## Quick Reference

**Create store:**

```typescript
const useStore = create<State>()((set) => ({ ... }))
```

**Use in component:**

```typescript
"use client";
const value = useStore((state) => state.value);
```

**Update state:**

```typescript
set({ key: value })                    // Partial
set((state) => ({ ... }))              // Functional
set({ key: value }, true)              // Replace
```

**Multiple values:**

```typescript
useShallow((state) => ({ a: state.a, b: state.b }));
```

**With middleware:**

```typescript
create<State>()(devtools(persist((set) => ({ ... }))))
```
