-- change word with <c-c>
vim.keymap.set({ "n", "x" }, "<C-c>", "<cmd>normal! ciw<cr>a")
