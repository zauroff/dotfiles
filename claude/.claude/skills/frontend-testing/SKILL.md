---
name: frontend-testing
description:
  Frontend testing patterns with Vitest and React Testing Library. Auto-invoke
  when writing or reviewing frontend tests. TRIGGER on .test.tsx/.test.ts files,
  testing-library usage, Vitest/Jest test files. SKIP for backend tests or
  non-JS test files.
---

# Frontend Testing (Vitest + React Testing Library)

## Philosophy

- Test behavior the user sees, not implementation details
- Query by accessible role/label, not by class name or test-id
- Use `userEvent` over `fireEvent` — it simulates real browser interactions

## Query Priority

Use in this order (most accessible first):

1. `getByRole('button', { name: /submit/i })` — accessible role + name
2. `getByLabelText(/email/i)` — form fields with labels
3. `getByPlaceholderText` — when no label exists
4. `getByText(/welcome/i)` — visible text content
5. `getByTestId` — last resort only

## Basic Component Test

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { UserCard } from './UserCard'

test('calls onSelect when clicked', async () => {
  const user = userEvent.setup()
  const onSelect = vi.fn()

  render(<UserCard user={{ id: '1', name: 'Alice' }} onSelect={onSelect} />)

  await user.click(screen.getByRole('button', { name: /alice/i }))

  expect(onSelect).toHaveBeenCalledWith('1')
})
```

## Async Patterns

- Use `findBy*` (returns promise) for elements that appear after async work
- Use `waitFor` for assertions that need to poll:

```tsx
await waitFor(() => {
  expect(screen.getByText(/success/i)).toBeInTheDocument()
})
```

- Use `waitForElementToBeRemoved` for loading states:

```tsx
render(<Dashboard />)
await waitForElementToBeRemoved(screen.getByText(/loading/i))
expect(screen.getByRole('table')).toBeInTheDocument()
```

## Mocking

- Mock at the network level with MSW (Mock Service Worker), not at the fetch/axios level
- Mock modules sparingly — prefer integration over isolation:

```tsx
// Mock a hook when testing a component that uses it
vi.mock('../hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: '1', name: 'Test' }, isLoggedIn: true }),
}))
```

## Testing Hooks

Use `renderHook` for custom hooks:

```tsx
import { renderHook, act } from '@testing-library/react'
import { useCounter } from './useCounter'

test('increments counter', () => {
  const { result } = renderHook(() => useCounter())

  act(() => result.current.increment())

  expect(result.current.count).toBe(1)
})
```

## Test Structure

- Group related tests with `describe`
- Test name reads as a sentence: `it('shows error when email is invalid')`
- Arrange / Act / Assert — keep them visually separate
- One behavior per test — split multiple assertions into separate tests when they test different things

## What NOT to Test

- Implementation details (state variables, internal methods)
- Third-party library behavior
- Exact CSS classes or styles (test visual outcome, not mechanism)
- That React works (e.g., don't test that setState updates state)

## Coverage Strategy

- Cover user flows: happy path, error states, empty states, loading states
- Cover edge cases: boundary values, empty inputs, very long strings
- Skip: trivial components (pure wrappers, style-only), generated code
