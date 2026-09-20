return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen -w<cr>", desc = "Diffview Open" },
      {
        "<leader>gf",
        function()
          local base = vim.fn.systemlist("git symbolic-ref refs/remotes/origin/HEAD --short")[1]
          base = base and base:gsub("^origin/", "") or "main"
          vim.cmd("DiffviewOpen -w origin/" .. base .. "...HEAD -- " .. vim.fn.expand("%"))
        end,
        desc = "Diffview File vs Origin",
      },
      { "<leader>gh", "<cmd>DiffviewFileHistory -w<cr>", desc = "Diffview Branch History" },
    },
  },
}
