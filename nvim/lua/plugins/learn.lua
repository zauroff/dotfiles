-- Local pseudo-plugin: lesson-note-specific tweaks; global autoreload lives in config/autocmds.lua.
return {
  dir = vim.fn.stdpath("config"),
  name = "learn",
  lazy = false,
  config = function()
    local group = vim.api.nvim_create_augroup("learn", { clear = true })
    local pattern = "*/learning/*.md"

    vim.api.nvim_create_autocmd("BufEnter", {
      group = group,
      pattern = pattern,
      callback = function()
        vim.wo.wrap = true
        vim.wo.linebreak = true
      end,
    })

    vim.api.nvim_create_autocmd("FileChangedShellPost", {
      group = group,
      pattern = pattern,
      command = "normal! G",
    })
  end,
}
