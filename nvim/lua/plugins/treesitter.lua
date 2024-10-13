return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "cmake",
        "css",
        "devicetree",
        "gitcommit",
        "gitignore",
        "glsl",
        "go",
        "graphql",
        "http",
        "kconfig",
        "kotlin",
        "meson",
        "ninja",
        "nix",
        "org",
        "scss",
        "sql",
        "svelte",
        "wgsl",
      })
    end,
  },
}
