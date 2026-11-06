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

config.font = wezterm.font("JetBrains Mono", { weight = "Bold" })
config.launch_menu = launch_menu
config.font_size = 14

-- readability fixes?
config.line_height = 1.2
config.cell_width = 1.0
config.front_end = "WebGpu"

-- Sharp & crispy text rendering
config.freetype_load_target = "Light"
config.freetype_load_flags = "NO_AUTOHINT"

-- Read theme mode from state file. dark_colors and light_colors match
-- ghostty/themes/boltz-dark and boltz-light. toggle-theme.sh selects the
-- matching Ghostty theme at the same time it writes this file.
local theme_file = wezterm.home_dir .. "/.config/wezterm/.theme-mode"

local function read_theme_mode()
	local f = io.open(theme_file, "r")
	if f then
		local mode = f:read("*l")
		f:close()
		return mode
	end
	return "dark"
end

wezterm.add_to_config_reload_watch_list(theme_file)

local dark_colors = {
	foreground = "#f0f0ec",
	background = "#0d0d0d",
	cursor_bg = "#ff5a1f",
	cursor_fg = "#0d0d0d",
	cursor_border = "#ff5a1f",
	selection_bg = "#2e2e2b",
	selection_fg = "#f0f0ec",
	split = "#2e2e2b",

	ansi = {
		"#3a3a37", -- black
		"#ff3b30", -- red
		"#1fc77a", -- green
		"#ff5a1f", -- yellow
		"#3d7bff", -- blue
		"#a07ee6", -- magenta
		"#36aebb", -- cyan
		"#c8c8c3", -- white
	},
	brights = {
		"#8a8a85", -- bright black
		"#ff6259", -- bright red
		"#4cd494", -- bright green
		"#ff7a48", -- bright yellow
		"#6696ff", -- bright blue
		"#b59ced", -- bright magenta
		"#5fc1cb", -- bright cyan
		"#f0f0ec", -- bright white
	},

	tab_bar = {
		background = "#131312",
		active_tab = {
			bg_color = "#0d0d0d",
			fg_color = "#f0f0ec",
		},
		inactive_tab = {
			bg_color = "#131312",
			fg_color = "#8a8a85",
		},
		inactive_tab_hover = {
			bg_color = "#2e2e2b",
			fg_color = "#f0f0ec",
		},
		new_tab = {
			bg_color = "#131312",
			fg_color = "#8a8a85",
		},
		new_tab_hover = {
			bg_color = "#2e2e2b",
			fg_color = "#f0f0ec",
		},
	},
}

local light_colors = {
	foreground = "#161616",
	background = "#e9e9e4",
	cursor_bg = "#ff4f00",
	cursor_fg = "#e9e9e4",
	cursor_border = "#ff4f00",
	selection_bg = "#cfcfc8",
	selection_fg = "#161616",
	split = "#cfcfc8",

	ansi = {
		"#161616", -- black
		"#e0201b", -- red
		"#00995c", -- green
		"#ff4f00", -- yellow
		"#0047ff", -- blue
		"#7a3fd1", -- magenta
		"#00879c", -- cyan
		"#4a4a45", -- white
	},
	brights = {
		"#77776f", -- bright black
		"#ec3d38", -- bright red
		"#14ad6e", -- bright green
		"#ff6a24", -- bright yellow
		"#2a63ff", -- bright blue
		"#8f5ade", -- bright magenta
		"#169cb0", -- bright cyan
		"#2a2a28", -- bright white
	},

	tab_bar = {
		background = "#dfdfd9",
		active_tab = {
			bg_color = "#e9e9e4",
			fg_color = "#161616",
		},
		inactive_tab = {
			bg_color = "#dfdfd9",
			fg_color = "#65655e",
		},
		inactive_tab_hover = {
			bg_color = "#cfcfc8",
			fg_color = "#161616",
		},
		new_tab = {
			bg_color = "#dfdfd9",
			fg_color = "#65655e",
		},
		new_tab_hover = {
			bg_color = "#cfcfc8",
			fg_color = "#161616",
		},
	},
}

local theme_mode = read_theme_mode()
config.colors = theme_mode == "light" and light_colors or dark_colors

config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.window_padding = { left = 2, right = 2, top = 0, bottom = 0 }
config.use_resize_increments = false
config.macos_window_background_blur = 10
-- disabling the annoying close confirmation
config.window_close_confirmation = "NeverPrompt"
-- How many lines of scrollback you want to retain per tab
config.scrollback_lines = 90000
-- Finally, return the configuration to wezterm:
return config
