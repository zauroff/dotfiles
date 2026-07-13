---
name: log-work
description: >
  Record work into the user's Obsidian vault. Default: append a dated entry to an existing
  project note's "## Claude Log" section. Can also create a new numbered project note (with a
  blank Excalidraw + area tag) when the work doesn't fit an existing project. Covers any code
  change (refactor, feature, fix, config) AND conceptual explainers (how a system/algorithm/
  pattern works). Use when the user says "log this", "log work", "write this up", "document
  this in obsidian", "explain this in a note", "/log-work", or after a large diff. Reads the
  git diff (if any) + the conversation, and explains both the change and the concepts behind it.
---

Record work into the user's Obsidian vault. The audience is the user's future self reading it
cold. Explain both the **change** (what changed and *why*) and the **concept** (how it works —
the algorithm, system, or pattern that makes the change make sense). Lead with understanding,
not a raw diff dump.

Two modes:
1. **Append** (default) — add a dated entry to an existing project note's `## Claude Log`.
2. **Create** — make a new numbered project note when the work is a new project.

## Vault

```
VAULT="/Users/dzauroff1/Documents/zauroff::obsidian_vault"
PROJECTS="$VAULT/Work/Projects"     # numbered project notes: "NNNN - Title.md"
ATTACH="$VAULT/_attachments"        # drawings & images
TEMPLATE="$VAULT/_templates"        # Project Note.md, Blank Drawing.excalidraw.md
```

Projects are tagged `#dray` or `#b2d2`. Each project note has the sections: Summary, Todo,
Notes, Excalidraw, Claude Log. If the vault has been reorganized, discover numbered series with:
`find "$VAULT" -type f -name '[0-9][0-9][0-9][0-9] - *.md' -not -path '*/_attachments/*'`.

## Steps

### 1. Gather context
- **Code change:** `git -C <repo> diff HEAD --stat` and `diff HEAD` for uncommitted work; if
  already committed, `git -C <repo> log --oneline -n 10` + `git -C <repo> show` / `diff <base>..HEAD`.
- **Concept note:** pull the relevant code/docs the explanation refers to (a diff is optional).
- Lean on the conversation for *intent* and *reasoning* — that's the point of the entry.

### 2. Pick the target project (ask every time)
Show existing projects and ask which one this belongs to, or whether to create a new project:
```bash
ls "$PROJECTS" | grep -E '^[0-9]{4} - '
```

### 3a. Existing project → append to its Claude Log
- Read `$PROJECTS/<NNNN - Title>.md`.
- Locate the `## Claude Log` heading (if absent, append it at the end of the file).
- Insert a new entry directly under the heading (newest first):

```markdown
### <date> — <short title>
**Summary:** one line on what this entry captures.
**Why:** the motivation / problem.
**How it works:** the concept, if relevant (algorithm, system, pattern). Be generous.
**Changed:** `path/to/file` — the decision, not just the mechanical edit. (one bullet per file)
**Follow-ups:** risks / TODO / things to verify, if any.
```

- `<date>`: use `currentDate` from the project `CLAUDE.md` if present, else system date.
- If the entry implies follow-up work, also add `- [ ]` items to the note's `## Todo` section
  (they roll up into Mission Control automatically).

### 3b. New project → create it, then log
- Compute the next number:
```bash
last=$(ls "$PROJECTS" 2>/dev/null | grep -oE '^[0-9]{4}' | sort -n | tail -1)
printf "%04d" $(( 10#${last:-0} + 1 ))
```
- Ask the user for a **Title** and the **area tag** (`dray` or `b2d2`).
- Create `$PROJECTS/<NNNN> - <Title>.md` following `$TEMPLATE/Project Note.md`: frontmatter
  with `project`, `status: active`, `created: <date>`, `tags: [<area>, project]`; then the
  Summary / Todo / Notes / Excalidraw / Claude Log sections.
- Give it a blank drawing so the embed resolves, and embed it:
```bash
cp "$TEMPLATE/Blank Drawing.excalidraw.md" "$ATTACH/<NNNN> - <Title>.excalidraw.md"
```
  Excalidraw section: `![[<NNNN> - <Title>.excalidraw]]`.
- Then append the first Claude Log entry (format from 3a).

### 4. Confirm
Report the exact file and section written and the project number. Obsidian picks it up
automatically — no import step.

## Notes
- Never create per-folder `Attachments/` folders — drawings go in `_attachments/`.
- Filenames are the link key in Obsidian; keep titles unique.
- Link related notes with `[[Title]]`; a link to a not-yet-existing note is fine.
- Do not commit anything (vault or dotfiles) unless the user asks.
