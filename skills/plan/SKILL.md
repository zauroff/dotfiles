---
name: plan
description: Plan a code change by exploring the real flow, interviewing the user where decisions remain, and writing an executable plain-English plan. Use in plan mode or when the user asks for a plan. After approval, hand off to the `code` skill.
---

# Plan

Plan mode has one procedure. Run it in order.

## 1. Explore

Read the code the change touches. Trace the real flow end to end. Every
question that the codebase can answer is answered by reading it, not by asking.

## 2. Interview

Invoke the `grill-me` skill using the host's skill mechanism. Ask one question at
a time, each with a recommended answer. Resolve every branch of the decision
tree. The last question is always "Is there anything else you would like to
add?".

## 3. Write the plan

Write the plan file in plain English. A plan is a set of instructions a
competent engineer with no context could execute. Rules:

- Numbered steps. Each step names the file it changes and says what changes and
  why, in one to three sentences.
- Concrete nouns. File paths, function names, table names. Never "the
  component", "the layer", "the system".
- No phase names, no "foundation", "scaffolding", "harden", "robust", "leverage",
  "streamline", "seamless", "ensure", "comprehensive", "holistic".
- No headers named "Overview", "Approach", "Considerations", "Next steps".
- Decisions taken during the interview are stated as facts, with the reason.
- Things deliberately skipped are listed, each with the condition that would
  bring it back.
- Risks are listed only when a step can break something that exists today,
  and each names what breaks.
- One runnable check per non-trivial step: the command, and what output means
  the step worked.

## 4. Submit

Submit the plan using the host's plan-mode mechanism. In Claude Code, call
`ExitPlanMode`. In Codex, return the plan and wait for approval. Once the user
approves, invoke the `code` skill before the first edit.
