local wezterm = require("wezterm")
local config = {}

config.color_scheme = "tokyonight_night"
config.cursor_blink_rate = 0
config.enable_tab_bar = false
config.font = wezterm.font("Cascadia Code")
config.font_size = 17
config.hide_tab_bar_if_only_one_tab = true
config.keys = {
	{ key = "\r", mods = "CTRL", action = wezterm.action({ SendString = "\x1b[13;5u" }) },
	{ key = "\r", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b[13;2u" }) },
	{ key = "LeftArrow", mods = "ALT", action = wezterm.action({ SendString = "\x1b\x62" }) },
	{ key = "RightArrow", mods = "ALT", action = wezterm.action({ SendString = "\x1b\x66" }) },
}
config.line_height = 1.4
config.mouse_bindings = {
	-- Open a link
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = "OpenLinkAtMouseCursor",
	},
}
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 5,
	right = 5,
	top = 0,
	bottom = 0,
}

return config
