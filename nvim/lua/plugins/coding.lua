return {
  {
    "folke/ts-comments.nvim",
    opts = {},
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
    opts = {},
  },
  -- {
  --   "numToStr/Comment.nvim",
  --   opts = {},
  -- },
  {
    "mg979/vim-visual-multi",
    branch = "master",
    init = function()
      vim.g.VM_maps = {
        ["Find Under"] = "<C-d>",
      }
    end,
  },
}
