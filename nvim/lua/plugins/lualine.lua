local function active_lsp()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if next(clients) == nil then
        return "no lsp"
    end

    local names = vim.tbl_map(function(client)
        return client.name
    end, clients)

    if #names == 1 then
        return names[1]
    end

    return string.format("%s (+%d)", names[1], #names - 1)
end

local function gitsigns_diff()
    local status = vim.b.gitsigns_status_dict
    if status == nil then
        return nil
    end

    return {
        added = status.added,
        modified = status.changed,
        removed = status.removed,
    }
end

return {
    {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
            local icons = require("lazyvim.config").icons

            opts.options = vim.tbl_extend("force", opts.options or {}, {
                theme = "auto",
                globalstatus = true,
                component_separators = { left = "|", right = "|" },
                section_separators = "",
                always_divide_middle = true,
                refresh = { statusline = 1000 },
            })

            opts.sections = {
                lualine_a = {
                    {
                        "filename",
                        path = 1,
                        symbols = { modified = " ", readonly = " ", unnamed = "[No Name]" },
                    },
                },
                lualine_b = {
                    {
                        "branch",
                        fmt = function(name)
                            return name:sub(1, 20)
                        end,
                        color = { gui = "italic,bold" },
                    },
                    {
                        "diff",
                        source = gitsigns_diff,
                        symbols = {
                            added = icons.git.added,
                            modified = icons.git.modified,
                            removed = icons.git.removed,
                        },
                    },
                },
                lualine_c = {
                    { "%S", color = { gui = "bold" } },
                    function()
                        return vim.o.spell and "[SPELL]" or ""
                    end,
                },
                lualine_x = {
                    {
                        function()
                            return require("noice").api.status.command.get()
                        end,
                        cond = function()
                            return package.loaded["noice"]
                                and require("noice").api.status.command.has()
                        end,
                    },
                    { active_lsp, icon = vim.fn.nr2char(0xf085) },
                    {
                        "diagnostics",
                        sources = { "nvim_diagnostic" },
                        symbols = {
                            error = icons.diagnostics.Error,
                            warn = icons.diagnostics.Warn,
                            info = icons.diagnostics.Info,
                            hint = icons.diagnostics.Hint,
                        },
                    },
                },
                lualine_y = {
                    { "encoding", fmt = string.upper },
                    { "fileformat" },
                    { "filetype", icon_only = true, separator = "" },
                },
                lualine_z = { "progress", "location" },
            }

            opts.inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            }

            opts.extensions = { "lazy", "quickfix", "trouble", "neo-tree" }

            return opts
        end,
    },
}
