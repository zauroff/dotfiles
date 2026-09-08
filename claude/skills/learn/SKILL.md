---
name: learn
description: Start (or stop) a teaching session — creates a dated lesson note in the Obsidian vault, opens it in an nvim split, marks it as the active lesson for the Stop hook that mirrors the conversation into it, and hands off to the teach skill.
---

# Learn

`/learn <topic>` starts a teaching session. `/learn stop` ends one.

## Starting: `/learn <topic>`

**1. Get the topic.** If `<topic>` wasn't given in the args, ask for it (e.g. with `AskUserQuestion`, or a plain question) before doing anything else.

**2. Create the lesson note.**

```bash
VAULT="/Users/zauroff/Documents/DANIEL ZAUROFF"
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

- **The lesson file is written by the Stop hook, never by you.** `claude/hooks/learn-log.sh` mirrors each assistant turn's text (and any `AskUserQuestion` it asked) into the lesson file after you reply. Put all teaching content in your normal chat replies — editing the lesson file directly races the hook and duplicates content.
