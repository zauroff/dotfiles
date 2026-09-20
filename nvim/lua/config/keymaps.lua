-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Terminal: real show/hide toggle. LazyVim binds <C-/> to Snacks.terminal.focus,
-- which only bounces the cursor between windows and leaves the terminal open.
-- <C-_> is what most terminals actually send for ctrl+/ (0x1f).
for _, key in ipairs({ "<D-/>", "<C-/>", "<C-_>" }) do
    vim.keymap.set({ "n", "t" }, key, function()
        Snacks.terminal.toggle(nil, { cwd = LazyVim.root() })
    end, { desc = "Terminal (Root Dir)" })
end

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
