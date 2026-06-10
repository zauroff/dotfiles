return {
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            current_line_blame = true,
        },
        keys = {
            {
                "<leader>grb",
                function()
                    require("gitsigns").change_base("origin/develop", true)
                end,
                desc = "Gitsigns base: develop",
            },
            {
                "<leader>grr",
                function()
                    require("gitsigns").reset_base(true)
                end,
                desc = "Gitsigns base: reset",
            },
        },
    },
}
