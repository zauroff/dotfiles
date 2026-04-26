return {
    {
        "nvim-telescope/telescope-ui-select.nvim",
    },
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup({
                defaults = {
                    hidden = true,
                    no_ignore = true,
                    file_ignore_patterns = {
                        "node_modules",
                        ".ruff_cache",
                        ".git/",
                        ".mypy_cache",
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                        no_ignore = true,
                        file_ignore_patterns = {
                            "node_modules",
                            ".ruff_cache",
                            ".git/",
                            ".mypy_cache",
                        },
                    },
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
            })
            require("telescope").load_extension("ui-select")
        end,
    },
}
