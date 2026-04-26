#!/bin/bash

DIR="$(pwd)"

# Start in the current pane as top-left (NVIM)
wezterm cli send-text --no-paste "cd $DIR && nvim"$'\n'

# Split right for top-right (CLAUDE) — right column gets 35% width
claude_pane_id=$(wezterm cli split-pane --right --percent 35)
wezterm cli send-text --pane-id "$claude_pane_id" --no-paste "cd $DIR && claude"$'\n'

# Split the top-right pane down for bottom-right (LAZYGIT)
lazygit_pane_id=$(wezterm cli split-pane --pane-id "$claude_pane_id" --bottom --percent 50)
wezterm cli send-text --pane-id "$lazygit_pane_id" --no-paste "cd $DIR && lazygit"$'\n'

# Split the top-left (nvim) pane down for bottom-left (TERMINAL) — terminal gets 30% height
terminal_pane_id=$(wezterm cli split-pane --bottom --percent 30)
wezterm cli send-text --pane-id "$terminal_pane_id" --no-paste "cd $DIR"$'\n'
