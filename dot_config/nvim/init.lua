-- ~/.config/nvim/init.lua — minimal starter. Replace with your own config later.

-- ---- Leader --------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ---- Options -------------------------------------------------------------
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.wrap = false
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.scrolloff = 8

-- ---- Basic keymaps -------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- No plugin manager wired up yet — drop in lazy.nvim / your config when ready.
