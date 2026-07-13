---
name: delegate
description:
  Dispatch system for routing work to the appropriate model tier. Use when
  deciding whether to handle something inline or delegate to a subagent.
  TRIGGER when the user says "delegate", or when planning how to distribute
  work across subagents. Also useful as a mental model for any multi-agent task.
user-invocable: true
---

# Delegate

## Decision Framework

For each unit of work, evaluate two dimensions:

1. **Complexity** — How much reasoning is required?
2. **Context need** — Does it need the full conversation history?

```
                    Low context need    High context need
                    ─────────────────   ─────────────────
High complexity  │  Sonnet subagent     Keep in main (opus)
Low complexity   │  Haiku subagent      Keep in main (any)
```

If it needs context → do it inline. If it doesn't → delegate to the cheapest model that can handle it.

## Model Routing

### Haiku — Mechanical tasks

- Grep/find/read operations
- Extracting specific data from files
- MCP tool calls and result summarization
- Formatting, linting checks
- Simple transformations (rename, reorder)

### Sonnet — Structured reasoning

- Multi-file code exploration
- Writing new code from clear specs
- Code review (single dimension)
- Test generation
- Refactoring with defined targets
- Research across documentation

### Opus — Judgment and synthesis

- Architectural decisions with tradeoffs
- Synthesizing multiple subagent findings
- Ambiguous requirements needing interpretation
- User-facing explanations and recommendations
- Final sign-off on important changes

## Delegation Checklist

Before spawning a subagent, verify:

- [ ] The task is self-contained (doesn't need conversation history)
- [ ] You can write a clear, complete prompt without saying "based on what we discussed"
- [ ] The expected output format is well-defined
- [ ] You know how to verify the result

If any of these fail → do it inline or break the task down further.

## Prompt Quality Rules

**Be specific about output format:**
```
Bad:  "Look into the auth system"
Good: "Find all functions in src/auth/ that accept a token parameter. Return: filepath:line, function name, parameter types. Format as a markdown table."
```

**Include success criteria:**
```
"...If you find more than 10 results, return only the top 5 by relevance and note the total count."
```

**Specify what NOT to do:**
```
"...Do not read test files. Do not suggest changes. Only report what exists."
```

## Parallel vs Sequential

**Parallel** (single message, multiple Agent calls):
- Independent research tasks
- Multi-lens reviews (each reviewer is independent)
- Searching in different parts of the codebase

**Sequential** (wait for result before next):
- Task B depends on Task A's output
- Iterative refinement (implement → review → fix)
- When you need to decide whether to proceed based on results

## Verification

After receiving subagent results:
- Spot-check one concrete claim (open the file, verify the line)
- Check for internal consistency (do the parts agree?)
- If anything smells off → ask a second subagent to verify that specific claim
