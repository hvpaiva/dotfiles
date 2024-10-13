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
    -- triggers_blacklist = {
    --   n = { "d", "y" },
    -- },
  },
  {
    "OXY2DEV/markview.nvim",
    enabled = true,
    opts = {
      checkboxes = { enable = false },
      links = {
        inline_links = {
          hl = "@markup.link.label.markown_inline",
          icon = " ",
          icon_hl = "@markup.link",
        },
        images = {
          hl = "@markup.link.label.markown_inline",
          icon = " ",
          icon_hl = "@markup.link",
        },
      },
      code_blocks = {
        style = "language",
        hl = "CodeBlock",
        pad_amount = 0,
      },
      list_items = {
        shift_width = 2,
        marker_minus = { text = "●", hl = "@markup.list.markdown" },
        marker_plus = { text = "●", hl = "@markup.list.markdown" },
        marker_star = { text = "●", hl = "@markup.list.markdown" },
        marker_dot = {},
      },
      inline_codes = { enable = false },
      headings = {
        heading_1 = { style = "simple", hl = "Headline1" },
        heading_2 = { style = "simple", hl = "Headline2" },
        heading_3 = { style = "simple", hl = "Headline3" },
        heading_4 = { style = "simple", hl = "Headline4" },
        heading_5 = { style = "simple", hl = "Headline5" },
        heading_6 = { style = "simple", hl = "Headline6" },
      },
    },

    ft = { "markdown", "norg", "rmd", "org" },
    specs = {
      "lukas-reineke/headlines.nvim",
      enabled = false,
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
