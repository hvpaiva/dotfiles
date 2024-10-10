return {
  {
    "folke/ts-comments.nvim",
  },
  {
    "zbirenbaum/copilot.lua",
    opts = {
      filetypes = { ["*"] = true },
    },
  },
  {
    "Wansmer/treesj",
    keys = {
      { "J", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
    },
    opts = { use_default_keymaps = false, max_join_length = 150 },
  },
  {
    "nvim-neotest/neotest",
    opts = {
      adapters = {},
    },
  },
  {
    "okuuva/auto-save.nvim",
    opts = {
      -- your config goes here
      -- or just leave it empty :)
    },
  },
  {
    "numToStr/Comment.nvim",
    opts = {
      -- add any options here
    },
  },
}
