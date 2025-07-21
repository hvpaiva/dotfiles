local wezterm = require("wezterm")
local config = {}

config.color_scheme = "tokyonight_night"
config.cursor_blink_rate = 0
config.enable_tab_bar = false
config.font = wezterm.font("Pragmasevka Nerd Font")
config.font_size = 15
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 0.9
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true
config.use_dead_keys = false
config.keys = {
	{ key = "\r", mods = "CTRL", action = wezterm.action({ SendString = "\x1b[13;5u" }) },
	{ key = "\r", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b[13;2u" }) },
	{ key = "LeftArrow", mods = "ALT", action = wezterm.action({ SendString = "\x1b\x62" }) },
	{ key = "RightArrow", mods = "ALT", action = wezterm.action({ SendString = "\x1b\x66" }) },
	{ key = "h", mods = "ALT", action = wezterm.action.SendString("\x1bh") },
	{ key = "j", mods = "ALT", action = wezterm.action.SendString("\x1bj") },
	{ key = "k", mods = "ALT", action = wezterm.action.SendString("\x1bk") },
	{ key = "l", mods = "ALT", action = wezterm.action.SendString("\x1bl") },
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
