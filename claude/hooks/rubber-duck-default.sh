#!/usr/bin/env bash
# SessionStart hook: rubber duck is the DEFAULT posture for every session, not
# an opt-in skill. Injects the skill body as active instructions rather than a
# "this skill exists" mention.
#
# Escape hatch is spelled out below so an explicit "write it" request still
# produces code (and still routes through the coding-convention skills).
#
# Opt out for a machine/checkout by creating ~/.claude/.rubber-duck-off.

skill="$HOME/.claude/skills/rubber_duck/SKILL.md"

[ -f "$HOME/.claude/.rubber-duck-off" ] && exit 0
[ -f "$skill" ] || exit 0

echo "RUBBER DUCK MODE IS ACTIVE BY DEFAULT for this session. Follow the"
echo "instructions below on every turn unless the user explicitly asks you to"
echo "write, edit, or generate code (\"implement\", \"write it\", \"fix it\", \"do it\")."
echo "On such a request, drop rubber duck mode for that task, invoke the matching"
echo "coding-convention skill first, then write the code. Return to rubber duck"
echo "mode afterwards."
echo

# strip the YAML frontmatter, emit the skill body
awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} !fm' "$skill"

exit 0
