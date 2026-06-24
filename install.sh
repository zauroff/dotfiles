#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Link wezterm.lua
ln -sf "$DOTFILES/wezterm.lua" "$HOME/.wezterm.lua"
echo "Linked wezterm.lua -> ~/.wezterm.lua"

# Link nvim config
mkdir -p "$HOME/.config"
ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"
echo "Linked nvim -> ~/.config/nvim"

# Link .ideavimrc
ln -sf "$DOTFILES/.ideavimrc" "$HOME/.ideavimrc"
echo "Linked .ideavimrc -> ~/.ideavimrc"

# Link ghostty config
mkdir -p "$HOME/.config/ghostty"
ln -sfn "$DOTFILES/ghostty/config" "$HOME/.config/ghostty/config"
ln -sfn "$DOTFILES/ghostty/crt.glsl" "$HOME/.config/ghostty/crt.glsl"
ln -sfn "$DOTFILES/ghostty/crt-light.glsl" "$HOME/.config/ghostty/crt-light.glsl"
echo "Linked ghostty/config -> ~/.config/ghostty/config"
echo "Linked ghostty/crt.glsl -> ~/.config/ghostty/crt.glsl"
echo "Linked ghostty/crt-light.glsl -> ~/.config/ghostty/crt-light.glsl"

# Initialize theme state files (default to dark)
[ -f "$HOME/.config/.current-theme" ] || echo "dark" > "$HOME/.config/.current-theme"
mkdir -p "$HOME/.config/wezterm"
[ -f "$HOME/.config/wezterm/.theme-mode" ] || echo "dark" > "$HOME/.config/wezterm/.theme-mode"
[ -f "$HOME/.config/nvim/.theme-mode" ] || echo "dark" > "$HOME/.config/nvim/.theme-mode"
echo "Initialized theme state files (dark mode)"

# Link Claude config
mkdir -p "$HOME/.claude/skills"
ln -sf "$DOTFILES/claude/.claude/settings.json" "$HOME/.claude/settings.json"
for skill in "$DOTFILES/claude/.claude/skills"/*/; do
  [ -d "$skill" ] && ln -sfn "$skill" "$HOME/.claude/skills/$(basename "$skill")"
done
echo "Linked claude/.claude -> ~/.claude (settings + skills)"

# Link CLAUDE.md to home directory
ln -sf "$DOTFILES/claude/.config/CLAUDE.md" "$HOME/CLAUDE.md"
echo "Linked claude/.config/CLAUDE.md -> ~/CLAUDE.md"

# Link aerospace.toml
ln -sf "$DOTFILES/aerospace.toml" "$HOME/.aerospace.toml"
echo "Linked aerospace.toml -> ~/.aerospace.toml"

# Link zdev to ~/.local/bin so it's on PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$DOTFILES/zdev.sh" "$HOME/.local/bin/zdev"
echo "Linked zdev.sh -> ~/.local/bin/zdev"
