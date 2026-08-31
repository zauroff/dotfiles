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

-- Read theme mode from state file. Palettes below are byte-for-byte the same
-- values Ghostty ships in its "Gruvbox Dark"/"Gruvbox Light" themes, which
-- toggle-theme.sh selects at the same time it writes this file.
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
	foreground = "#ebdbb2",
	background = "#1f1f1f",
	cursor_bg = "#ebdbb2",
	cursor_fg = "#282828",
	cursor_border = "#ebdbb2",
	selection_bg = "#665c54",
	selection_fg = "#ebdbb2",
	split = "#504945",

	ansi = {
		"#282828", -- black (bg0)
		"#cc241d", -- red
		"#98971a", -- green
		"#d79921", -- yellow
		"#458588", -- blue
		"#b16286", -- magenta (purple)
		"#689d6a", -- cyan (aqua)
		"#a89984", -- white (fg4)
	},
	brights = {
		"#928374", -- bright black (gray)
		"#fb4934", -- bright red
		"#b8bb26", -- bright green
		"#fabd2f", -- bright yellow
		"#83a598", -- bright blue
		"#d3869b", -- bright magenta
		"#8ec07c", -- bright cyan
		"#ebdbb2", -- bright white (fg1)
	},

	tab_bar = {
		background = "#1d2021",
		active_tab = {
			bg_color = "#282828",
			fg_color = "#ebdbb2",
		},
		inactive_tab = {
			bg_color = "#1d2021",
			fg_color = "#928374",
		},
		inactive_tab_hover = {
			bg_color = "#3c3836",
			fg_color = "#ebdbb2",
		},
		new_tab = {
			bg_color = "#1d2021",
			fg_color = "#928374",
		},
		new_tab_hover = {
			bg_color = "#3c3836",
			fg_color = "#ebdbb2",
		},
	},
}

local light_colors = {
	foreground = "#3c3836",
	background = "#fbf1c7",
	cursor_bg = "#3c3836",
	cursor_fg = "#fbf1c7",
	cursor_border = "#3c3836",
	selection_bg = "#3c3836",
	selection_fg = "#fbf1c7",
	split = "#bdae93",

	ansi = {
		"#fbf1c7", -- black (bg0)
		"#cc241d", -- red
		"#98971a", -- green
		"#d79921", -- yellow
		"#458588", -- blue
		"#b16286", -- magenta (purple)
		"#689d6a", -- cyan (aqua)
		"#7c6f64", -- white (fg4)
	},
	brights = {
		"#928374", -- bright black (gray)
		"#9d0006", -- bright red
		"#79740e", -- bright green
		"#b57614", -- bright yellow
		"#076678", -- bright blue
		"#8f3f71", -- bright magenta
		"#427b58", -- bright cyan
		"#3c3836", -- bright white (fg1)
	},

	tab_bar = {
		background = "#f9f5d7",
		active_tab = {
			bg_color = "#fbf1c7",
			fg_color = "#3c3836",
		},
		inactive_tab = {
			bg_color = "#f9f5d7",
			fg_color = "#928374",
		},
		inactive_tab_hover = {
			bg_color = "#ebdbb2",
			fg_color = "#3c3836",
		},
		new_tab = {
			bg_color = "#f9f5d7",
			fg_color = "#928374",
		},
		new_tab_hover = {
			bg_color = "#ebdbb2",
			fg_color = "#3c3836",
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

-- Finally, return the configuration to wezterm:
return config
