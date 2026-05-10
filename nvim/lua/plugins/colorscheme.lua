return {
    "daaanny90/claude-desktop.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        require("claudetheme").setup({})
        vim.cmd.colorscheme("claude-desktop")
    end,
}
