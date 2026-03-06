-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

local act = wezterm.action

-- tab bar plugin
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
bar.apply_to_config(config, {
	padding = {
		left = 0,
		right = 0,
		tabs = { left = 1, right = 1 },
	},
	separator = { space = 1 },
})

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
config.initial_rows = 28
config.font = wezterm.font("Jetbrains Mono")
config.launch_menu = launch_menu
config.font_size = 19
config.color_scheme = "Monokai Pro Ristretto (Gogh)"
config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.window_background_opacity = 0.99
config.window_padding = { left = 4, right = 4, top = 4, bottom = 0 }
config.colors = {

	tab_bar = {
		background = "#000000",
		inactive_tab_edge = "#575757",
		active_tab = {
			bg_color = "#FF9400",
			fg_color = "#000000",
		},
	},
}

-- disabling the annoying close confirmation
config.window_close_confirmation = "NeverPrompt"

-- Finally, return the configuration to wezterm:
return config
