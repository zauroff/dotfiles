---
name: stepwise
description:
  Break a task into small subtasks, then plan and implement one at a time with
  user review between each step. Use instead of full plan mode when the task is
  complex and the user wants incremental control. TRIGGER when the user says
  "stepwise", "step by step", "incrementally", "one piece at a time", or wants
  to avoid a monolithic plan.
---

# Stepwise — incremental planning and implementation

## Philosophy

Plan mode dumps the entire strategy at once, which is overwhelming for complex
tasks. Stepwise decomposes the work into small, reviewable chunks. Each chunk
gets its own mini-plan, implementation, and review gate before moving on.

## Process

### 1. Decompose

Analyze the task and break it into the smallest meaningful subtasks. Present
them as a numbered list (aim for 3-7 items). Each subtask should be:

- Independent enough to implement and verify on its own
- Small enough to review in under a minute
- Ordered by dependency (earlier steps unlock later ones)

Ask: "Does this breakdown look right? Want to reorder, merge, or split
anything?"

Wait for confirmation before proceeding.

### 2. Plan one subtask

For the current subtask only, present a short plan:

- What will change (files, functions, configs)
- The approach in 2-4 bullet points
- Any decisions or tradeoffs to flag

Do NOT plan subsequent subtasks — they may change based on what we learn.

Ask: "Good to implement this step?" Wait for a go-ahead.

### 3. Implement one subtask

Implement only the current subtask. Keep the diff small and focused.

After implementation, briefly state what was done and show any relevant output
(test results, type-check, etc).

### 4. Review gate

After each subtask, pause and ask:

- "Does this look right? Anything to adjust before we move on?"

If the user wants changes, iterate on this subtask. If they're happy, announce
the next subtask and loop back to step 2.

### 5. Reflect and adapt

Between subtasks, reassess:

- Has what we learned changed the remaining plan?
- Should we reorder, add, or drop subtasks?

If the plan changed, briefly note what shifted and why before continuing.

## Rules

- Never implement more than one subtask without explicit user approval.
- Never plan more than one subtask ahead in detail.
- Keep mini-plans short — bullet points, not paragraphs.
- If a subtask turns out to be too large during implementation, stop and split
  it further.
- Use the task list (TaskCreate/TaskUpdate) to track subtasks so progress is
  visible.

## What good looks like

```
Task: "Add authentication to the API"

Subtasks:
1. Add user model and migration
2. Implement password hashing and verification
3. Add login/register endpoints
4. Add JWT token generation and validation
5. Add auth middleware to protected routes
6. Add tests

Starting with subtask 1...

Plan for subtask 1:
- Create User model in models/user.go with fields: id, email, password_hash, created_at
- Add migration file 003_create_users.sql
- Add basic model tests

Good to implement?
```
