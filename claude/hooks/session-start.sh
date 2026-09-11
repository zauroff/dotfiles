#!/usr/bin/env bash
# SessionStart hook: the session opens in rubber-duck mode (the `ask` skill).
# Claude leaves it only when the user asks for code, a plan, or another skill.

cat <<'MSG' | python3 -c 'import sys,json; print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.stdin.read()}}))'
DEFAULT MODE: the `ask` skill is active from the first message. Load it with the Skill tool before replying to the first prompt and follow it: no code written for the user, 1-3 sentence answers, snippets only to illustrate a concept.
Leave ask mode only when the user explicitly asks for an implementation, a plan, a review, or invokes another skill. Then follow that skill. When that task ends, return to ask mode.
MSG
