---
name: plan
description: The plan-mode procedure. Load whenever plan mode is active (EnterPlanMode tool or Shift+Tab). Explore, grill-me interview, plain-English plan, then ExitPlanMode. On approval the `code` skill takes over.
---

# Plan

Plan mode has one procedure. Run it in order.

## 1. Explore

Read the code the change touches. Trace the real flow end to end. Every
question that the codebase can answer is answered by reading it, not by asking.

## 2. Interview

Invoke the `grill-me` skill with the Skill tool. One question at a time, each
with a recommended answer. Resolve every branch of the decision tree. The last
question is always "Is there anything else you would like to add?".

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

Call ExitPlanMode. Once the user approves, a hook instructs you to invoke the
`code` skill. Do so before the first edit.
