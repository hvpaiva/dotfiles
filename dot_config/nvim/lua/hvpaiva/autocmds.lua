-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('hvpaiva-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Set the '~' End of file a dimmer color
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('MyEoBColor', { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, 'EndOfBuffer', { fg = '#5F7188', bg = 'none' })
  end,
})
