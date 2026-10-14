#!/usr/bin/env bash
# PreToolUse hook (Edit|Write): inject the dedicated coding-convention skill for
# whatever language is being written. Go is the primary one and the only skill
# that exists today; other languages get a short fallback pointing at it.
#
# Add a new language by dropping ~/.claude/skills/<lang>-coding-conventions/
# and adding its extensions to the case below.
#
# No-ops on non-code files so it stays silent on docs, configs, and data.
#
# Opt out for a machine/checkout by creating ~/.claude/.coding-conventions-off.

[ -f "$HOME/.claude/.coding-conventions-off" ] && exit 0

case "$(jq -r '.tool_input.file_path // empty')" in
  *.go) lang=go ;;
  *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs) lang=typescript ;;
  *.py) lang=python ;;
  *.rs) lang=rust ;;
  *.lua) lang=lua ;;
  *.sh | *.bash | *.zsh) lang=shell ;;
  *.c | *.h | *.cc | *.cpp | *.hpp) lang=cpp ;;
  *.java) lang=java ;;
  *) exit 0 ;; # not code, nothing to say
esac

skill="$HOME/.claude/skills/${lang}-coding-conventions/SKILL.md"
go_skill="$HOME/.claude/skills/go-coding-conventions/SKILL.md"

if [ -f "$skill" ]; then
  intro="Follow the $lang coding conventions below for this edit."
elif [ -f "$go_skill" ]; then
  # No skill for this language: fall back to the Go conventions' principles, which
  # are language-agnostic enough to carry (naming, error handling, comments).
  skill="$go_skill"
  intro="No dedicated $lang convention skill exists. Apply the Go coding conventions
below in spirit — naming, function shape, comments, and error handling —
translated into idiomatic $lang."
else
  exit 0
fi

{
  echo "$intro"
  echo
  # strip the YAML frontmatter, emit the skill body
  awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} !fm' "$skill"
} | python3 -c 'import sys,json; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":sys.stdin.read()}}))'
