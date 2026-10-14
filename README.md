# dotfiles

my personal dotfiles for nvim, vscode, terminals, tiling, ai stuff, etc.
`install.sh` installs and symlinks everything.

## Install

Requirements: macOS, [Homebrew](https://brew.sh), Node.js (npm), and [oh-my-zsh](https://ohmyz.sh).

```sh
git clone <this repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` runs `brew bundle` on the `Brewfile`, then links each config below. It is safe to run again. Tools it skips when missing: iTerm2, VSCode, Obsidian, oh-my-zsh, GoLand.

Install these separately: Claude Code, Codex, Obsidian, GoLand.

## Tools

| Tool              | Files                                                                                | Installed to                                                                |
| ----------------- | ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| Neovim (LazyVim)  | `nvim/`                                                                              | `~/.config/nvim`                                                            |
| VSCode            | `vscode/settings.json`, `vscode/keybindings.json`                                    | `~/Library/Application Support/Code/User`                                   |
| VSCode extensions | `vscode/extensions.txt`, `vscode/extensions/`                                        | installed with the `code` CLI                                               |
| IdeaVim           | `.ideavimrc`                                                                         | `~/.ideavimrc`                                                              |
| GoLand keymap     | `jetbrains/keymaps/`                                                                 | the keymaps folder of each GoLand version                                   |
| Ghostty           | `ghostty/` (config, CRT shaders, themes)                                             | `~/.config/ghostty`                                                         |
| WezTerm           | `wezterm.lua`                                                                        | `~/.wezterm.lua`                                                            |
| iTerm2            | `iterm2/`                                                                            | generated profile in `~/Library/Application Support/iTerm2/DynamicProfiles` |
| AeroSpace         | `aerospace.toml`                                                                     | `~/.aerospace.toml`                                                         |
| zsh prompt        | `zsh/asiimov.zsh-theme`                                                              | oh-my-zsh custom themes; select with `ZSH_THEME="asiimov"`                  |
| Claude Code       | `claude/` (settings, hooks, agents, output styles, themes, status line, `CLAUDE.md`) | `~/.claude`, `~/CLAUDE.md`                                                  |
| Codex             | `codex/config.toml`                                                                  | `~/.codex/config.toml`                                                      |
| Agent skills      | `skills/`                                                                            | `~/.claude/skills`, `~/.codex/skills`                                       |
| opencode          | `opencode/`                                                                          | `~/.config/opencode`                                                        |
| Obsidian theme    | `obsidian/themes/Asiimov`                                                            | `.obsidian/themes` in the vault at `$OBSIDIAN_VAULT`                        |

## Scripts

| Script                          | What it does                                                                                                                 |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `install.sh`                    | Installs `Brewfile` packages and links all configs.                                                                          |
| `toggle-theme.sh [dark\|light]` | Switches Ghostty, iTerm2, WezTerm, Neovim, VSCode, and Claude Code to one theme. With no argument, it toggles. Use with `gt` |
| `zdev.sh`                       | Splits the current WezTerm tab into Neovim, Claude Code, lazygit, and a shell. `install.sh` links it to `~/.local/bin/zdev`. |

## Machine-local settings

Settings for one machine only (for example, work proxies) go in `local/`. Git ignores `local/`.

- `local/` uses the same paths as the repo. `local/vscode/settings.json` overrides `vscode/settings.json`.
- When a local file exists, `install.sh` merges it over the repo file and writes the result as a real file, not a symlink. Local values win. Nested objects merge key by key. Lists are replaced.
- Supported now: `vscode/settings.json`, `claude/settings.json`.
- To change a merged setting, edit the repo file or the local file, then run `./install.sh`.
- Changes made inside an app go to the merged file only. The next `./install.sh` overwrites them and keeps the old file as `settings.json.bak`.

Other local files, also ignored by git:

- `work.sh`: runs at the start of `install.sh` when present.
- `nvim/lua/plugins/local.lua`: Neovim plugins for this machine only.
