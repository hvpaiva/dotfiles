return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        grug_far = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- modicator (auto color line number based on vim mode)
  {
    "mawkler/modicator.nvim",
    dependencies = "catppuccin/nvim",
    init = function()
      -- These are required for Modicator to work
      vim.o.cursorline = true
      vim.o.number = true
      vim.o.termguicolors = true
    end,
    opts = {
      show_warnings = true,
    },
  },

  --  {
  --    "nvim-lualine/lualine.nvim",
  --    event = "VeryLazy",
  --    opts = function()
  --      local icons = LazyVim.config.icons
  --      local opts = {
  --        options = {
  --          theme = "catppuccin",
  --        },
  --        sections = {
  --          lualine_a = { "mode" },
  --          lualine_b = { "branch" },
  --
  --          lualine_c = {
  --            {
  --              "diagnostics",
  --              symbols = {
  --                error = icons.diagnostics.Error,
  --                warn = icons.diagnostics.Warn,
  --                info = icons.diagnostics.Info,
  --                hint = icons.diagnostics.Hint,
  --              },
  --            },
  --            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
  --            { LazyVim.lualine.pretty_path() },
  --          },
  --          lualine_x = {
  --            {
  --              function()
  --                return require("noice").api.status.command.get()
  --              end,
  --              cond = function()
  --                return package.loaded["noice"] and require("noice").api.status.command.has()
  --              end,
  --              color = function()
  --                return LazyVim.ui.fg("Statement")
  --              end,
  --            },
  --            {
  --              function()
  --                return require("noice").api.status.mode.get()
  --              end,
  --              cond = function()
  --                return package.loaded["noice"] and require("noice").api.status.mode.has()
  --              end,
  --              color = function()
  --                return LazyVim.ui.fg("Constant")
  --              end,
  --            },
  --            {
  --              function()
  --                return "  " .. require("dap").status()
  --              end,
  --              cond = function()
  --                return package.loaded["dap"] and require("dap").status() ~= ""
  --              end,
  --              color = function()
  --                return LazyVim.ui.fg("Debug")
  --              end,
  --            },
  --            {
  --              require("lazy.status").updates,
  --              cond = require("lazy.status").has_updates,
  --              color = function()
  --                return LazyVim.ui.fg("Special")
  --              end,
  --            },
  --            {
  --              "diff",
  --              symbols = {
  --                added = icons.git.added,
  --                modified = icons.git.modified,
  --                removed = icons.git.removed,
  --              },
  --              source = function()
  --                local gitsigns = vim.b.gitsigns_status_dict
  --                if gitsigns then
  --                  return {
  --                    added = gitsigns.added,
  --                    modified = gitsigns.changed,
  --                    removed = gitsigns.removed,
  --                  }
  --                end
  --              end,
  --            },
  --          },
  --          lualine_y = {
  --            { "progress" },
  --          },
  --          lualine_z = {
  --            { "location", padding = { left = 1, right = 1 } },
  --          },
  --        },
  --      }
  --
  --      return opts
  --    end,
  --  },
}
