return {
  -- Generic log syntax highlighting and filetype management for Neovim
  {
    "fei6409/log-highlight.nvim",
    lazy = true,
    event = "BufRead *.log",
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
