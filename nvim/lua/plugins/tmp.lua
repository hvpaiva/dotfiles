vim.env.FZF_DEFAULT_OPTS = ""

vim.schedule(function() end)

return {
  {
    "folke/which-key.nvim",
    enabled = true,
    opts = {
      preset = "helix",
      debug = false,
      win = {},
      spec = {},
    },
  },
  { "justinsgithub/wezterm-types", lazy = true },
  {
    "folke/lazydev.nvim",
    opts = function(_, opts)
      opts.debug = true
      vim.list_extend(opts.library, {
        { path = "wezterm-types", mods = { "wezterm" } },
      })
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = { show_help = false },
  },
  { "fei6409/log-highlight.nvim", event = "BufRead *.log", opts = {} },
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    opts = {
      disable_mouse = false,
    },
  },
  {
    "Dronakurl/usage-tracker.nvim",
    config = function()
      require("usage-tracker").setup({})
    end,
  },
}
