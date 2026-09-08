#!/usr/bin/env bash
# Stop hook: mirror the just-finished assistant turn into the active lesson file.
set -euo pipefail

ACTIVE="$HOME/.claude/learn-active"
[ -f "$ACTIVE" ] || exit 0
LESSON="$(cat "$ACTIVE")"
[ -f "$LESSON" ] || exit 0

INPUT="$(cat)"
TRANSCRIPT="$(jq -r '.transcript_path // empty' <<<"$INPUT")"
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || exit 0

TEXT="$(jq -s -r '
  def is_real_user:
    .type == "user"
    and (
      (.message.content | type) == "string"
      or ( (.message.content | type) == "array"
           and ([.message.content[] | select(.type == "tool_result")] | length == 0) )
    );
  . as $all
  | ([range(0; length) | select($all[.] | is_real_user)] | last // -1) as $cut
  | ($all[($cut+1):]) as $trail
  | ([ $trail[] | select(.type == "assistant") | .message.content[]?
       | select(.type == "tool_use" and .name == "AskUserQuestion") | .id ]) as $askIds
  | [ $trail[] |
      if .type == "assistant" then
        ( .message.content[]? |
          if .type == "text" then .text
          elif .type == "tool_use" and .name == "AskUserQuestion" then
            ((.input.questions? // [.input]) as $qs
              | [ $qs[] |
                  "> **Q:** " + .question,
                  ( .options[]? | "> - " + .label + " — " + .description )
                ] | join("\n")
            )
          else empty
          end
        )
      elif .type == "user" and (.message.content | type) == "array" then
        ( .message.content[]
          | select(.type == "tool_result" and (.tool_use_id as $id | $askIds | index($id)))
          | "> **A:** " + (.content | if type == "string" then . else ([.[] | select(.type == "text") | .text] | join("\n")) end)
        )
      else empty
      end
    ] | map(select(length > 0)) | join("\n\n")
' "$TRANSCRIPT")"

[ -n "$TEXT" ] || exit 0

printf '\n---\n\n%s\n' "$TEXT" >> "$LESSON"
