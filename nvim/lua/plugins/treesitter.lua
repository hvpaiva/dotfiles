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
  --   {
  --     "https://github.com/Samonitari/tree-sitter-caddy",
  --     dependencies = {
  --       "nvim-treesitter/nvim-treesitter",
  --       opts = function(_, opts)
  --         require("nvim-treesitter.parsers").get_parser_configs().caddy = {
  --           install_info = {
  --             url = "https://github.com/Samonitari/tree-sitter-caddy",
  --             files = { "src/parser.c", "src/scanner.c" },
  --             branch = "master",
  --           },
  --           filetype = "caddy",
  --         }
  --
  --         opts.ensure_installed = opts.ensure_installed or {}
  --         vim.list_extend(opts.ensure_installed, { "caddy" })
  --         vim.filetype.add({
  --           pattern = {
  --             ["Caddyfile"] = "caddy",
  --           },
  --         })
  --       end,
  --     },
  --     event = "BufRead Caddyfile",
  --   },
}
