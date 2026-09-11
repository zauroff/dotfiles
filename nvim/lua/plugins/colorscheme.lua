local theme_file = vim.fn.expand("~/.config/nvim/.theme-mode")

local function read_theme_mode()
    local f = io.open(theme_file, "r")
    if f then
        local mode = f:read("*l")
        f:close()
        return mode
    end
    return "dark"
end

-- Dark mode uses the VS Code "2026 Dark" port in nvim/colors/vscode2026.lua.
-- Light mode stays on gruvbox, which has no matching 2026 counterpart here.
local function apply_theme()
    if read_theme_mode() == "light" then
        vim.o.background = "light"
        pcall(vim.cmd.colorscheme, "gruvbox")
    else
        vim.o.background = "dark"
        pcall(vim.cmd.colorscheme, "vscode2026")
    end
end

local function watch_theme_file()
    local w = vim.uv.new_fs_event()
    if not w then return end

    local function start_watch()
        w:start(theme_file, {}, vim.schedule_wrap(function()
            apply_theme()
            -- fs_event stops after firing on macOS; restart it
            w:stop()
            start_watch()
        end))
    end

    if vim.fn.filereadable(theme_file) == 1 then
        start_watch()
    end
end

return {
    {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("gruvbox").setup({})
        end,
    },
    -- Let LazyVim apply our theme as its final colorscheme step, otherwise
    -- LazyVim re-applies its default (tokyonight) after our plugins load and
    -- clobbers whatever apply_theme() set.
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = function()
                apply_theme()
                watch_theme_file()
            end,
        },
    },
}
