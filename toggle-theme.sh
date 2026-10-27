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
    # The boltz themes set their own background, so only the theme line flips. The
    # shader patterns are deliberately unanchored so they keep matching while those
    # lines are commented out.
    if [ "$target" = "light" ]; then
        sed -i '' 's/^theme = boltz-dark$/theme = boltz-light/' "$GHOSTTY_CONFIG"
        sed -i '' 's/custom-shader = crt\.glsl/custom-shader = crt-light.glsl/' "$GHOSTTY_CONFIG"
    else
        sed -i '' 's/^theme = boltz-light$/theme = boltz-dark/' "$GHOSTTY_CONFIG"
        sed -i '' 's/custom-shader = crt-light\.glsl/custom-shader = crt.glsl/' "$GHOSTTY_CONFIG"
    fi
fi

# --- iTerm2 ---
# iTerm2 watches DynamicProfiles and pushes reloaded colors into open sessions,
# so rewriting the file is the whole switch. Stage the file outside that
# directory: iTerm2 parses every file it finds there, so a half-written temp
# file inside it raises an "invalid JSON" alert.
DOTFILES="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
ITERM_PROFILES="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
if [ -d "$ITERM_PROFILES" ]; then
    tmp="$(mktemp -t iterm-dotfiles)"
    bash "$DOTFILES/iterm2/gen-profile.sh" "$target" >"$tmp"
    mv "$tmp" "$ITERM_PROFILES/dotfiles.json"
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
    [ "$target" = "light" ] && vscode_theme="Boltz Light" || vscode_theme="Boltz Dark"
    sed -i '' -E "s/\"workbench.colorTheme\": \"[^\"]*\"/\"workbench.colorTheme\": \"$vscode_theme\"/" "$VSCODE_SETTINGS"
fi

# --- Claude Code ---
# Custom themes in claude/themes/boltz-{dark,light}.json. The boltz mod follows
# this setting. Resolve the symlink first for the same reason as VSCode above.
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLAUDE_SETTINGS="$(readlink -f "$CLAUDE_SETTINGS" 2>/dev/null || echo "$CLAUDE_SETTINGS")"
if [ -f "$CLAUDE_SETTINGS" ]; then
    sed -i '' -E "s/\"theme\": \"(custom:[^\"]*|light|dark)\"/\"theme\": \"custom:boltz-$target\"/" "$CLAUDE_SETTINGS"
fi

# --- Save state ---
echo "$target" > "$STATE_FILE"
echo "Switched to $target mode"
