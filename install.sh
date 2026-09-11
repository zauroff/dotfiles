#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Run work-specific setup if present (gitignored)
if [ -f "$DOTFILES/work.sh" ]; then
  bash "$DOTFILES/work.sh"
fi

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
ln -sfn "$DOTFILES/ghostty/themes" "$HOME/.config/ghostty/themes"
echo "Linked ghostty/config -> ~/.config/ghostty/config"
echo "Linked ghostty/crt.glsl -> ~/.config/ghostty/crt.glsl"
echo "Linked ghostty/crt-light.glsl -> ~/.config/ghostty/crt-light.glsl"
echo "Linked ghostty/themes -> ~/.config/ghostty/themes"

# Initialize theme state files (default to dark)
[ -f "$HOME/.config/.current-theme" ] || echo "dark" >"$HOME/.config/.current-theme"
mkdir -p "$HOME/.config/wezterm"
[ -f "$HOME/.config/wezterm/.theme-mode" ] || echo "dark" >"$HOME/.config/wezterm/.theme-mode"
[ -f "$HOME/.config/nvim/.theme-mode" ] || echo "dark" >"$HOME/.config/nvim/.theme-mode"
echo "Initialized theme state files (dark mode)"

# Link Claude config
mkdir -p "$HOME/.claude/skills" "$HOME/.claude/hooks" "$HOME/.claude/output-styles" "$HOME/.claude/agents" "$HOME/.claude/themes"
ln -sf "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
ln -sf "$DOTFILES/claude/statusline.sh" "$HOME/.claude/statusline.sh"
for skill in "$DOTFILES/claude/skills"/*/; do
  [ -d "$skill" ] && ln -sfn "$skill" "$HOME/.claude/skills/$(basename "$skill")"
done
for hook in "$DOTFILES/claude/hooks"/*; do
  [ -f "$hook" ] && ln -sf "$hook" "$HOME/.claude/hooks/$(basename "$hook")"
done
for style in "$DOTFILES/claude/output-styles"/*.md; do
  [ -f "$style" ] && ln -sf "$style" "$HOME/.claude/output-styles/$(basename "$style")"
done
for agent in "$DOTFILES/claude/agents"/*.md; do
  [ -f "$agent" ] && ln -sf "$agent" "$HOME/.claude/agents/$(basename "$agent")"
done
for theme in "$DOTFILES/claude/themes"/*.json; do
  [ -f "$theme" ] && ln -sf "$theme" "$HOME/.claude/themes/$(basename "$theme")"
done
# Drop symlinks whose source left the repo (e.g. a renamed hook).
find "$HOME/.claude/hooks" "$HOME/.claude/skills" "$HOME/.claude/output-styles" "$HOME/.claude/agents" "$HOME/.claude/themes" \
  -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
echo "Linked claude/ -> ~/.claude (settings + skills + hooks + agents + output styles + themes)"

# Link CLAUDE.md to home directory
ln -sf "$DOTFILES/claude/CLAUDE.md" "$HOME/CLAUDE.md"
echo "Linked claude/CLAUDE.md -> ~/CLAUDE.md"

# Install diagram tools used by the visualize skill's maker agents
command -v rsvg-convert >/dev/null 2>&1 || brew install librsvg
command -v mmdc >/dev/null 2>&1 || npm i -g @mermaid-js/mermaid-cli
echo "Checked diagram tools (rsvg-convert, mmdc)"

# Link aerospace.toml
ln -sf "$DOTFILES/aerospace.toml" "$HOME/.aerospace.toml"
echo "Linked aerospace.toml -> ~/.aerospace.toml"

# Link zdev to ~/.local/bin so it's on PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$DOTFILES/zdev.sh" "$HOME/.local/bin/zdev"
echo "Linked zdev.sh -> ~/.local/bin/zdev"

# Link opencode config
mkdir -p "$HOME/.config"
ln -sfn "$DOTFILES/opencode" "$HOME/.config/opencode"
echo "Linked opencode -> ~/.config/opencode"

# Link VSCode config
VSCODE_USER="$HOME/Library/Application Support/Code/User"
if [ -d "$(dirname "$VSCODE_USER")" ]; then
  mkdir -p "$VSCODE_USER"

  ln -sf "$DOTFILES/vscode/settings.json" "$VSCODE_USER/settings.json"
  ln -sf "$DOTFILES/vscode/keybindings.json" "$VSCODE_USER/keybindings.json"
  echo "Linked vscode/settings.json    -> $VSCODE_USER/settings.json"
  echo "Linked vscode/keybindings.json -> $VSCODE_USER/keybindings.json"

  # Install missing extensions. Skipped when the `code` CLI is not on PATH
  # (Command Palette > "Shell Command: Install 'code' command in PATH").
  if command -v code >/dev/null 2>&1 && [ -f "$DOTFILES/vscode/extensions.txt" ]; then
    installed="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    missing=0
    while IFS= read -r ext; do
      [ -z "$ext" ] && continue
      if ! printf '%s\n' "$installed" | grep -qxF "$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"; then
        echo "  installing $ext"
        code --install-extension "$ext" --force >/dev/null 2>&1 || echo "  failed: $ext"
        missing=$((missing + 1))
      fi
    done <"$DOTFILES/vscode/extensions.txt"
    echo "VSCode extensions: $missing installed, $(wc -l <"$DOTFILES/vscode/extensions.txt" | tr -d ' ') tracked"
  else
    echo "Skipped VSCode extensions (no \`code\` CLI on PATH)"
  fi

  echo "NOTE: run \"Enable Custom CSS and JS\" from the Command Palette, then restart"
else
  echo "Skipped VSCode (not installed)"
fi
