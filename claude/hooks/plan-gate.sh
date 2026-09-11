#!/usr/bin/env bash
# PreToolUse hook (ExitPlanMode): refuse to submit a plan that has no Excalidraw
# diagram. mkplan.py drops a marker keyed by cwd; the marker proves it ran.

input=$(cat)
cwd=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null)
[ -n "$cwd" ] || cwd="$PWD"
marker="$HOME/.claude/plan-viz/$(printf %s "$cwd" | shasum | cut -c1-16)"

if [ ! -f "$marker" ]; then
  echo "BLOCKED: no Excalidraw plan exists for this session. Load the 'plan' skill, write the plan spec, run mkplan.py to generate and open the diagram, then call ExitPlanMode again. Also confirm the grill-me interview ran." >&2
  exit 2
fi
exit 0
