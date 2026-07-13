---
name: group-review
description:
  Parallel PR review with multiple independent subagents for consensus-based
  findings. Use when reviewing PRs where confidence matters. TRIGGER when the
  user says "group review", "consensus review", or wants a thorough PR review.
  SKIP for quick/trivial reviews.
user-invocable: true
---

# Group Review

## Concept

Spawn 3 independent review subagents in parallel. Each reviews the same diff without seeing the others' findings. Consolidate by consensus — findings that multiple reviewers agree on are high-confidence.

## Process

### 1. Spawn Reviewers

Send a single message with 3 Agent tool calls (they run concurrently). Each reviewer gets:
- The diff or list of changed files
- A distinct review lens (see below)
- Instructions to return structured findings

### 2. Review Lenses

Each reviewer focuses on a different dimension:

**Reviewer A — Correctness:**
- Logic bugs, off-by-one errors, race conditions
- Missing error handling, null/undefined paths
- Broken invariants, incorrect assumptions

**Reviewer B — Design:**
- Naming clarity, abstraction level, cohesion
- Unnecessary complexity, missed simplifications
- Violation of existing patterns in the codebase

**Reviewer C — Robustness:**
- Edge cases, boundary conditions
- Failure modes, error propagation
- Missing tests, untested paths

### 3. Consolidate

After all 3 return, merge findings:

- **High confidence** (2-3 reviewers found it): Definitely flag
- **Medium confidence** (1 reviewer found it): Include but note it's single-source
- **Contradictions** (reviewers disagree): Present both perspectives, let the user decide

Deduplicate — same finding in different words counts once.

### 4. Report

Present findings grouped by severity:
1. Bugs / correctness issues
2. Design concerns
3. Suggestions / nitpicks

For each finding: file, line, description, which reviewers flagged it.

## Reviewer Prompt Template

```
Review this PR diff. Focus on [LENS]. You are one of 3 independent reviewers — give your honest assessment without hedging.

Changed files: [list]

For each finding, report:
- File and line
- Severity: bug / concern / suggestion
- Description (one sentence)
- Your confidence: high / medium / low

Return as a JSON array. Do not explain your methodology.
```

## When to Use

- PRs with significant logic changes
- Changes to critical paths (auth, payments, data integrity)
- When you want to be thorough and catch subtle issues
- When the user explicitly asks for a careful review

## When NOT to Use

- Trivial PRs (dependency bumps, typo fixes, config changes)
- When speed matters more than thoroughness
- Formatting-only changes
