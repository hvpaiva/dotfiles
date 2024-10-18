return {
  -- 🧶 Automatically save your changes in NeoVim
  {
    "okuuva/auto-save.nvim",
    enabled = false, --  TODO: I'm experiencing some performance issues.
    keys = {
      { "<leader>n", ":ASToggle<CR>", desc = "Toggle auto-save" },
    },
    opts = {},
  },

  -- Generic log syntax highlighting and filetype management for Neovim
  { "fei6409/log-highlight.nvim", event = "BufRead *.log", opts = {} },

  -- Establish good command workflow and quit bad habit
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    opts = {
      disable_mouse = false,
      disabled_keys = {
        ["<Up>"] = {},
        ["<Down>"] = {},
        ["<Left>"] = {},
        ["<Right>"] = {},
      },
      restricted_keys = {
        ["<Up>"] = { "n", "x" },
        ["<Down>"] = { "n", "x" },
        ["<Left>"] = { "n", "x" },
        ["<Right>"] = { "n", "x" },
      },
    },
  },

  -- NeoVim plugin with which you can track the time you spent on files, projects, repos, filetypes
  {
    "Dronakurl/usage-tracker.nvim",
    config = function()
      require("usage-tracker").setup({})
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

  -- 🍁 Fun little plugin that can be used as a screensaver and on your dashboard
  {
    "folke/drop.nvim",
    opts = {},
  },

  -- TODO: Validate conflicts with other tools.
  --
  -- Multiple cursors plugin for vim/neovim
  --  {
  --    "mg979/vim-visual-multi",
  --    branch = "master",
  --    lazy = false,
  --    config = function() end,
  --  },
}
