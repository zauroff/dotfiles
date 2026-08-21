return {
    "neovim/nvim-lspconfig",
    opts = {
        inlay_hints = { enabled = false },
        servers = {
            vtsls = {
                settings = {
                    complete_function_calls = false,
                    typescript = {
                        suggest = {
                            completeFunctionCalls = false,
                        },
                    },
                },
            },
        },
    },
}
