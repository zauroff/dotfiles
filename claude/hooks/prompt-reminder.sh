#!/usr/bin/env bash
# UserPromptSubmit hook: every prompt re-injects the output style contract, and
# the plan-mode contract when the session is in plan mode.

input=$(cat)
mode=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("permission_mode",""))' 2>/dev/null)
style=$(python3 -c 'import json; print(json.load(open("'"$HOME"'/.claude/settings.json")).get("outputStyle","Dry"))' 2>/dev/null)

{
  echo "OUTPUT STYLE CONTRACT. The active output style is '$style'. Follow it exactly."
  echo "Every sentence carries a fact, a decision, an instruction, or a result. No chatter, no framing phrases, no personality."
  echo "Violations are logged and punished. A response that breaks the style is a failed response and will be rejected."
  echo "Write in plain English. Cite code as file:line."
  if [ "$mode" = "plan" ]; then
    echo
    echo "PLAN MODE IS ACTIVE. If the 'plan' skill is not loaded in this conversation, load it now with the Skill tool and follow it: grill-me first, then a plain-English plan, then the Excalidraw diagram via mkplan.py, then ExitPlanMode."
  fi
} | python3 -c 'import sys,json; print(json.dumps({"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":sys.stdin.read()}}))'
