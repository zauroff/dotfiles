-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28
config.font = wezterm.font 'Jetbrains Mono'
config.launch_menu = launch_menu
-- or, changing the font size and color scheme.
config.font_size = 19
config.color_scheme = 'Gruvbox Dark (Gogh)'
config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.window_background_opacity = 0.9
config.macos_window_background_blur = 10
-- Finally, return the configuration to wezterm:
return config
