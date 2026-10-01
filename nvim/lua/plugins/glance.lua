return {
    {
        "dnlhc/glance.nvim",
        cmd = "Glance",
        opts = {
            height = 25,
            border = {
                enable = true,
            },
            list = {
                position = "right",
                width = 0.33,
            },
            theme = {
                enable = true,
                mode = "auto",
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                ["*"] = {
                    keys = {
                        {
                            "gd",
                            "<cmd>Glance definitions<cr>",
                            desc = "Goto Definition",
                            has = "definition",
                        },
                        {
                            "gr",
                            "<cmd>Glance references<cr>",
                            desc = "References",
                            nowait = true,
                        },
                        {
                            "gI",
                            "<cmd>Glance implementations<cr>",
                            desc = "Goto Implementation",
                        },
                        {
                            "gy",
                            "<cmd>Glance type_definitions<cr>",
                            desc = "Goto T[y]pe Definition",
                        },
                        {
                            "gc",
                            "<cmd>Trouble lsp_incoming_calls toggle focus=true<cr>",
                            desc = "Incoming Calls",
                            has = "prepareCallHierarchy",
                            nowait = true,
                        },
                        {
                            "gC",
                            "<cmd>Trouble lsp_outgoing_calls toggle focus=true<cr>",
                            desc = "Outgoing Calls",
                            has = "prepareCallHierarchy",
                            nowait = true,
                        },
                    },
                },
            },
        },
    },
}
