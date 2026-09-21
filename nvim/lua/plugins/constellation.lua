return {
    {
        "zauroff/constellation.nvim",
        dev = true,
        cmd = { "Constellation", "Graph" },
        keys = {
            { "<leader>cu", "<cmd>Constellation<cr>", desc = "Usage Graph (local)" },
        },
        opts = {},
    },
}
