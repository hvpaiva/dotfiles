local pattern = "[^:]+:(%d+):(%d+): (.+)%s%[(%w+)%]"
local groups = { "lnum", "col", "message", "code" }

local severities = {
  ["warning"] = vim.diagnostic.severity.WARN,
  ["error"] = vim.diagnostic.severity.ERROR,
}

local defaults = {
  source = "detekt",
}

local detektConfigFile = vim.fn.getcwd() .. "/detekt.yml"
local detektPlugins = {
  "detekt-formatting.jar",
}
local function detektPluginsArgs()
  local path = vim.fn.expand("$XDG_CONFIG_HOME") .. "/plugins/java"
  local args = ""
  for i, plugin in ipairs(detektPlugins) do
    if i > 1 then
      args = args .. ";"
    end

    args = args .. path .. "/" .. plugin
  end

  return args
end

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
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        kotlin = { "detekt" },
      },
      linters = {
        detekt = {
          cmd = "detekt",
          args = {
            "-i",
            function()
              return vim.api.nvim_buf_get_name(0)
            end,
            "-c",
            detektConfigFile,
            "-p",
            detektPluginsArgs(),
          },
          append_fname = false,
          ignore_exitcode = true,
          stream = "stdout",
          parser = require("lint.parser").from_pattern(pattern, groups, severities, defaults),
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- kotlin = { "detekt" },
      },
      formatters = {
        injected = { options = { ignore_errors = true } },
        detekt = {
          command = "detekt",
          args = {
            "-i",
            "$FILENAME",
            "-c",
            detektConfigFile,
            "-p",
            detektPluginsArgs(),
            "-ac",
          },
          stdin = false,
          exit_codes = {
            0,
            2, -- This is used when linting, meaning there are some linting errors
          },
        },
      },
    },
  },
}
