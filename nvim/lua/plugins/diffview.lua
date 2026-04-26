return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen -w<cr>", desc = "Diffview Open" },
      { "<leader>gf", "<cmd>DiffviewFileHistory -w %<cr>", desc = "Diffview File History" },
      { "<leader>gh", "<cmd>DiffviewFileHistory -w<cr>", desc = "Diffview Branch History" },
    },
  },
}
