return {
    {
        "kosayoda/nvim-lightbulb",
        event = "LspAttach",
        opts = {
            autocmd = {
                enabled = true,
                updatetime = -1,
            },
            sign = {
                enabled = true,
                text = "󰌵",
                hl = "DiagnosticSignWarn",
            },
            filter = function(_, result)
                local ignored = {
                    "source.fixAll.ruff",
                    "source.organizeImports.ruff",
                }
                return not vim.tbl_contains(ignored, result.kind)
            end,
        },
    },
}
