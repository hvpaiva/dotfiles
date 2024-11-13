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
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    opts = {
      disable_mouse = false,
    },
    command = "Hardtime",
    event = "BufEnter",
    keys = {
      { "n", "j", "<cmd>Hardtime<CR>", desc = "Hardtime" },
      { "n", "k", "<cmd>Hardtime<CR>", desc = "Hardtime" },
      { "n", "gj", "<cmd>Hardtime<CR>", desc = "Hardtime" },
      { "n", "gk", "<cmd>Hardtime<CR>", desc = "Hardtime" },
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
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
}
