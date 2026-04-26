return {
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
    keys = {
      { "<leader>cgt", "<cmd>GoTagAdd json<cr>", desc = "Add json tags" },
      { "<leader>cgT", "<cmd>GoTagRm json<cr>", desc = "Remove json tags" },
      { "<leader>cge", "<cmd>GoIfErr<cr>", desc = "Generate if err" },
      { "<leader>cgi", "<cmd>GoImpl<cr>", desc = "Generate impl stubs" },
      { "<leader>cgc", "<cmd>GoCmt<cr>", desc = "Generate comment" },
      { "<leader>cga", "<cmd>GoTestAdd<cr>", desc = "Generate test for func" },
      { "<leader>cgA", "<cmd>GoTestsAll<cr>", desc = "Generate all tests" },
    },
  },
}
