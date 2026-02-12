-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- In visual mode, J moves the selected block one line DOWN, keeps selection, and reindents
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move block J down' })
-- In visual mode, K moves the selected block one line UP, keeps selection, and reindents
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move block K up' })

-- Join lines but preserve cursor position by marking it and jumping back afterward
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines keeping cursor' })

-- Half-page down and recenter the cursor line
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Page down and center' })

-- Half-page up and recenter the cursor line
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Page up and center' })

-- Next search result, then recenter and open folds if needed
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'next search result (centered)' })

-- Previous search result, then recenter and open folds if needed
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Prev search result (centered)' })

-- Reindent the paragraph text object around cursor (=ap) and return to the original line using mark 'a
vim.keymap.set('n', '=ap', "ma=ap'a", { desc = 'Reindent around paragraph' })

-- Prepare a global, case-insensitive substitution of the WORD under cursor; leave cursor before flags to edit
vim.keymap.set('n', '<leader>S', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Substitute current word' })

vim.keymap.set('x', '<leader>p', [["_dP]])
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set('n', '<leader>Y', [["+Y]])
vim.keymap.set({ 'n', 'v' }, '<leader>d', '"_d')

-- Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Yank text objects and return caret
vim.keymap.set('n', '<leader>yip', 'mpyip`p')
vim.keymap.set('n', '<leader>yis', 'mpyis`p')
vim.keymap.set('n', '<leader>yiB', 'mpyiB`p')
vim.keymap.set('n', '<leader>yiw', 'mpyiw`p')
vim.keymap.set('n', '<leader>yiW', 'mpyiW`p')
vim.keymap.set('n', '<leader>yi(', 'mpyi(`p')
vim.keymap.set('n', '<leader>yi[', 'mpyi[`p')
vim.keymap.set('n', '<leader>yi{', 'mpyi{`p')
vim.keymap.set('n', '<leader>yi<', 'mpyi<`p')
vim.keymap.set('n', '<leader>yi)', 'mpyi)`p')
vim.keymap.set('n', '<leader>yi]', 'mpyi]`p')
vim.keymap.set('n', '<leader>yi}', 'mpyi}`p')
vim.keymap.set('n', '<leader>yi>', 'mpyi>`p')
vim.keymap.set('n', '<leader>yib', 'mpyib`p')
vim.keymap.set('n', '<leader>yi"', 'mpyi"`p')
vim.keymap.set('n', "<leader>yi'", "mpyi'`p")
vim.keymap.set('n', '<leader>yi`', 'mpyi``p')
vim.keymap.set('n', '<leader>yiq', 'mpyiq`p')
vim.keymap.set('n', '<leader>yi?', 'mpyi?`p')
vim.keymap.set('n', '<leader>yit', 'mpyit`p')
vim.keymap.set('n', '<leader>yif', 'mpyif`p')
vim.keymap.set('n', '<leader>yia', 'mpyia`p')

vim.keymap.set('n', '<leader>yap', 'mpyap`p')
vim.keymap.set('n', '<leader>yas', 'mpyas`p')
vim.keymap.set('n', '<leader>yaB', 'mpyaB`p')
vim.keymap.set('n', '<leader>yaw', 'mpyaw`p')
vim.keymap.set('n', '<leader>yaW', 'mpyaW`p')
vim.keymap.set('n', '<leader>ya(', 'mpya(`p')
vim.keymap.set('n', '<leader>ya[', 'mpya[`p')
vim.keymap.set('n', '<leader>ya{', 'mpya{`p')
vim.keymap.set('n', '<leader>ya<', 'mpya<`p')
vim.keymap.set('n', '<leader>ya)', 'mpya)`p')
vim.keymap.set('n', '<leader>ya]', 'mpya]`p')
vim.keymap.set('n', '<leader>ya}', 'mpya}`p')
vim.keymap.set('n', '<leader>ya>', 'mpya>`p')
vim.keymap.set('n', '<leader>yab', 'mpyab`p')
vim.keymap.set('n', '<leader>ya"', 'mpya"`p')
vim.keymap.set('n', "<leader>ya'", "mpya'`p")
vim.keymap.set('n', '<leader>ya`', 'mpya``p')
vim.keymap.set('n', '<leader>yaq', 'mpyaq`p')
vim.keymap.set('n', '<leader>ya?', 'mpya?`p')
vim.keymap.set('n', '<leader>yat', 'mpyat`p')
vim.keymap.set('n', '<leader>yaf', 'mpyaf`p')
vim.keymap.set('n', '<leader>yaa', 'mpyaa`p')
