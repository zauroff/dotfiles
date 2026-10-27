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

-- Both modes use nvim/colors/boltz.lua, which picks its palette from
-- 'background'.
local function apply_theme()
    vim.o.background = read_theme_mode() == "light" and "light" or "dark"
    pcall(vim.cmd.colorscheme, "boltz")
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
    { "folke/tokyonight.nvim", enabled = false },
    { "catppuccin/nvim", name = "catppuccin", enabled = false },
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
