---
name: golang-testing
description:
  Go testing patterns and best practices. Auto-invoke when writing or reviewing
  Go tests. TRIGGER on _test.go files, test functions, or when the user asks
  about Go testing. SKIP for non-Go test files.
---

# Go Testing

## Table-Driven Tests

The default pattern for Go tests. Each case is a struct with inputs and expected outputs.

```go
func TestParseDuration(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    time.Duration
        wantErr bool
    }{
        {name: "seconds", input: "5s", want: 5 * time.Second},
        {name: "empty", input: "", wantErr: true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseDuration(tt.input)
            if tt.wantErr {
                require.Error(t, err)
                return
            }
            require.NoError(t, err)
            assert.Equal(t, tt.want, got)
        })
    }
}
```

## Parallel Tests

Run independent subtests in parallel for speed:

```go
t.Run(tt.name, func(t *testing.T) {
    t.Parallel()
    // ...
})
```

Only parallelize when tests don't share mutable state.

## Test Helpers

- Use `t.Helper()` in helper functions so failures report the caller's line
- Use `t.Cleanup(func())` instead of defer for test teardown
- Use `t.TempDir()` for temp files — auto-cleaned

```go
func setupDB(t *testing.T) *DB {
    t.Helper()
    db := openTestDB()
    t.Cleanup(func() { db.Close() })
    return db
}
```

## Interface-Based Mocking

Define a minimal interface at the test site. Implement it with a struct that records calls or returns canned values.

```go
type sender interface {
    Send(ctx context.Context, msg Message) error
}

type mockSender struct {
    sent []Message
    err  error
}

func (m *mockSender) Send(_ context.Context, msg Message) error {
    m.sent = append(m.sent, msg)
    return m.err
}
```

No mocking frameworks needed — Go interfaces make this trivial.

## Golden Files

For complex output (JSON, HTML, large strings), compare against a file:

```go
func TestRender(t *testing.T) {
    got := render(input)
    golden := filepath.Join("testdata", t.Name()+".golden")

    if *update {
        os.WriteFile(golden, []byte(got), 0644)
    }

    want, _ := os.ReadFile(golden)
    assert.Equal(t, string(want), got)
}
```

Run with `-update` flag to regenerate: `go test -run TestRender -update`

## Benchmarks

```go
func BenchmarkProcess(b *testing.B) {
    input := setupInput()
    b.ResetTimer()
    for b.Loop() {
        process(input)
    }
}
```

- Use `b.ResetTimer()` after expensive setup
- Use `b.ReportAllocs()` or `-benchmem` to track allocations
- Compare with `benchstat old.txt new.txt`

## Fuzzing

```go
func FuzzParseConfig(f *testing.F) {
    f.Add([]byte(`{"port": 8080}`))
    f.Add([]byte(`{}`))

    f.Fuzz(func(t *testing.T, data []byte) {
        cfg, err := ParseConfig(data)
        if err != nil {
            return
        }
        // Invariant: valid config should round-trip
        out, err := cfg.Marshal()
        require.NoError(t, err)
        assert.JSONEq(t, string(data), string(out))
    })
}
```

Run: `go test -fuzz FuzzParseConfig -fuzztime 30s`

## Testing Principles

- Test behavior, not implementation
- One assertion per logical concept (but multiple `assert` calls are fine)
- Test names describe the scenario: `TestCreateUser_DuplicateEmail_ReturnsConflict`
- Use `require` for fatal checks (stops test), `assert` for non-fatal
- Integration tests use build tags: `//go:build integration`
- Keep `testdata/` for fixtures — Go tooling ignores this directory
