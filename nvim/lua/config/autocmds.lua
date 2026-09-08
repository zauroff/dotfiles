-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
require("config.cpp").setup()

-- Global autoreload: pick up external changes (e.g. the learn Stop hook) without an explicit :e
vim.o.autoread = true

local function safe_checktime()
  if vim.fn.mode():sub(1, 1) == "c" or vim.fn.getcmdwintype() ~= "" then
    return
  end
  vim.cmd("checktime")
end

local autoreload = vim.api.nvim_create_augroup("autoreload", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose" }, {
  group = autoreload,
  callback = safe_checktime,
})

local uv = vim.uv or vim.loop
local reload_timer = uv.new_timer()
reload_timer:start(1000, 1000, function()
  vim.schedule(safe_checktime)
end)

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = autoreload,
  callback = function()
    vim.notify("reloaded " .. vim.fn.expand("<afile>:t"), vim.log.levels.INFO)
  end,
})
