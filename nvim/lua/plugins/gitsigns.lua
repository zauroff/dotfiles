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
                    -- Diff against the merge-base, not the tip of develop, so hunks
                    -- reflect only this branch's changes (like a PR diff) even when
                    -- develop has advanced since the fork point.
                    local base = vim.fn.systemlist({ "git", "merge-base", "origin/develop", "HEAD" })[1]
                    require("gitsigns").change_base(base or "origin/develop", true)
                end,
                desc = "Gitsigns base: develop (merge-base)",
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
