# Zustand Testing Guide

## Overview

Testing Zustand stores requires proper setup to isolate state between tests. The recommended approach uses automatic
store reset via mocking, with support for both unit tests (testing stores directly) and integration tests (testing
components using stores).

## Generic Testing Principles

1. **State Isolation**: Reset all stores between tests to prevent state leakage
2. **Testing Library**: Use React Testing Library (RTL) for UI component testing
3. **Mock Network Requests**: Use Mock Service Worker (MSW) for API calls
4. **Test from User Perspective**: Focus on behavior, not implementation details
5. **TypeScript Support**: Ensure proper TypeScript configuration for type safety

## Vitest Setup

### 1. Mock File (`__mocks__/zustand.ts`)

Create a mock that wraps Zustand's `create` and `createStore` functions to track and reset store state:

```ts
import { act } from "@testing-library/react";
import type * as ZustandExportedTypes from "zustand";
export * from "zustand";

const { create: actualCreate, createStore: actualCreateStore } =
  await vi.importActual<typeof ZustandExportedTypes>("zustand");

export const storeResetFns = new Set<() => void>();

const createUncurried = <T>(stateCreator: ZustandExportedTypes.StateCreator<T>) => {
  const store = actualCreate(stateCreator);
  const initialState = store.getInitialState();
  storeResetFns.add(() => {
    store.setState(initialState, true);
  });
  return store;
};

export const create = (<T>(stateCreator: ZustandExportedTypes.StateCreator<T>) => {
  console.log("zustand create mock");
  return typeof stateCreator === "function" ? createUncurried(stateCreator) : createUncurried;
}) as typeof ZustandExportedTypes.create;

const createStoreUncurried = <T>(stateCreator: ZustandExportedTypes.StateCreator<T>) => {
  const store = actualCreateStore(stateCreator);
  const initialState = store.getInitialState();
  storeResetFns.add(() => {
    store.setState(initialState, true);
  });
  return store;
};

export const createStore = (<T>(stateCreator: ZustandExportedTypes.StateCreator<T>) => {
  console.log("zustand createStore mock");
  return typeof stateCreator === "function" ? createStoreUncurried(stateCreator) : createStoreUncurried;
}) as typeof ZustandExportedTypes.createStore;

afterEach(() => {
  act(() => {
    storeResetFns.forEach((resetFn) => {
      resetFn();
    });
  });
});
```

**Important**: Place `__mocks__` in the correct location relative to your root. If your root is `./src`, place mocks in
`./src/__mocks__/`.

### 2. Setup File (`setup-vitest.ts`)

```ts
import "@testing-library/jest-dom";
vi.mock("zustand");
```

**Critical**: You must call `vi.mock('zustand')` to enable automatic mocking. Without this, modules are not mocked.

### 3. Vitest Config (`vitest.config.ts`)

```ts
import { defineConfig, mergeConfig } from "vitest/config";
import viteConfig from "./vite.config";

export default defineConfig((configEnv) =>
  mergeConfig(
    viteConfig(configEnv),
    defineConfig({
      test: {
        globals: true,
        environment: "jsdom",
        setupFiles: ["./setup-vitest.ts"]
      }
    })
  )
);
```

### 4. TypeScript Types (`global.d.ts`)

```ts
/// <reference types="vite/client" />
/// <reference types="vitest/globals" />
```

## How State Reset Works

The mock automatically:

1. **Captures Initial State**: Stores the initial state when a store is created
2. **Tracks Reset Functions**: Collects reset functions in a Set as stores are created
3. **Resets After Each Test**: The `afterEach()` hook resets all tracked stores to their initial state
4. **Uses act()**: Wraps state resets with React's `act()` to maintain test stability

This automatic approach eliminates manual reset logic and prevents test pollution.

## Testing Patterns

### Direct Store Testing

Test store behavior independently without rendering components:

```ts
import { useCounterStore } from "../stores/use-counter-store";

describe("Counter Store", () => {
  test("should have initial state of 1", () => {
    expect(useCounterStore.getState().count).toBe(1);
  });

  test("should increment count", () => {
    useCounterStore.getState().inc();
    expect(useCounterStore.getState().count).toBe(2);
  });
});
```

### Component Testing

Test components connected to Zustand stores:

```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Counter } from "./counter";

describe("Counter Component", () => {
  test("should render with initial state", async () => {
    render(<Counter />);
    expect(await screen.findByText(/^1$/)).toBeInTheDocument();
  });

  test("should increment count on button click", async () => {
    const user = userEvent.setup();
    render(<Counter />);

    await user.click(await screen.findByRole("button", { name: /one up/i }));
    expect(await screen.findByText(/^2$/)).toBeInTheDocument();
  });
});
```

## Best Practices

### 1. Automatic State Reset (Preferred)

Use the mock setup above for automatic reset between tests. No manual cleanup needed.

```ts
// ✅ Good: State automatically resets after each test
test("first test", () => {
  useStore.getState().increment();
  expect(useStore.getState().count).toBe(1);
});

test("second test", () => {
  // Store is automatically reset to initial state
  expect(useStore.getState().count).toBe(0);
});
```

### 2. Test from User Perspective

Use React Testing Library for UI tests:

```ts
// ✅ Good: Tests user behavior, not implementation
test("user can increment counter", async () => {
  const user = userEvent.setup()
  render(<Counter />)

  await user.click(screen.getByRole("button", { name: /increment/i }))
  expect(screen.getByText(/count: 1/i)).toBeInTheDocument()
})
```

### 3. Mock External Dependencies

Use Mock Service Worker for API calls:

```ts
// ✅ Good: Mock network requests, not store logic
server.use(
  http.get("/api/data", () => {
    return HttpResponse.json({ data: "test" });
  })
);
```

### 4. Avoid Implementation Details

```ts
// ❌ Bad: Testing internal selectors
test("counter selector", () => {
  const selector = useCounterStore((state) => state.count)
})

// ✅ Good: Test store state directly or through UI
test("counter displays", () => {
  render(<Counter />)
  expect(screen.getByText(/1/)).toBeInTheDocument()
})
```

## Troubleshooting

### Issue: Store state persists between tests

**Solution**: Ensure `vi.mock('zustand')` is called in `setup-vitest.ts` and `__mocks__/zustand.ts` is in the correct
location.

### Issue: **mocks** directory not found

**Solution**: In Vitest, mocks must be in the correct location relative to your configured root. If root is `./src`, use
`./src/__mocks__/`.

### Issue: State resets don't work

**Solution**: Verify that `afterEach()` is running. Check that the mock file exports the `storeResetFns` Set and that
all stores are created with the mocked `create()` function.
