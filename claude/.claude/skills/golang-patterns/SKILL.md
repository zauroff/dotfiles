---
name: golang-patterns
description:
  Idiomatic Go patterns and best practices. Auto-invoke when writing or
  reviewing Go code. TRIGGER on .go files, Go architecture decisions, or when
  the user asks about Go idioms. SKIP for non-Go languages.
---

# Go Patterns

## Error Handling

- Always wrap errors with context: `fmt.Errorf("doing X: %w", err)`
- Define sentinel errors as package-level vars: `var ErrNotFound = errors.New("not found")`
- Use `errors.Is` and `errors.As` for checking — never compare strings
- Custom error types implement `Error() string` and optionally `Unwrap() error`
- Return early on error — avoid nested else branches

```go
if err := doThing(); err != nil {
    return fmt.Errorf("doing thing: %w", err)
}
```

## Concurrency

- Start goroutines only when you know how they'll stop
- Use `errgroup.Group` for fan-out with error collection
- Pass `context.Context` as the first parameter, never store it in a struct
- Use channels for communication, mutexes for state protection
- Prefer `sync.Once` over manual flags for one-time init

```go
g, ctx := errgroup.WithContext(ctx)
for _, item := range items {
    g.Go(func() error {
        return process(ctx, item)
    })
}
if err := g.Wait(); err != nil {
    return err
}
```

## Interfaces

- Define interfaces at the consumer, not the implementor
- Keep interfaces small — 1-3 methods max
- Accept interfaces, return concrete types
- Don't export interfaces unless consumers outside your package need them
- Name single-method interfaces with `-er` suffix: `Reader`, `Closer`, `Handler`

## Struct Design

- Use functional options for complex constructors:

```go
type Option func(*Server)

func WithPort(p int) Option { return func(s *Server) { s.port = p } }

func NewServer(opts ...Option) *Server {
    s := &Server{port: 8080}
    for _, o := range opts {
        o(s)
    }
    return s
}
```

- Embedding for composition, not inheritance
- Zero value should be useful (e.g., `sync.Mutex`, `bytes.Buffer`)

## Package Organization

- Package name matches directory name, short and lowercase
- No `util`, `common`, `helpers` packages — find a real name
- Internal packages for implementation details: `internal/`
- `cmd/<name>/main.go` for executables
- One package per concern, not one file per type

## Performance

- Preallocate slices when length is known: `make([]T, 0, n)`
- Use `strings.Builder` for multi-step string construction
- `sync.Pool` for frequently allocated/freed objects
- Benchmark before optimizing: `func BenchmarkX(b *testing.B)`
- Avoid allocations in hot paths — check with `go test -benchmem`

## Anti-Patterns

- Don't use `panic` for normal error flow
- Don't ignore errors with `_` — at minimum log them
- Don't use `init()` unless absolutely necessary (makes testing hard)
- Don't return interfaces from constructors (hides what you actually return)
- Don't use context for passing optional function parameters
