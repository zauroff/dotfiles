---
name: react-frontend
description:
  React and TypeScript frontend conventions. Auto-invoke when writing or
  reviewing React components, hooks, or TypeScript frontend code. TRIGGER on
  .tsx/.jsx files, React component questions, hooks, state management. SKIP for
  backend-only TypeScript or non-React frameworks.
---

# React + TypeScript Conventions

## Components

- Function components only — no class components
- Props typed with an inline type or named `Props` suffix:

```tsx
type UserCardProps = {
  user: User
  onSelect: (id: string) => void
}

function UserCard({ user, onSelect }: UserCardProps) {
  return <button onClick={() => onSelect(user.id)}>{user.name}</button>
}
```

- Export named, not default: `export function UserCard`
- One component per file. File name matches component name.
- Colocate component, styles, and tests in the same directory

## Hooks

- Custom hooks extract reusable logic: `useDebounce`, `useLocalStorage`, `useMediaQuery`
- `useMemo`/`useCallback` only when there's a measured perf problem or a stable-reference requirement (e.g., dependency of another hook)
- Prefer derived state over `useEffect` + `useState`:

```tsx
// Bad: syncing state
const [fullName, setFullName] = useState('')
useEffect(() => {
  setFullName(`${first} ${last}`)
}, [first, last])

// Good: derive it
const fullName = `${first} ${last}`
```

- `useEffect` is for synchronizing with external systems (subscriptions, DOM APIs, network). Not for transforming data.

## State Management

- Local state first (`useState`)
- Lift state up before reaching for context or libraries
- Context for low-frequency cross-cutting concerns (theme, auth, locale)
- Avoid putting frequently-changing values in context — every consumer re-renders

## TypeScript

- Prefer `type` over `interface` for props (they can't be accidentally merged)
- Use discriminated unions for complex state:

```tsx
type AsyncState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error }
```

- Avoid `any` — use `unknown` and narrow
- Generic components when the pattern repeats across types

## Performance

- Split state: components only re-render when their specific state changes
- `React.memo` only when profiling shows expensive re-renders
- Virtualize long lists (react-window, tanstack-virtual)
- Code-split routes with `React.lazy` + `Suspense`

## Patterns

- Compound components for related UI (Tabs/Tab, Select/Option)
- Render props or children-as-function for flexible composition
- Controlled components for forms — uncontrolled only when integrating with non-React code
- Error boundaries at route level and around risky third-party components

## Accessibility

- Semantic HTML first (`button`, `nav`, `main`, `article`)
- All interactive elements must be keyboard-accessible
- Images need `alt` text; decorative images get `alt=""`
- Use `aria-label` or `aria-labelledby` when visual label is absent
- Test with keyboard navigation — tab order should be logical

## File Structure

```
src/
  components/
    UserCard/
      UserCard.tsx
      UserCard.test.tsx
  hooks/
    useDebounce.ts
  pages/
    Dashboard.tsx
  types/
    user.ts
```
