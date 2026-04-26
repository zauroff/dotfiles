-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

local act = wezterm.action

config.keys = { -- Split pane vertically (creates a pane to the right)
	{ key = "s", mods = "CTRL|ALT", action = act.SplitPane({ direction = "Right" }) },
	{ key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\x1b\r") },

	-- Split pane horizontally (creates a pane below)
	{ key = "v", mods = "CTRL|ALT", action = act.SplitPane({ direction = "Down" }) },

	-- Close current pane
	{ key = "w", mods = "CTRL|ALT", action = act.CloseCurrentPane({ confirm = false }) },

	-- Navigate between panes
	{ key = "LeftArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Down") },

	-- Navigate between tabs
	{ key = "LeftArrow", mods = "SUPER|ALT", action = act.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "SUPER|ALT", action = act.ActivateTabRelative(1) },
}

config.initial_cols = 120
config.initial_rows = 2

config.font = wezterm.font("Jetbrains Mono")
config.launch_menu = launch_menu
config.font_size = 20
config.color_scheme = "nordfox"
config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.macos_window_background_blur = 10
-- disabling the annoying close confirmation
config.window_close_confirmation = "NeverPrompt"

-- Finally, return the configuration to wezterm:
return config
