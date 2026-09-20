return {
    {
        "zauroff/constellation.nvim",
        dir = vim.fn.expand("~/repos/personal/constellation.nvim"),
        dev = true,
        cmd = { "Constellation", "Graph" },
        keys = {
            { "<leader>cu", "<cmd>Constellation<cr>", desc = "Usage Graph (local)" },
        },
        opts = {},
    },
}
