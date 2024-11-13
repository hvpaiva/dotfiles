return {
	-- Generic log syntax highlighting and filetype management for Neovim
	{
		"fei6409/log-highlight.nvim",
		lazy = true,
		event = "BufRead *.log",
		opts = {},
	},
	-- Establish good command workflow and quit bad habit
	{
		"m4xshen/hardtime.nvim",
		opts = {
			disable_mouse = false,
		},
		keys = {
			{ "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"' },
			{ "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"' },
		},
	},
	-- NeoVim plugin with which you can track the time you spent on files, projects, repos, filetypes
	{
		"Dronakurl/usage-tracker.nvim",
		config = function()
			require("usage-tracker").setup({
				json_file = vim.fn.stdpath("data") .. "/usage-tracker.json",
				keep_eventlog_days = 365,
				cleanup_freq_days = 356,
			})
		end,
	},
	-- Prismatic line decorations for the adventurous vim user
	{
		"mvllow/modes.nvim",
		tag = "v0.2.0",
		config = function()
			require("modes").setup({
				colors = {
					bg = "#82aaff",
					copy = "#86e1fc",
					delete = "#ff757f",
					insert = "#c3e88d",
					visual = "#c099ff",
				},
				line_opacity = 0.25,
				set_cursor = true,
				set_cursorline = true,
				set_number = true,
				ignore_filetypes = { "NvimTree", "TelescopePrompt" },
			})
		end,
	},
}
