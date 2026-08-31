return {
    {
        "Bekaboo/dropbar.nvim",
        event = "VeryLazy",
        opts = {
            bar = {
                enable = function(buf, win, _)
                    if
                        not vim.api.nvim_buf_is_valid(buf)
                        or not vim.api.nvim_win_is_valid(win)
                        or vim.fn.win_gettype(win) ~= ""
                        or vim.wo[win].winbar ~= ""
                        or vim.bo[buf].ft == "help"
                    then
                        return false
                    end

                    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
                    if stat and stat.size > 1024 * 1024 then
                        return false
                    end

                    return vim.bo[buf].buftype == ""
                        and vim.api.nvim_buf_get_name(buf) ~= ""
                        and not vim.wo[win].diff
                end,
            },
            icons = {
                ui = {
                    bar = { separator = "  ", extends = "…" },
                },
            },
            menu = {
                win_configs = {
                    border = "rounded",
                },
            },
        },
        keys = {
            {
                "<leader>;",
                function()
                    require("dropbar.api").pick()
                end,
                desc = "Breadcrumb pick",
            },
        },
    },
}
