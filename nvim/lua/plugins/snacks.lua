return {
    "folke/snacks.nvim",
    dependencies = { "MaximilianLloyd/ascii.nvim" },
    opts = function(_, opts)
        return vim.tbl_deep_extend("force", opts or {}, {
            dashboard = {
                preset = {
                    header = table.concat(require("ascii").art.text.neovim.sharp, "\n"),
                },
            },
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
        })
    end,
}
