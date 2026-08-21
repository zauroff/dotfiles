#!/usr/bin/env bash
# SessionStart + UserPromptSubmit hook: make stop-slop the default posture,
# reinjected on every single message, not just once at session start.
#
# Prints the stop-slop skill into context every time it fires so the rules
# stay live turn to turn instead of decaying as the conversation grows.
#
# Opt out for a machine/checkout by creating ~/.claude/.stop-slop-off;
# mid-session, just tell Claude "stop-slop off".

skill="$HOME/.claude/skills/stop-slop/SKILL.md"

[ -f "$HOME/.claude/.stop-slop-off" ] && exit 0
[ -f "$skill" ] || exit 0

cat <<'EOF'
STOP-SLOP MODE active. Follow the skill below for all prose you write, until
the user says otherwise ("stop-slop off").

EOF

awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} !fm' "$skill"

exit 0
