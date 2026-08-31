local loaded = false

local function launchjs()
    if loaded then return end
    loaded = true
    pcall(function()
        require("dap.ext.vscode").load_launchjs(nil, {
            go = { "go" },
            delve = { "go" },
            debugpy = { "python" },
            python = { "python" },
        })
    end)
end

return {
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.test.core" },
    { import = "lazyvim.plugins.extras.lang.go" },
    { import = "lazyvim.plugins.extras.lang.python" },

    {
        "mfussenegger/nvim-dap",
        keys = {
            { "<F5>", function() launchjs() require("dap").continue() end, desc = "Debug: Start/Continue" },
            { "<S-F5>", function() require("dap").terminate() end, desc = "Debug: Stop" },
            { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
            { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
            { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
            { "<S-F11>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
        },
    },

    {
        "rcarriga/nvim-dap-ui",
        opts = {
            expand_lines = false,
            render = { max_type_length = 0, max_value_lines = 3 },
            layouts = {
                {
                    position = "left",
                    size = 58,
                    elements = {
                        { id = "scopes", size = 0.45 },
                        { id = "stacks", size = 0.30 },
                        { id = "watches", size = 0.15 },
                        { id = "breakpoints", size = 0.10 },
                    },
                },
                {
                    position = "bottom",
                    size = 8,
                    elements = { { id = "repl", size = 1.0 } },
                },
            },
        },
    },

    {
        "theHamsta/nvim-dap-virtual-text",
        opts = {
            virt_text_pos = "eol",
            all_frames = false,
            highlight_changed_variables = true,
            display_callback = function(variable)
                local v = variable.value:gsub("%s+", " ")
                if #v > 48 then v = v:sub(1, 47) .. "…" end
                return " " .. variable.name .. " = " .. v
            end,
        },
    },
}
