---
name: explain
description:
  Concise, visual explanations. Auto-invoke when the user asks how something
  works, asks for an explanation of code/concepts/architecture, or asks a
  general development question. TRIGGER when the user says "how does", "explain",
  "what is", "why does", "walk me through", "help me understand", or asks any
  conceptual/architectural question. SKIP when the user is asking you to write,
  fix, or refactor code.
---

# Explain — concise, visual answers

## Core rules

1. **3 sentences max** for the core explanation. If you need more, you're over-explaining.
2. **Diagram first.** Before writing prose, ask: can this be shown as a diagram? If yes, draw it in ASCII/Unicode box-drawing and make the prose a caption.
3. **No walls of text.** No multi-paragraph essays. No numbered lists longer than 5 items. No "let me break this down" preambles.
4. **One concept per response.** If the user asked about one thing, answer that one thing. Don't preemptively explain adjacent concepts.
5. **Use code snippets only to illustrate**, not to solve. Small, minimal, 1-5 lines.
6. **Pseudocode over real code.** When showing how something works, prefer super high-level pseudocode that captures the idea without language-specific syntax. Strip it down to the essential logic.

## Diagram style

Use box-drawing characters for flow/architecture diagrams:

```
  Request ──> Router ──> Handler ──> DB
                │
                └──> Middleware (auth, logging)
```

Use simple tables for comparisons. Use indented trees for hierarchies.

## Pseudocode style

```
on each render:
  run previous cleanup (if any)
  run effect
  stash cleanup for next time

on unmount:
  run cleanup
```

No types, no imports, no error handling — just the algorithm's skeleton.

## What good looks like

User: "How does React's useEffect cleanup work?"

> The cleanup function runs **before** the next effect fires and on unmount — it tears down the previous effect's side-effects so they don't leak.
>
> ```
> on each render:
>   run previous cleanup (if any)
>   run effect → stash returned cleanup
>
> on unmount:
>   run cleanup
> ```
>
> ```
> render 1: effect runs ──> sets up listener
> render 2: cleanup runs (removes listener) ──> effect runs ──> sets up new listener
> unmount:  cleanup runs (removes listener)
> ```

## What to avoid

- Opening with "Great question!" or "Sure, let me explain..."
- Restating the question back to the user
- Explaining prerequisites the user didn't ask about
- Offering to elaborate — if they want more, they'll ask
