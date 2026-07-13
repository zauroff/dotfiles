---
name: mcp-query-router
description:
  Route MCP tool calls to a subagent for context isolation. Auto-invoke when
  any MCP tool is needed (docs search, GitHub, ticketing, or similar). TRIGGER
  when the PreToolUse hook blocks an MCP call, or when you need to query
  external tools. SKIP when already inside a subagent.
---

# MCP Query Router

## Rule

**Never call MCP tools directly in the main conversation.** Always delegate to a subagent.

MCP responses are often large (thousands of tokens of JSON, search results, ticket details). Running them in a subagent keeps the main context clean and cheap.

## How to Route

When you need information from an MCP tool:

1. Spawn a subagent (model: haiku) with the Agent tool
2. Tell it exactly what to query and what format to return
3. The subagent calls the MCP tools, processes the results, and returns a concise summary
4. Use the summary in your main response

## Prompt Template

```
Search [tool] for [query]. Return:
- [specific fields needed]
- Maximum [N] results
- One-sentence summary of findings

Format as a bullet list. Omit raw JSON.
```

## Examples

**Docs search:**
```
Agent(model: haiku, prompt: "Search the docs tool for documentation about service routing. Return the top 3 results with title, URL, and a one-line summary of each.")
```

**GitHub PR lookup:**
```
Agent(model: haiku, prompt: "Get PR #42 from org/repo on GitHub. Return: title, status, author, and a 2-sentence summary of the changes.")
```

**Ticket lookup:**
```
Agent(model: haiku, prompt: "Look up ticket #12345 in the ticketing tool. Return: summary, status, owner, severity, and the last 3 comments (one line each).")
```

## When to Use Sonnet Instead of Haiku

- The query requires multi-hop reasoning (search → read → cross-reference)
- You need the subagent to analyze or compare multiple results
- The task involves writing a synthesis from several sources

## What NOT to Route

- Simple bash commands (git, ls, grep) — run these directly
- File reads — use the Read tool directly
- Anything where the response is predictably small
