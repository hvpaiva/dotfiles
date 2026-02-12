return {
  'mbbill/undotree',

  config = function()
    vim.keymap.set('n', '<leader>U', function()
      vim.cmd 'UndotreeToggle | UndotreeFocus'
    end, { desc = 'Toggle undotree' })
  end,
}
