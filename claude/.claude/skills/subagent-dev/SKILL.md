---
name: subagent-dev
description:
  Subagent-driven development methodology. Use for complex multi-step
  implementation tasks where isolation prevents context pollution. TRIGGER
  when the user says "subagent", "isolate", or for large implementation tasks
  that benefit from fresh-context review. SKIP for simple single-file changes.
user-invocable: true
---

# Subagent-Driven Development

## Philosophy

Each task gets a fresh subagent with isolated context. The main agent orchestrates — it never implements directly for non-trivial work. This prevents context pollution, enables parallel work, and guarantees independent review.

## Roles

### Implementer (sonnet or opus)

A fresh subagent that receives:
- The spec (what to build)
- Relevant file paths and context
- Constraints and patterns to follow

It implements, then reports what it did and any concerns.

### Spec Reviewer (sonnet)

A separate subagent (fresh context, no memory of implementation) that:
- Reads the implemented code
- Compares against the original spec
- Reports: does the implementation satisfy all requirements?

### Quality Reviewer (sonnet)

Another fresh subagent that:
- Reads the implemented code with no knowledge of the spec
- Evaluates: code quality, edge cases, error handling, test coverage
- Reports concerns ranked by severity

## Workflow

```
1. Main agent understands the task and writes a spec
2. Spawn Implementer → receives spec → writes code → reports back
3. Spawn Spec Reviewer → reads code + spec → confirms alignment
4. Spawn Quality Reviewer → reads code only → reports quality issues
5. Main agent synthesizes feedback, iterates if needed
```

## When to Use

- Task touches 3+ files
- Task requires both implementation and tests
- You want confidence that the implementation matches intent
- The implementation is complex enough that review in a fresh context adds value

## When NOT to Use

- Single-file changes
- Simple bug fixes with obvious solutions
- Tasks where the user wants to see the work happen in real-time

## Prompt Templates

**Implementer:**
```
Implement the following spec. Follow existing patterns in the codebase.

Spec: [description]
Files to modify: [paths]
Patterns to follow: [reference files]
Constraints: [list]

When done, report: files changed, key decisions made, anything you're unsure about.
```

**Spec Reviewer:**
```
Review this implementation against the spec. You have not seen the implementation process — evaluate with fresh eyes.

Spec: [original spec]
Files to review: [paths]

Report: Does it satisfy all requirements? Any gaps or misinterpretations?
```

**Quality Reviewer:**
```
Review this code for quality. You have no context about what it's supposed to do — evaluate the code on its own merits.

Files: [paths]

Report: edge cases missed, error handling gaps, naming issues, test coverage, potential bugs. Rank by severity (high/medium/low).
```

## Status Handling

Subagents report one of:
- **DONE** — completed successfully, no concerns
- **DONE_WITH_CONCERNS** — completed but flagging issues for the orchestrator
- **NEEDS_CONTEXT** — missing information, cannot proceed (escalate to main)
- **BLOCKED** — hit an obstacle (dependency, unclear requirement)
