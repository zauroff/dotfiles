return {
    "folke/snacks.nvim",
    opts = {
        picker = {
            sources = {
                files = {
                    hidden = true,
                    ignored = true,
                    -- keep gitignored files searchable, but drop dependency noise
                    exclude = {
                        "node_modules",
                        "vendor",
                        ".git",
                    },
                },
            },
        },
    },
}
