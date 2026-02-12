vim.opt.guicursor = 'a:block'
vim.opt.mouse = ''
vim.opt.showmode = false

vim.opt.number = true
vim.opt.relativenumber = true

vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

vim.o.showmode = false
vim.opt.undofile = true
vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undodir'

vim.opt.breakindent = true
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append '@-@'

vim.opt.updatetime = 50
vim.opt.timeoutlen = 300

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrap = false

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
