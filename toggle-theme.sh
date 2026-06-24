#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="$HOME/.config/.current-theme"
current=$(cat "$STATE_FILE" 2>/dev/null || echo "dark")

# Accept optional arg to force a mode, otherwise toggle
if [ "${1:-}" = "dark" ] || [ "${1:-}" = "light" ]; then
    target="$1"
else
    [ "$current" = "dark" ] && target="light" || target="dark"
fi

[ "$current" = "$target" ] && { echo "Already in $target mode"; exit 0; }

# --- Ghostty ---
GHOSTTY_CONFIG="$(readlink -f "$HOME/.config/ghostty/config" 2>/dev/null || echo "$HOME/.config/ghostty/config")"
if [ -f "$GHOSTTY_CONFIG" ]; then
    if [ "$target" = "light" ]; then
        sed -i '' 's/^background = 000000$/background = f9f9f9/' "$GHOSTTY_CONFIG"
        sed -i '' 's/^foreground = ffffff$/foreground = 000000/' "$GHOSTTY_CONFIG"
        sed -i '' 's/^custom-shader = crt\.glsl$/custom-shader = crt-light.glsl/' "$GHOSTTY_CONFIG"
    else
        sed -i '' 's/^background = f9f9f9$/background = 000000/' "$GHOSTTY_CONFIG"
        sed -i '' 's/^foreground = 000000$/foreground = ffffff/' "$GHOSTTY_CONFIG"
        sed -i '' 's/^custom-shader = crt-light\.glsl$/custom-shader = crt.glsl/' "$GHOSTTY_CONFIG"
    fi
fi

# --- WezTerm ---
mkdir -p "$HOME/.config/wezterm"
echo "$target" > "$HOME/.config/wezterm/.theme-mode"

# --- Neovim ---
mkdir -p "$HOME/.config/nvim"
echo "$target" > "$HOME/.config/nvim/.theme-mode"

# --- Save state ---
echo "$target" > "$STATE_FILE"
echo "Switched to $target mode"
