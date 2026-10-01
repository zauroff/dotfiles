---
name: learn
description: Start or stop a recorded teaching session, create its Obsidian note, and hand off to the teach skill. Invoke only when the user explicitly selects the learn skill.
---

# Learn

`/learn <topic>` starts a teaching session. `/learn stop` ends one.

## Starting: `/learn <topic>`

**1. Get the topic.** If `<topic>` wasn't given in the args, ask for it with
the host's interactive-question mechanism or a plain question before doing
anything else.

**2. Create the lesson note.**

```bash
VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/DANIEL ZAUROFF}"
SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
LESSON_DIR="$VAULT/learning/$SLUG"
mkdir -p "$LESSON_DIR/viz"
LESSON_FILE="$LESSON_DIR/$(date +%F) $TOPIC.md"
cat > "$LESSON_FILE" <<EOF
---
tags: [learning]
---
# $TOPIC
EOF
```

Quote every path — the vault name has spaces.

**3. Mark the lesson active for this session only.** The marker is scoped by working directory (`$PWD`) so other Claude sessions' Stop hooks don't append to it — run this with the shell's real `$PWD` (the Bash tool's cwd), not a stored or guessed path:

```bash
mkdir -p "$HOME/.claude/learn-active"
echo "$LESSON_FILE" > "$HOME/.claude/learn-active/$(printf %s "$PWD" | shasum | cut -c1-16)"
```

**4. Open the lesson file in a split**, trying each in order:

```bash
if [ -n "${NVIM:-}" ]; then
  ESCAPED=$(printf '%s' "$LESSON_FILE" | sed 's/ /\\ /g')
  nvim --server "$NVIM" --remote-send "<C-\\><C-n>:vsplit $ESCAPED<CR>"
elif wezterm cli list >/dev/null 2>&1; then
  wezterm cli split-pane --right --percent 45 -- nvim "$LESSON_FILE"
else
  echo "Open manually: nvim \"$LESSON_FILE\""
fi
```

**5. Hand off.** Invoke the `teach` skill and start Phase 1 (probe) against `$TOPIC`.

## Stopping: `/learn stop`

Remove only this session's marker, again keyed by the real `$PWD`:

```bash
rm -f "$HOME/.claude/learn-active/$(printf %s "$PWD" | shasum | cut -c1-16)"
```

## Rules while a lesson is active

- In Claude Code, **never write teaching turns directly to the lesson file**.
  `claude/hooks/learn-log.sh` mirrors each assistant turn and interactive question
  after the reply; writing it yourself would race the hook and duplicate content.
- In Codex or another host without that hook, mirror each teaching turn into the
  active lesson file with the host's file-editing mechanism before replying. Read
  the marker keyed by the current working directory to locate the file. Never
  mirror the same turn twice.
