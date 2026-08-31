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
        sed -i '' 's/^theme = Gruvbox Dark$/theme = Gruvbox Light/' "$GHOSTTY_CONFIG"
        sed -i '' 's/^custom-shader = crt\.glsl$/custom-shader = crt-light.glsl/' "$GHOSTTY_CONFIG"
    else
        sed -i '' 's/^theme = Gruvbox Light$/theme = Gruvbox Dark/' "$GHOSTTY_CONFIG"
        sed -i '' 's/^custom-shader = crt-light\.glsl$/custom-shader = crt.glsl/' "$GHOSTTY_CONFIG"
    fi
fi

# --- WezTerm ---
mkdir -p "$HOME/.config/wezterm"
echo "$target" > "$HOME/.config/wezterm/.theme-mode"

# --- Neovim ---
mkdir -p "$HOME/.config/nvim"
echo "$target" > "$HOME/.config/nvim/.theme-mode"

# --- VSCode ---
# VSCode has no theme-file watcher, so rewrite the setting in place. It picks
# up settings.json changes live, no reload needed.
# Resolve the symlink first: macOS sed -i writes a temp file and renames it over
# the target, which would replace install.sh's symlink with a regular file.
VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
VSCODE_SETTINGS="$(readlink -f "$VSCODE_SETTINGS" 2>/dev/null || echo "$VSCODE_SETTINGS")"
if [ -f "$VSCODE_SETTINGS" ]; then
    if [ "$target" = "light" ]; then
        sed -i '' 's/"workbench.colorTheme": "Gruvbox Dark Soft"/"workbench.colorTheme": "Gruvbox Light Soft"/' "$VSCODE_SETTINGS"
    else
        sed -i '' 's/"workbench.colorTheme": "Gruvbox Light Soft"/"workbench.colorTheme": "Gruvbox Dark Soft"/' "$VSCODE_SETTINGS"
    fi
fi

# --- Save state ---
echo "$target" > "$STATE_FILE"
echo "Switched to $target mode"
