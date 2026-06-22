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
config.initial_rows = 120

config.font = wezterm.font("JetBrains Mono", { weight = "Medium" })
config.launch_menu = launch_menu
config.font_size = 20

-- Sharp & crispy text rendering
config.freetype_load_target = "Light"
config.freetype_render_target = "HorizontalLcd"
config.freetype_load_flags = "NO_AUTOHINT"
config.colors = {
	foreground = "#f5f4ef",
	background = "#2f2f2d",
	cursor_bg = "#d97757",
	cursor_fg = "#2f2f2d",
	cursor_border = "#d97757",
	selection_bg = "#524e48",
	selection_fg = "#f5f4ef",
	split = "#4a4a47",

	ansi = {
		"#242422", -- black
		"#d97757", -- red (clay)
		"#65bb30", -- green
		"#c1a855", -- yellow (gold)
		"#74abe2", -- blue
		"#9b86f4", -- magenta (purple)
		"#7ab89a", -- cyan (mint)
		"#eadbbb", -- white (manilla)
	},
	brights = {
		"#4a4a47", -- bright black
		"#e89070", -- bright red
		"#7dd04a", -- bright green
		"#d4be6e", -- bright yellow
		"#92c0ec", -- bright blue
		"#b5a2f7", -- bright magenta
		"#96cdb2", -- bright cyan
		"#f5f4ef", -- bright white
	},

	tab_bar = {
		background = "#242422",
		active_tab = {
			bg_color = "#2f2f2d",
			fg_color = "#f5f4ef",
		},
		inactive_tab = {
			bg_color = "#242422",
			fg_color = "#7a7a75",
		},
		inactive_tab_hover = {
			bg_color = "#3a3a37",
			fg_color = "#eadbbb",
		},
		new_tab = {
			bg_color = "#242422",
			fg_color = "#7a7a75",
		},
		new_tab_hover = {
			bg_color = "#3a3a37",
			fg_color = "#eadbbb",
		},
	},
}
config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.use_resize_increments = true
config.macos_window_background_blur = 10
config.window_background_opacity = 0.95
-- disabling the annoying close confirmation
config.window_close_confirmation = "NeverPrompt"

-- Finally, return the configuration to wezterm:
return config
