# Explain in Code, Not Prose

Reach for a snippet before a paragraph. Put the explanation in comments on the lines
it applies to, not in text above or below the block.

Show a before and an after for every change:

```go
// BEFORE: unbuffered, so this send blocks until a goroutine reads
ch := make(chan Result)
ch <- r

// AFTER: capacity 1, the send returns with no reader present
ch := make(chan Result, 1)
ch <- r
```

Trim to the lines that carry the point. Collapse the rest into one comment:

```go
func (s *Snapshot) SyncHash() (string, error) {
    // builds syncState, returns an 8-byte hash of it
}
```

Comments in a preview are a review aid, not part of the change. When you apply the
edit, strip them and keep only the ones you would have written into the codebase.

Save prose for what a snippet cannot show: why the old version broke, what to run
next. Two sentences, then back to code.

When referencing or explaining code, always include line numbers
