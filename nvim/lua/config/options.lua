-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = false
vim.opt.number = true

vim.opt.winborder = "rounded"

vim.opt.fillchars = {
    horiz = "─",
    horizup = "┴",
    horizdown = "┬",
    vert = "│",
    vertleft = "┤",
    vertright = "├",
    verthoriz = "┼",
    eob = " ",
    fold = " ",
    foldopen = vim.fn.nr2char(0xf47c),
    foldclose = vim.fn.nr2char(0xf460),
    foldsep = " ",
    diff = "╱",
    msgsep = "‾",
}

vim.opt.cursorline = true
vim.opt.pumblend = 0
vim.opt.winblend = 0
vim.opt.signcolumn = "yes:1"
vim.opt.numberwidth = 4
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.list = true
vim.opt.listchars = {
    tab = "▸ ",
    extends = "❯",
    precedes = "❮",
    nbsp = "␣",
}
vim.opt.linebreak = true
vim.opt.showbreak = "↪"

vim.opt.colorcolumn = "100"
vim.opt.pumheight = 10
vim.opt.splitkeep = "screen"
vim.opt.updatetime = 500
vim.opt.showcmdloc = "statusline"
vim.opt.showmode = false
vim.opt.synmaxcol = 250

vim.opt.diffopt = {
    "vertical",
    "filler",
    "closeoff",
    "context:3",
    "internal",
    "indent-heuristic",
    "algorithm:histogram",
    "inline:char",
}
