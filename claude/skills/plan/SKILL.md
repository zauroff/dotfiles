---
name: plan
description: The plan-mode procedure. Load whenever plan mode is active (EnterPlanMode tool or Shift+Tab). Explore, grill-me interview, plain-English plan, Excalidraw diagram opened in the browser, then ExitPlanMode. On approval the `code` skill takes over.
---

# Plan

Plan mode has one procedure. Run it in order. The ExitPlanMode hook rejects a
plan that skipped the diagram step.

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

## 4. Diagram

Write a spec for `mkplan.py` and run it. The script writes an `.excalidraw`
file and an `.html` viewer into `~/.claude/plans/viz/`, opens the viewer in a
browser tab, and drops the marker that the ExitPlanMode hook checks.

```bash
python3 ~/.claude/skills/plan/mkplan.py /path/to/spec.txt
```

Spec format:

```
title: <the plan title>

section: Steps
1. <step> | <file>
2. <step> | <file>

section: Architecture
[id] Label | detail
[id2] Label
id -> id2 : edge label

section: Notes
- Skipped: <thing>. Add when <condition>.
```

Rules for the spec:

- The Steps section is mandatory and mirrors the numbered steps of the plan
  file, one box per step, the file path as the detail line.
- An Architecture section is mandatory when the change touches more than one
  component, service, table, or process. Boxes are the real components. Edges
  are the real calls or data flows, labeled with the protocol or the payload.
  Add a second graph section (for example "Data flow" or "Before" and "After")
  when one graph cannot show the change.
- Notes carry the skipped items and the risks from the plan file.
- Write the spec to the scratchpad directory. Run `mkplan.py --help` for the
  full format.

## 5. Submit

Call ExitPlanMode. Once the user approves, a hook instructs you to invoke the
`code` skill. Do so before the first edit.
