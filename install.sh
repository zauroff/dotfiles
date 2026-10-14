#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Link $DOTFILES/$1 to $2. When local/$1 exists, write $1 deep-merged with it to $2
# instead: local/ is gitignored and holds machine-specific (work) settings. The
# merged file is a copy, so edit the repo files and rerun install.sh.
link_or_merge() {
  local src="$DOTFILES/$1" over="$DOTFILES/local/$1" dest="$2" tmp
  # A regular file at $2 is an earlier merge and may hold edits made in the app.
  if [ -f "$dest" ] && [ ! -L "$dest" ]; then cp "$dest" "$dest.bak"; fi
  if [ ! -f "$over" ]; then
    ln -sf "$src" "$dest"
    echo "Linked $1 -> $dest"
    return
  fi
  tmp="$(mktemp -t dotfiles-merge)"
  # Output is plain JSON, no header comment: some readers (Claude Code) reject JSONC.
  node -e '
    const fs = require("fs")
    // JSONC (comments, trailing commas) is valid JS, so evaluate it instead of adding a parser.
    const read = f => new Function(`return (${fs.readFileSync(f, "utf8")}\n)`)()
    const isObj = v => v?.constructor === Object
    const merge = (a, b) => {
      for (const k in b) a[k] = isObj(a[k]) && isObj(b[k]) ? merge(a[k], b[k]) : b[k]
      return a
    }
    console.log(JSON.stringify(merge(read(process.argv[1]), read(process.argv[2])), null, 2))
  ' "$src" "$over" >"$tmp"
  # mv replaces a symlink at $2 instead of writing through it into the repo file.
  mv "$tmp" "$dest"
  echo "Merged $1 + local/$1 -> $dest"
}

# Run work-specific setup if present (gitignored)
if [ -f "$DOTFILES/work.sh" ]; then
  bash "$DOTFILES/work.sh"
fi

brew bundle --file="$DOTFILES/Brewfile" --no-upgrade
echo "Installed Brewfile packages"

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

# Generate the iTerm2 dynamic profile. Not a symlink: toggle-theme.sh rewrites
# the file on every theme switch, and iTerm2 reloads it into open sessions.
if [ -d "/Applications/iTerm.app" ] || [ -d "$HOME/Applications/iTerm.app" ]; then
  ITERM_PROFILES="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  mkdir -p "$ITERM_PROFILES"
  # Stage outside DynamicProfiles: iTerm2 parses every file in that directory,
  # so a half-written temp file inside it raises an "invalid JSON" alert.
  ITERM_TMP="$(mktemp -t iterm-dotfiles)"
  bash "$DOTFILES/iterm2/gen-profile.sh" "$(cat "$HOME/.config/.current-theme")" >"$ITERM_TMP"
  mv "$ITERM_TMP" "$ITERM_PROFILES/dotfiles.json"
  echo "Wrote iterm2/gen-profile.sh output -> $ITERM_PROFILES/dotfiles.json"

  # Which profile is the default is app-level state, not part of the dynamic
  # profile. iTerm2 overwrites its plist on quit, so only set it while closed.
  if pgrep -x iTerm2 >/dev/null 2>&1; then
    echo "NOTE: iTerm2 is running; set the \"dotfiles\" profile as default yourself (Settings > Profiles > Other Actions)"
  else
    defaults write com.googlecode.iterm2 "Default Bookmark Guid" \
      -string "$(jq -r .Guid "$DOTFILES/iterm2/profile.json")"
    echo "Set iTerm2 default profile to dotfiles"
  fi
else
  echo "Skipped iTerm2 (not installed)"
fi

# Link Claude config
mkdir -p "$HOME/.claude/skills" "$HOME/.claude/hooks" "$HOME/.claude/output-styles" "$HOME/.claude/agents" "$HOME/.claude/themes"
link_or_merge claude/settings.json "$HOME/.claude/settings.json"
ln -sf "$DOTFILES/claude/statusline.sh" "$HOME/.claude/statusline.sh"
for skill in "$DOTFILES/skills"/*/; do
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

# Link Codex config and the shared skills.
mkdir -p "$HOME/.codex/skills"
ln -sf "$DOTFILES/codex/config.toml" "$HOME/.codex/config.toml"
for skill in "$DOTFILES/skills"/*/; do
  [ -d "$skill" ] && ln -sfn "$skill" "$HOME/.codex/skills/$(basename "$skill")"
