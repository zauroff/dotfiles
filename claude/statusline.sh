#!/usr/bin/env bash
# Claude Code statusLine
# Shows: dir | git branch + status | context bar + % + tokens | time | weather
# White background, Claude-orange accents. No emojis.
# Rendered on every update, so anything slow (weather) is cached + refreshed in background.
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_id=$(echo "$input" | jq -r '.model.id // ""')
model=$(echo "$input" | jq -r '.model.display_name')
transcript=$(echo "$input" | jq -r '.transcript_path // ""')

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

# --- context usage from transcript ---
case "$model_id$model" in
  *1m*|*1M*) ctx_window=1000000 ;;
  *)         ctx_window=200000 ;;
esac

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

pct=$(( tokens * 100 / ctx_window ))
[ "$pct" -gt 100 ] && pct=100
if [ "$tokens" -ge 1000 ]; then
  tok_h=$(awk "BEGIN{printf \"%.1fk\", $tokens/1000}")
else
  tok_h="$tokens"
fi

# --- context progress bar ---
bar_width=8
filled=$(( pct * bar_width / 100 ))
[ "$filled" -gt "$bar_width" ] && filled=$bar_width
filled_str=""; empty_str=""
i=0; while [ "$i" -lt "$filled" ]; do filled_str="${filled_str}█"; i=$((i+1)); done
i=$filled; while [ "$i" -lt "$bar_width" ]; do empty_str="${empty_str}░"; i=$((i+1)); done

# --- time ---
now=$(date +%H:%M)

# --- weather (cached, refreshed in background every 30 min; text, no emoji) ---
weather_cache="$HOME/.claude/.weather_cache"
weather_max_age=1800
refresh_weather=0
if [ ! -f "$weather_cache" ]; then
  refresh_weather=1
else
  age=$(( $(date +%s) - $(stat -f %m "$weather_cache" 2>/dev/null || echo 0) ))
  [ "$age" -gt "$weather_max_age" ] && refresh_weather=1
fi
if [ "$refresh_weather" -eq 1 ]; then
  ( curl -fs --max-time 3 "wttr.in/?format=%C+%t" -o "$weather_cache" 2>/dev/null & ) >/dev/null 2>&1
fi
weather=$(cat "$weather_cache" 2>/dev/null | tr -d '\n' | sed 's/^ *//;s/ *$//')

# --- colors (foreground only; bg set once so the whole line stays white) ---
BG=$'\033[48;2;255;255;255m'      # white background
ORANGE=$'\033[38;2;217;119;87m'   # Claude orange
DARK=$'\033[38;2;70;70;70m'       # near-black text
GRAY=$'\033[38;2;155;155;155m'    # dim separators / empty bar
BOLD=$'\033[1m'
NB=$'\033[22m'
RESET=$'\033[0m'

sep="${GRAY}  ·  "

line="${BG} ${BOLD}${ORANGE}${dir}${NB}"
[ -n "$branch" ] && line+="${sep}${DARK}${branch} ${ORANGE}${gitstatus}"
line+="${sep}${ORANGE}${filled_str}${GRAY}${empty_str} ${ORANGE}${pct}% ${DARK}${tok_h}"
line+="${sep}${DARK}${now}"
[ -n "$weather" ] && line+="${sep}${DARK}${weather}"
line+=" ${RESET}"

printf '%s\n' "$line"
