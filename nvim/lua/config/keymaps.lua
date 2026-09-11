-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

if vim.g.vscode then
    local vscode = require("vscode")
    vim.keymap.set("n", "<leader>e", function()
        vscode.action("workbench.action.toggleSidebarVisibility")
    end)
    vim.keymap.set("n", "<leader>E", function()
        vscode.action("workbench.files.action.showActiveFileInExplorer")
    end)
end

if vim.g.neovide then
    local function zoom(factor)
        vim.g.neovide_scale_factor = math.max(0.5, math.min(3, (vim.g.neovide_scale_factor or 1) * factor))
    end

    local modes = { "n", "i", "v", "t" }

    vim.keymap.set(modes, "<D-=>", function()
        zoom(1.1)
    end) -- Cmd +
    vim.keymap.set(modes, "<D-->", function()
        zoom(1 / 1.1)
    end) -- Cmd -
    vim.keymap.set(modes, "<D-0>", function()
        vim.g.neovide_scale_factor = 1
    end) -- Cmd 0
end
