return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                protols = {},
            },
        },
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = { ensure_installed = { "proto" } },
    },
}
