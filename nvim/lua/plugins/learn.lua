-- Local pseudo-plugin: keeps lesson notes live-reloading while the Stop hook writes to them.
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
      callback = function(args)
        vim.bo[args.buf].autoread = true
        vim.wo.wrap = true
        vim.wo.linebreak = true
      end,
    })

    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "FocusGained", "BufEnter" }, {
      group = group,
      pattern = pattern,
      command = "checktime",
    })

    vim.api.nvim_create_autocmd("FileChangedShellPost", {
      group = group,
      pattern = pattern,
      command = "normal! G",
    })
  end,
}
