return {
    {
        "wojciech-kulik/xcodebuild.nvim",
        ft = { "swift", "objc" },
        dependencies = { "MunifTanjim/nui.nvim", "folke/snacks.nvim", "mfussenegger/nvim-dap" },
        keys = {
            { "<leader>ii", "<cmd>XcodebuildPicker<cr>", desc = "iOS: all actions" },
            { "<leader>is", "<cmd>XcodebuildSetup<cr>", desc = "iOS: setup project" },
            { "<leader>ib", "<cmd>XcodebuildBuild<cr>", desc = "iOS: build" },
            { "<leader>ir", "<cmd>XcodebuildBuildRun<cr>", desc = "iOS: build & run" },
            { "<leader>it", "<cmd>XcodebuildTest<cr>", desc = "iOS: run tests" },
            { "<leader>it", "<cmd>XcodebuildTestSelected<cr>", mode = "x", desc = "iOS: run selected tests" },
            { "<leader>iT", "<cmd>XcodebuildTestClass<cr>", desc = "iOS: run test class" },
            { "<leader>i.", "<cmd>XcodebuildTestRepeat<cr>", desc = "iOS: repeat last test" },
            { "<leader>il", "<cmd>XcodebuildToggleLogs<cr>", desc = "iOS: toggle logs" },
            { "<leader>ie", "<cmd>XcodebuildTestExplorerToggle<cr>", desc = "iOS: test explorer" },
            { "<leader>ic", "<cmd>XcodebuildToggleCodeCoverage<cr>", desc = "iOS: toggle coverage" },
            { "<leader>ip", "<cmd>XcodebuildPreviewGenerateAndShow<cr>", desc = "iOS: preview" },
            { "<leader>id", "<cmd>XcodebuildSelectDevice<cr>", desc = "iOS: select device" },
            { "<leader>if", "<cmd>XcodebuildProjectManager<cr>", desc = "iOS: project manager" },
            { "<leader>ia", "<cmd>XcodebuildCodeActions<cr>", desc = "iOS: code actions" },
            { "<leader>ix", "<cmd>XcodebuildQuickfixLine<cr>", desc = "iOS: quickfix line" },
            { "<leader>iD", function() require("xcodebuild.integrations.dap").build_and_debug() end, desc = "iOS: build & debug" },
            { "<leader>iR", function() require("xcodebuild.integrations.dap").debug_without_build() end, desc = "iOS: debug (no build)" },
        },
        config = function()
            require("xcodebuild").setup({})
            -- Xcode 16+ ships lldb-dap; no codelldb path needed.
            require("xcodebuild.integrations.dap").setup()
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                -- /usr/bin/sourcekit-lsp is an xcrun shim; not in mason.
                sourcekit = { mason = false },
            },
        },
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = { ensure_installed = { "swift" } },
    },
}
