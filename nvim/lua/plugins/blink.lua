return {
    {
        "saghen/blink.cmp",
        dependencies = { "xzbdmw/colorful-menu.nvim" },
        opts = {
            completion = {
                list = {
                    selection = {
                        auto_insert = false,
                    },
                },
                documentation = {
                    auto_show = false,
                },
                accept = {
                    auto_brackets = { enabled = false },
                },
                menu = {
                    draw = {
                        treesitter = { "lsp" },
                        columns = { { "kind_icon" }, { "label", gap = 1 } },
                        components = {
                            label = {
                                text = function(ctx)
                                    return require("colorful-menu").blink_components_text(ctx)
                                end,
                                highlight = function(ctx)
                                    return require("colorful-menu").blink_components_highlight(ctx)
                                end,
                            },
                        },
                    },
                },
            },
            signature = { enabled = false },
        },
    },
    {
        "xzbdmw/colorful-menu.nvim",
        lazy = true,
        opts = {
            max_width = 60,
            fallback_highlight = "@variable",
            ls = {
                lua_ls = { arguments_hl = "@comment" },
                gopls = {
                    align_type_to_right = true,
                    add_colon_before_type = false,
                    preserve_type_when_truncate = true,
                },
                clangd = {
                    extra_info_hl = "@comment",
                    align_type_to_right = true,
                    import_dot_hl = "@comment",
                    preserve_type_when_truncate = true,
                },
                basedpyright = { extra_info_hl = "@comment" },
                ts_ls = { extra_info_hl = "@comment" },
                vtsls = { extra_info_hl = "@comment" },
                fallback = true,
                fallback_extra_info_hl = "@comment",
            },
        },
    },
}
