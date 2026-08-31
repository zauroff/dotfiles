-- Plugins that survive inside vscode-neovim.
--
-- lazyvim.plugins.extras.vscode disables everything outside a 17-plugin
-- allowlist. These four manipulate buffers and never draw their own windows,
-- so they work unchanged; their pickers and prompts go through vim.ui.select /
-- vim.ui.input, which vscode-neovim swaps for native QuickPicks.
--
-- flash.nvim already carries `vscode = true` upstream, so it needs no entry.
if not vim.g.vscode then
    return {}
end

return {
    { "ThePrimeagen/refactoring.nvim", vscode = true },
    { "olexsmir/gopher.nvim", vscode = true },
    { "obsidian-nvim/obsidian.nvim", vscode = true },
    { "nvim-treesitter/nvim-treesitter-textobjects", vscode = true },
}
