#!/usr/bin/env bash
# PostToolUse hook (EnterPlanMode): plan mode has a fixed procedure, owned by
# the `plan` skill. Shift+Tab entry is covered by prompt-reminder.sh instead.

cat <<'MSG' | python3 -c 'import sys,json; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":sys.stdin.read()}}))'
PLAN MODE ENTERED. Load the `plan` skill with the Skill tool now and follow it exactly. Order: explore the code, run the grill-me interview, write the plain-English plan, generate and open the Excalidraw diagram with mkplan.py, then call ExitPlanMode.
MSG
