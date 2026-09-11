#!/usr/bin/env bash
# PostToolUse hook (ExitPlanMode): the plan was accepted. Implementation runs
# under the `code` skill. Clear the diagram marker so the next plan must regenerate.

input=$(cat)
cwd=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null)
[ -n "$cwd" ] || cwd="$PWD"
rm -f "$HOME/.claude/plan-viz/$(printf %s "$cwd" | shasum | cut -c1-16)"

cat <<'MSG' | python3 -c 'import sys,json; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":sys.stdin.read()}}))'
PLAN APPROVED. Invoke the `code` skill with the Skill tool now, before any edit. Implement the approved plan under it: minimal diff, stdlib and existing helpers first, one runnable check per non-trivial change. Follow the plan's steps in order.
MSG
