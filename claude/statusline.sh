#!/usr/bin/env bash
# Claude Code statusLine
# Shows: model | effort | turn | context bar + % + tokens, then dir | git branch + status | time | weather
# Boltz palette (dark or light from ~/.config/.current-theme). No emojis.
# Rendered on every update, so anything slow (weather) is cached + refreshed in background.
input=$(cat)

US=$'\x1f'
IFS="$US" read -r cwd model_id model transcript effort ctx_window ctx_pct tokens <<EOF
$(echo "$input" | jq -r --arg us "$US" '[
  (.workspace.current_dir // .cwd // ""),
  (.model.id // ""),
  (.model.display_name // ""),
  (.transcript_path // ""),
  (.effort.level // ""),
  (.context_window.context_window_size // ""),
  (.context_window.used_percentage // ""),
  (if .context_window.current_usage then
     (.context_window.current_usage.input_tokens // 0)
     + (.context_window.current_usage.cache_read_input_tokens // 0)
     + (.context_window.current_usage.cache_creation_input_tokens // 0)
   else "" end)
] | map(tostring) | join($us)')
EOF

dir=$(basename "$cwd")

# --- git branch + status ---
branch=""
gitstatus=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$dirty" -gt 0 ]; then
    gitstatus="✗${dirty}"
  else
    gitstatus="✓"
  fi
fi

base_id="${model_id%\[*\]}"
if [[ "$base_id" =~ ^claude-([a-z]+)-([0-9]+)(-([0-9]{1,2}))?($|[^0-9]) ]]; then
  model_h="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
  [ -n "${BASH_REMATCH[4]}" ] && model_h+=".${BASH_REMATCH[4]}"
else
  model_h="${base_id:-$model}"
fi
case "$model_id" in
  *"[1m]"*) model_h+=" 1m" ;;
  *) [ "${ctx_window:-0}" -ge 1000000 ] 2>/dev/null && model_h+=" 1m" ;;
esac

if [ -z "$effort" ] && [ -f "$HOME/.claude/settings.json" ]; then
  effort=$(jq -r --arg m "$base_id" '.modelSettings[$m].effortLevel // .effortLevel // ""' \
    "$HOME/.claude/settings.json" 2>/dev/null)
fi

turn=0
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  turn=$(grep -o '"promptIndex":[0-9]*' "$transcript" 2>/dev/null | tail -1 | cut -d: -f2)
fi
turn=$(printf '%02d' "${turn:-0}")

# --- context usage from transcript ---
# case "$model_id$model" in
#   *1m*|*1M*) ctx_window=1000000 ;;
#   *)         ctx_window=200000 ;;
# esac
# note: as of the latest models, most have a context window of 1m tokens
[ -z "$ctx_window" ] && ctx_window=1000000
if [ -z "$tokens" ]; then
  tokens=0
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    usage=$(grep '"usage"' "$transcript" 2>/dev/null | tail -1)
    if [ -n "$usage" ]; then
      tokens=$(echo "$usage" | jq '
        (.message.usage.input_tokens // 0)
        + (.message.usage.cache_read_input_tokens // 0)
        + (.message.usage.cache_creation_input_tokens // 0)' 2>/dev/null)
      [ -z "$tokens" ] && tokens=0
    fi
  fi
fi

if [ -n "$ctx_pct" ]; then
  pct=$(printf '%.0f' "$ctx_pct")
else
  pct=$((tokens * 100 / ctx_window))
fi
[ "$pct" -gt 100 ] && pct=100
if [ "$tokens" -ge 1000 ]; then
  tok_h=$(awk "BEGIN{printf \"%.1fk\", $tokens/1000}")
else
  tok_h="$tokens"
fi

# --- context progress bar ---
bar_width=10
filled=$(((pct * bar_width + 50) / 100))
[ "$filled" -gt "$bar_width" ] && filled=$bar_width
filled_str=""
empty_str=""
i=0
while [ "$i" -lt "$filled" ]; do
  filled_str="${filled_str}█"
  i=$((i + 1))
done
i=$filled
while [ "$i" -lt "$bar_width" ]; do
  empty_str="${empty_str}░"
  i=$((i + 1))
done

# --- time ---
now=$(date +%H:%M)

# --- weather (cached, refreshed in background every 30 min; text, no emoji) ---
weather_cache="$HOME/.claude/.weather_cache"
weather_max_age=1800
refresh_weather=0
if [ ! -f "$weather_cache" ]; then
  refresh_weather=1
else
  age=$(($(date +%s) - $(stat -f %m "$weather_cache" 2>/dev/null || echo 0)))
  [ "$age" -gt "$weather_max_age" ] && refresh_weather=1
fi
if [ "$refresh_weather" -eq 1 ]; then
  (curl -fs --max-time 3 "wttr.in/?format=%C+%t" -o "$weather_cache" 2>/dev/null &) >/dev/null 2>&1
fi
weather=$(cat "$weather_cache" 2>/dev/null | tr -d '\n' | sed 's/^ *//;s/ *$//')

# --- colors (boltz palette, foreground only) ---
theme=$(cat "$HOME/.config/.current-theme" 2>/dev/null)
rgb() { printf '\033[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
if [ "$theme" = "light" ]; then
  INK=$(rgb 161616) GRAY=$(rgb 77776f) DIM=$(rgb c2c2bb) ORANGE=$(rgb ff4f00)
  BLUE=$(rgb 0047ff) GREEN=$(rgb 00995c) WHITE=$(rgb 161616)
else
  INK=$(rgb f0f0ec) GRAY=$(rgb 8a8a85) DIM=$(rgb 3a3a37) ORANGE=$(rgb ff5a1f)
  BLUE=$(rgb 3d7bff) GREEN=$(rgb 1fc77a) WHITE=$(rgb f0f0ec)
fi
BOLD=$'\033[1m'
NB=$'\033[22m'
RESET=$'\033[0m'

knob() { printf '%s◉%s %s %s%s%s%s' "$1" "$GRAY" "$2" "$BOLD" "$INK" "$3" "$NB"; }
gap="   "
sep="${GRAY}  ·  "

knobs="$(knob "$BLUE" MODEL "$model_h")"
[ -n "$effort" ] && knobs+="${gap}$(knob "$GREEN" EFFORT "$effort")"
knobs+="${gap}$(knob "$ORANGE" TURN "$turn")"
knobs+="${gap}${WHITE}◉${GRAY} CONTEXT ${ORANGE}${filled_str}${DIM}${empty_str} ${BOLD}${INK}${pct}%${NB} ${GRAY}${tok_h}"

line="${BOLD}${ORANGE}${dir}${NB}"
[ -n "$branch" ] && line+="${sep}${INK}${branch} ${ORANGE}${gitstatus}"
line+="${sep}${INK}${now}"
[ -n "$weather" ] && line+="${sep}${INK}${weather}"

printf '%s%s\n%s%s\n' "$knobs" "$RESET" "$line" "$RESET"
