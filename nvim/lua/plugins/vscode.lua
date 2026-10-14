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
    -- Runs unchanged; config.vscode_whichkey redraws its invisible float as editor decorations. helix (LazyVim's
    -- preset) is one column up to 75 rows tall against vscode-neovim's 100-line grid, so pack columns instead, capped
    -- at 100 because vscode-neovim reports 1000 columns. A mouse selection puts nvim in charwise visual mode, which
    -- which-key's default `defer` doesn't cover, so defer every visual mode until a key is pressed.
    {
        "folke/which-key.nvim",
        vscode = true,
        opts = {
            preset = "classic",
            win = { width = 100 },
            icons = { mappings = false },
            defer = function(ctx)
                return vim.tbl_contains({ "v", "V", "<C-V>" }, ctx.mode)
            end,
        },
        config = function(_, opts)
            require("which-key").setup(opts)
            require("config.vscode_whichkey").setup()
        end,
    },
}
