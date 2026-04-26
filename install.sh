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

# Link zdev to ~/.local/bin so it's on PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$DOTFILES/zdev.sh" "$HOME/.local/bin/zdev"
echo "Linked zdev.sh -> ~/.local/bin/zdev"
