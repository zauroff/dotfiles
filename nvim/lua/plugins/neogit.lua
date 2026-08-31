return {
    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
            "folke/snacks.nvim",
        },
        cmd = "Neogit",
        opts = {
            graph_style = "unicode",
            kind = "tab",
            integrations = {
                diffview = true,
                snacks = true,
            },
            signs = {
                hunk = { vim.fn.nr2char(0xf460), vim.fn.nr2char(0xf47c) },
                item = { vim.fn.nr2char(0xf460), vim.fn.nr2char(0xf47c) },
                section = { vim.fn.nr2char(0xf460), vim.fn.nr2char(0xf47c) },
            },
        },
        keys = {
            { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit" },
            { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit commit" },
        },
    },
}
