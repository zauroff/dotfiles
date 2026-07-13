---
name: token-conservation
description:
  Session-wide mode that delegates work to cheaper models via subagents.
  Invoke with "/token-conservation" to activate. Use when working on long
  sessions where context window budget matters, or when the user wants to
  minimize token usage.
user-invocable: true
---

# Token Conservation Mode

When activated, route work to the cheapest model capable of handling it. Keep expensive models (opus) for synthesis and judgment only.

## Routing Tiers

### Haiku (cheapest — delegate aggressively)

- File reads and greps
- Git operations (log, diff, status, blame)
- JSON/YAML extraction and transformation
- Simple lookups (find a function, list files matching pattern)
- MCP tool calls (all of them — see mcp-query-router)
- Summarizing large outputs

### Sonnet (mid-tier — moderate complexity)

- Multi-step code exploration (trace a call chain across files)
- Writing boilerplate or repetitive code
- Test generation from existing patterns
- Code review of individual files
- Refactoring with clear instructions

### Opus (keep in main context — judgment and synthesis)

- Architectural decisions
- Synthesizing findings from multiple subagents
- User-facing analysis and recommendations
- Ambiguous tasks requiring interpretation
- Final review of subagent outputs

## How to Apply

For each unit of work, ask: "Could a cheaper model do this correctly?"

- If yes → spawn a subagent at that tier
- If unsure → try haiku first, escalate if the result is insufficient

## Subagent Prompt Pattern

Be specific about what to return. Vague prompts waste tokens on irrelevant output:

```
Bad:  "Look at the auth module and tell me about it"
Good: "In src/auth/, find which function validates JWT tokens. Return: file path, function name, and its signature."
```

## Trust but Verify

Subagent results are usually correct for mechanical tasks. Spot-check when:
- The result will drive an architectural decision
- The task had ambiguity the cheaper model might misinterpret
- Something in the summary doesn't match your mental model
