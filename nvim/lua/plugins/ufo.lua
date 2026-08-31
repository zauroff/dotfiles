local function fold_virt_text(virt_text, lnum, end_lnum, width, truncate)
    local result = {}
    local suffix = ("  󰁂 %d "):format(end_lnum - lnum)
    local suffix_width = vim.fn.strdisplaywidth(suffix)
    local target_width = width - suffix_width
    local cur_width = 0

    for _, chunk in ipairs(virt_text) do
        local text = chunk[1]
        local chunk_width = vim.fn.strdisplaywidth(text)

        if target_width > cur_width + chunk_width then
            table.insert(result, chunk)
        else
            text = truncate(text, target_width - cur_width)
            table.insert(result, { text, chunk[2] })
            chunk_width = vim.fn.strdisplaywidth(text)
            if cur_width + chunk_width < target_width then
                suffix = suffix .. (" "):rep(target_width - cur_width - chunk_width)
            end
            break
        end

        cur_width = cur_width + chunk_width
    end

    table.insert(result, { suffix, "MoreMsg" })
    return result
end

return {
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
        event = "BufReadPost",
        init = function()
            vim.o.foldcolumn = "1"
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
        end,
        opts = {
            open_fold_hl_timeout = 150,
            fold_virt_text_handler = fold_virt_text,
            provider_selector = function()
                return { "lsp", "indent" }
            end,
            preview = {
                win_config = {
                    border = "rounded",
                    winblend = 0,
                },
            },
        },
        keys = {
            {
                "zR",
                function()
                    require("ufo").openAllFolds()
                end,
                desc = "Open all folds",
            },
            {
                "zM",
                function()
                    require("ufo").closeAllFolds()
                end,
                desc = "Close all folds",
            },
            {
                "zr",
                function()
                    require("ufo").openFoldsExceptKinds()
                end,
                desc = "Open folds except kinds",
            },
            {
                "zK",
                function()
                    if not require("ufo").peekFoldedLinesUnderCursor() then
                        vim.lsp.buf.hover()
                    end
                end,
                desc = "Peek fold",
            },
        },
    },
    {
        "luukvbaal/statuscol.nvim",
        lazy = false,
        priority = 900,
        config = function()
            local builtin = require("statuscol.builtin")
            local ffi = require("statuscol.ffidef")

            local max_fold_depth = 3
            local function foldfunc(args)
                if ffi.C.fold_info(args.wp, args.lnum).level > max_fold_depth then
                    return " "
                end
                return builtin.foldfunc(args)
            end

            require("statuscol").setup({
                relculright = false,
                segments = {
                    { text = { builtin.lnumfunc }, click = "v:lua.ScLa" },
                    { text = { "%s" }, click = "v:lua.ScSa" },
                    {
                        text = { foldfunc, " " },
                        condition = { true, builtin.not_empty },
                        click = "v:lua.ScFa",
                    },
                },
            })
        end,
    },
}