done
find "$HOME/.codex/skills" -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
echo "Linked codex/config.toml -> ~/.codex/config.toml"
echo "Linked skills/ -> ~/.claude/skills and ~/.codex/skills"

# Link CLAUDE.md to home directory
ln -sf "$DOTFILES/claude/CLAUDE.md" "$HOME/CLAUDE.md"
echo "Linked claude/CLAUDE.md -> ~/CLAUDE.md"

# Install diagram tools used by the visualize skill's maker agents
command -v mmdc >/dev/null 2>&1 || npm i -g @mermaid-js/mermaid-cli
echo "Checked diagram tools (mmdc)"

# Link Obsidian theme into the vault
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/DANIEL ZAUROFF}"
if [ -d "$OBSIDIAN_VAULT/.obsidian" ]; then
  mkdir -p "$OBSIDIAN_VAULT/.obsidian/themes"
  ln -sfn "$DOTFILES/obsidian/themes/Asiimov" "$OBSIDIAN_VAULT/.obsidian/themes/Asiimov"
  echo "Linked obsidian/themes/Asiimov -> $OBSIDIAN_VAULT/.obsidian/themes/Asiimov"
else
  echo "Skipped Obsidian (no vault at $OBSIDIAN_VAULT)"
fi

# Link the oh-my-zsh prompt theme. ~/.zshrc selects it with ZSH_THEME="asiimov".
if [ -d "$HOME/.oh-my-zsh" ]; then
  ZSH_THEMES="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes"
  mkdir -p "$ZSH_THEMES"
  ln -sf "$DOTFILES/zsh/asiimov.zsh-theme" "$ZSH_THEMES/asiimov.zsh-theme"
  echo "Linked zsh/asiimov.zsh-theme -> $ZSH_THEMES/asiimov.zsh-theme"
else
  echo "Skipped oh-my-zsh theme (no ~/.oh-my-zsh)"
fi

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

# Link JetBrains keymap into every installed GoLand version
for kmdir in "$HOME/Library/Application Support/JetBrains"/GoLand*/keymaps; do
  [ -d "$kmdir" ] || continue
  ln -sf "$DOTFILES/jetbrains/keymaps/zauroff's.xml" "$kmdir/zauroff's.xml"
  echo "Linked jetbrains/keymaps/zauroff's.xml -> $kmdir/zauroff's.xml"
done

# Link VSCode config
VSCODE_USER="$HOME/Library/Application Support/Code/User"
if [ -d "$(dirname "$VSCODE_USER")" ]; then
  mkdir -p "$VSCODE_USER"

  link_or_merge vscode/settings.json "$VSCODE_USER/settings.json"
  ln -sf "$DOTFILES/vscode/keybindings.json" "$VSCODE_USER/keybindings.json"
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

    # Local extensions. VSCode ignores folders linked into ~/.vscode/extensions once extensions.json exists, so
    # package each as a .vsix, which is a zip with the extension under extension/.
    for dir in "$DOTFILES"/vscode/extensions/*/; do
      name="$(basename "$dir")"
      tmp="$(mktemp -d)"
      mkdir "$tmp/extension" && cp -R "$dir". "$tmp/extension/"
      (cd "$tmp" && zip -qr "$name.vsix" extension)
      code --install-extension "$tmp/$name.vsix" --force >/dev/null 2>&1 && echo "Installed local extension $name" ||
        echo "  failed: $name"
      rm -rf "$tmp"
    done
  else
    echo "Skipped VSCode extensions (no \`code\` CLI on PATH)"
  fi

  echo "NOTE: run \"Enable Custom CSS and JS\" from the Command Palette, then restart"
else
  echo "Skipped VSCode (not installed)"
fi
