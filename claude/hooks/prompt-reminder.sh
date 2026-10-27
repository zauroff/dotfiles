#!/usr/bin/env bash
# UserPromptSubmit hook: re-injects the plan-mode contract when the session is
# in plan mode.

input=$(cat)
mode=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("permission_mode",""))' 2>/dev/null)

[ "$mode" = "plan" ] || exit 0

echo "PLAN MODE IS ACTIVE. If the 'plan' skill is not loaded in this conversation, load it now with the Skill tool and follow it: grill-me first, then a plain-English plan, then ExitPlanMode." |
  python3 -c 'import sys,json; print(json.dumps({"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":sys.stdin.read()}}))'
