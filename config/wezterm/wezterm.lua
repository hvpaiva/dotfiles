local wezterm = require("wezterm")

local config = wezterm.config_builder()
wezterm.log_info("reloading")

-- require("tabs").setup(config)
-- require("mouse").setup(config)
require("link").setup(config)
-- require("keys").setup(config)

return {
	color_scheme = "Catppuccin Mocha",
	enable_tab_bar = false,
	enable_wayland = true,
	webgpu_power_preference = "HighPerformance",
	font_size = 16.0,
	font = wezterm.font({ family = "Fira Code" }),
	font_rules = {
		{
			intensity = "Bold",
			italic = true,
			font = wezterm.font({ family = "Maple Mono", weight = "Bold", style = "Italic" }),
		},
		{
			italic = true,
			intensity = "Half",
			font = wezterm.font({ family = "Maple Mono", weight = "DemiBold", style = "Italic" }),
		},
		{
			italic = true,
			intensity = "Normal",
			font = wezterm.font({ family = "Maple Mono", style = "Italic" }),
		},
	},
	-- macos_window_background_blur = 30,
	-- window_background_opacity = 1.0,
	-- window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
	-- window_decorations = "RESIZE",
	keys = {
		{
			key = "R",
			mods = "CTRL",
			action = wezterm.action.ToggleFullScreen,
		},
		{
			key = "'",
			mods = "CTRL",
			action = wezterm.action.ClearScrollback("ScrollbackAndViewport"),
		},
	},
	-- default_cursor_style = "BlinkingBar",
	-- cursor_blink_ease_in = "Constant",
	-- cursor_blink_ease_out = "Constant",
	-- cursor_thickness = 4,
	-- underline_thickness = 3,
	-- underline_position = -6,
	-- bold_brightens_ansi_colors = true,
	-- colors = {
	-- 	indexed = { [241] = "#65bcff" },
	-- },
	-- command_palette_font_size = 13,
	-- command_palette_bg_color = "#394b70",
	-- command_palette_fg_color = "#828bb8",
}
