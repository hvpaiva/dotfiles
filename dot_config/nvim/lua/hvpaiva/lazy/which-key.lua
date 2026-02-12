-- NOTE: Plugins can also be configured to run Lua code when they are loaded.
--
-- This is often very useful to both group configuration, as well as handle
-- lazy loading plugins that don't need to be loaded immediately at startup.
--
-- For example, in the following configuration, we use:
--  event = 'VimEnter'
--
-- which loads which-key before all the UI elements are loaded. Events can be
-- normal autocommands events (`:help autocmd-events`).
--
-- Then, because we use the `opts` key (recommended), the configuration runs
-- after the plugin has been loaded as `require(MODULE).setup(opts)`.

return {
  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      -- this setting is independent of vim.o.timeoutlen
      preset = 'helix',
      delay = 0,
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = false,
      },
      win = {
        wo = { winblend = 0 },
      },

      -- Document existing key chains
      spec = {
        { '<leader>s', group = 'Search' },
        { '<leader>t', group = 'Toggle' },
        { '<leader>h', group = 'Git Hunk', mode = { 'n', 'v' } },
      },
    },

    config = function(_, opts)
      require('which-key').setup(opts)

      -- local function apply_whichkey_hl()
      --   vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'NONE' })
      --   vim.api.nvim_set_hl(0, 'WhichKeyNormal', { bg = 'NONE' })
      --   -- Bordas/coerência (opcional):
      --   -- vim.api.nvim_set_hl(0, 'WhichKeyBorder', { fg = '#4C566A', bg = 'NONE' })
      --   -- Título/separadores (opcional):
      --   -- vim.api.nvim_set_hl(0, 'WhichKeyTitle', { fg = '#E5E9F0', bg = 'NONE', bold = true })
      --   -- vim.api.nvim_set_hl(0, 'WhichKeySeparator', { fg = '#81A1C1', bg = 'NONE' })
      -- end
      --
      -- apply_whichkey_hl()
      --
      -- vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter' }, {
      --   callback = apply_whichkey_hl,
      --   desc = 'Reapply WhichKey float highlights',
      -- })
    end,
  },
}
