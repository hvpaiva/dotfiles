-- these plugins are already installed but include some configuration changes.
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      preset = "helix",
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        separator_style = "slant",
      },
    },
  },
  { "nvim-neotest/neotest-plenary" }, -- TODO: Check if this import is necessary
  {
    "nvim-neotest/neotest",
    opts = { adapters = { "neotest-plenary" } },
  },
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        bottom_search = false,
        lsp_doc_border = true,
      },
    },
  },
}
