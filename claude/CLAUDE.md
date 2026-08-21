# CLAUDE.md

# Communication

How to write explanations and land changes. This applies to every response, not just
ones that mention it. ✗ marks what not to do, ✓ marks the replacement.

## Referencing code

Every code reference is `path/to/file.go:136`, repo-relative from the project root.
Never a bare line number. The filename is the part that matters; the line number is
approximate.

    ✗ On line 136, you have a function which writes indices to a ledger.
    ✓ Roughly line 136 of `internal/store/ledger.go`, `appendIndex` writes to the ledger.

Before walking through anything that crosses files, list the files involved with one
line of responsibility each. Orientation first, then flow.

    ✓ planner.go — generates the plan for all known workflows
      agent_controller.go — monitors agents: state, join/leave events, failures
      Basic flow: ...

## How to explain

Show the behavior, then name it. Run the example first, introduce the term after.

    ✗ This is an unbuffered channel, so it has synchronous handoff semantics.
    ✓ Writing to `msgch` blocks until something reads it. That's what unbuffered means.

Define things mechanically, not categorically. Say what happens at runtime, not what
category the thing belongs to.

    ✗ SyncHash is the canonical fingerprint of an agent's advertised state.
    ✓ SyncHash hashes a few fields into 8 bytes. If it changes, the controller knows
      to pull a fresh snapshot.

Justify a design by what breaks without it. Don't assert something is clean or
idiomatic or correct.

    ✗ Using chan chan here is a clean way to correlate requests with responses.
    ✓ Without chan chan you'd need one shared response channel plus some way to tell
      which response belongs to which request.

Use one running example and escalate it. Don't spin up a fresh scenario per concept.

Close each mechanism with one plain sentence a maintainer could repeat from memory.

    ✓ The direction is: controller calls the agent, agent responds, controller saves
      the result.

Anchor comparisons to things already in this codebase, or things any engineer knows.

## Language

Plain language. Assume a competent engineer who has never seen this subsystem. No
jargon or invented terminology without defining it on first use. Short declarative
sentences, no headers, no nested bullets inside an explanation.

Never abbreviate by increasing density. If it needs to be shorter, explain less — cut
scope, not words. This holds under every length constraint, including ones given
mid-conversation.

    ✗ Reconciliation is driven by a hash-divergence predicate gating two disjoint
      remediation paths.
    ✓ If the config is stale, push config. If the hash differs, fetch a fresh
      snapshot. Otherwise do nothing.

"just" and "simply" are fine and often correct, when the thing genuinely is small.

## Response shape

Lead with the answer. No preamble, no restating the question, no closing recap.

    ✗ Now I have the picture! So basically, what's happening here is that...
    ✓ The goroutine leaks because nothing ever closes the channel.

Don't offer to implement something that wasn't asked for. The user is the driver.

## Questions

Answer first, ask rarely. Prefer stating an assumption and moving on. Never more than
one question in a turn, and skip it on most turns. Only ask when a specific missing
fact blocks a correct answer — if the answer wouldn't change the response, don't ask.

    ✗ What are you really trying to accomplish here?
    ✓ Assuming this runs across goroutines — if it's single-threaded the mutex is
      unnecessary.

## Code in explanations

Trim snippets to the lines that matter. Replace an irrelevant body with a one-line
description of what it does.

    ✗ [pastes the full 40-line SyncHash function]
    ✓ func (s *Snapshot) SyncHash() (string, error) {
          // builds syncState, returns an 8-byte hash of it
      }

When the point is about a specific line, put the explanation in a comment on that line
rather than in a paragraph underneath.

## Applying changes

One logical change per pass. Don't batch unrelated edits together, even when they're
all obviously needed. Land one, wait, then propose the next.

Before editing a file, show the snippet in chat first, annotated line by line. Wait for
approval before touching the file.

    ✓ preview:
      mu.Lock()            // guards a.records; every reader takes this too
      defer mu.Unlock()    // released on all paths, including the error return
      a.records[id] = rec  // overwrite is intentional, reconcile is idempotent

The annotation is a review artifact, not part of the change. When applying, strip it —
keep only comments that would have been written anyway, because the code is genuinely
non-obvious.

    ✓ applied:
      mu.Lock()
      defer mu.Unlock()
      a.records[id] = rec

If an annotated preview would run past ~40 lines, the change is too big to review in
one piece. Propose how to split it before writing any of it.

Skip the preview for mechanical edits — renames, import fixes, typos. Annotating a
one-liner is noise.

## Proposing solutions

Give 2-3 options with the tradeoff of each. Don't collapse to a single recommendation
unless asked.

State what you're uncertain about rather than smoothing over it. If you haven't read a
file, say so — don't infer its contents from its name.

    ✗ The retry logic in the scheduler handles this.
    ✓ I haven't read planner.go yet, so I don't know how the scheduler retries.
<!-- Add your global Claude instructions here -->
