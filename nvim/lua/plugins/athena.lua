return {
    {
        "zauroff/athena.nvim",
        dir = vim.fn.expand("~/repos/personal/athena.nvim"),
        dev = true,
        dependencies = { "folke/snacks.nvim" },
        cmd = {
            "Athena",
            "AthenaFiles",
            "AthenaClose",
            "AthenaComment",
            "AthenaThread",
            "AthenaReview",
            "AthenaQuickfix",
        },
        keys = {
            { "<leader>p", "", desc = "+pull request" },
            { "<leader>pp", "<cmd>Athena<cr>", desc = "Open a pull request" },
            { "<leader>pf", "<cmd>AthenaFiles<cr>", desc = "PR changed files" },
            { "<leader>pc", "<cmd>AthenaComment<cr>", mode = { "n", "x" }, desc = "PR comment on selection" },
            {
                "<leader>pC",
                function()
                    require("athena.comment").start_review()
                end,
                mode = { "n", "x" },
                desc = "PR start review with this comment",
            },
            { "<leader>pt", "<cmd>AthenaThread<cr>", desc = "PR toggle thread on this line" },
            { "<leader>px", "<cmd>AthenaQuickfix<cr>", desc = "PR hunks to quickfix" },
            { "<leader>pR", "<cmd>AthenaReview start<cr>", desc = "PR start review" },
            { "<leader>pS", "<cmd>AthenaReview submit<cr>", desc = "PR submit review" },
            { "<leader>pD", "<cmd>AthenaReview discard<cr>", desc = "PR discard pending review" },
            { "<leader>pq", "<cmd>AthenaClose<cr>", desc = "PR close review" },
        },
        opts = {},
    },
}
