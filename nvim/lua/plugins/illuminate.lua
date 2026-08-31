return {
    {
        "RRethy/vim-illuminate",
        event = "LazyFile",
        opts = {
            delay = 120,
            min_count_to_highlight = 2,
            large_file_cutoff = 2000,
            large_file_overrides = { providers = { "lsp" } },
            filetypes_denylist = {
                "DressingSelect",
                "Outline",
                "TelescopePrompt",
                "alpha",
                "dirbuf",
                "dirvish",
                "fugitive",
                "help",
                "lazy",
                "mason",
                "neo-tree",
                "snacks_picker_list",
                "trouble",
            },
        },
        config = function(_, opts)
            require("illuminate").configure(opts)
        end,
        keys = {
            {
                "]]",
                function()
                    require("illuminate").goto_next_reference(false)
                end,
                desc = "Next Reference",
            },
            {
                "[[",
                function()
                    require("illuminate").goto_prev_reference(false)
                end,
                desc = "Prev Reference",
            },
        },
    },
    {
        "folke/snacks.nvim",
        opts = {
            words = { enabled = false },
        },
    },
}
