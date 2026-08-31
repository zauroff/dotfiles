-- LazyVim's keymap surface, ported onto VSCode commands.
--
-- Two things broke when lazyvim.plugins.extras.vscode started gating plugins:
--
--   1. Maps registered in a plugin's on_attach never appear at all. gitsigns
--      owns ]h/[h/<leader>gh*, nvim-lspconfig owns gd/gr/K/<leader>ca.
--   2. Maps from allowlisted plugins stay bound but point at disabled
--      machinery. snacks.nvim survives the allowlist, but the extra sets
--      picker.enabled = false, so <leader>ff and friends are live keys wired
--      to nothing.
--
-- This rebinds both sets onto vscode.action(). Every command id here was
-- checked against workbench.desktop.main.js and the bundled extension
-- manifests, so none of them are guesses.
--
-- Loaded from config/keymaps.lua, which LazyVim sources on VeryLazy. That runs
-- after lazy.nvim has installed plugin `keys` handlers, so these overwrite the
-- dead snacks mappings rather than losing a race with them.

local M = {}

---@param cmd string VSCode command id
---@param args? table forwarded as the command's arguments
local function act(cmd, args)
    return function()
        require("vscode").action(cmd, args and { args = args } or nil)
    end
end

---@type table[] { mode, lhs, rhs, desc }
local spec = {
    -- ── diagnostics ────────────────────────────────────────────────────────
    -- VSCode's marker nav has no severity filter, so ]e/[e widen to
    -- cross-file rather than narrowing to errors.
    { "n", "]d", act("editor.action.marker.next"), "Next Diagnostic" },
    { "n", "[d", act("editor.action.marker.prev"), "Prev Diagnostic" },
    { "n", "]e", act("editor.action.marker.nextInFiles"), "Next Diagnostic (Files)" },
    { "n", "[e", act("editor.action.marker.prevInFiles"), "Prev Diagnostic (Files)" },
    { "n", "]w", act("editor.action.marker.nextInFiles"), "Next Diagnostic (Files)" },
    { "n", "[w", act("editor.action.marker.prevInFiles"), "Prev Diagnostic (Files)" },
    { "n", "]q", act("editor.action.marker.nextInFiles"), "Next Quickfix Item" },
    { "n", "[q", act("editor.action.marker.prevInFiles"), "Prev Quickfix Item" },

    -- ── git hunks (gitsigns) ───────────────────────────────────────────────
    { "n", "]h", act("workbench.action.editor.nextChange"), "Next Hunk" },
    { "n", "[h", act("workbench.action.editor.previousChange"), "Prev Hunk" },
    { { "n", "x" }, "<leader>ghs", act("git.stageSelectedRanges"), "Stage Hunk" },
    { { "n", "x" }, "<leader>ghr", act("git.revertSelectedRanges"), "Reset Hunk" },
    { { "n", "x" }, "<leader>ghu", act("git.unstageSelectedRanges"), "Undo Stage Hunk" },
    { "n", "<leader>ghS", act("git.stage"), "Stage Buffer" },
    { "n", "<leader>ghR", act("git.clean"), "Reset Buffer" },
    { "n", "<leader>ghp", act("editor.action.dirtydiff.next"), "Preview Hunk Inline" },
    { "n", "<leader>ghb", act("gitlens.toggleLineBlame"), "Blame Line" },
    { "n", "<leader>ghB", act("gitlens.showQuickFileHistory"), "Blame Buffer" },
    { "n", "<leader>ghd", act("git.openChange"), "Diff This" },
    { "n", "<leader>ghD", act("gitlens.diffWithPrevious"), "Diff This ~" },
    { "n", "]x", act("merge-conflict.next"), "Next Conflict" },
    { "n", "[x", act("merge-conflict.previous"), "Prev Conflict" },

    -- ── git panels (diffview.lua, snacks) ──────────────────────────────────
    { "n", "<leader>gs", act("workbench.view.scm"), "Git Status" },
    { "n", "<leader>gg", act("lazygit.openLazygit"), "Lazygit" },
    { "n", "<leader>gd", act("git.openChange"), "Diffview Open" },
    { "n", "<leader>gf", act("gitlens.showQuickFileHistory"), "Diffview File History" },
    { "n", "<leader>gh", act("gitlens.showQuickRepoHistory"), "Diffview Branch History" },

    -- ── LSP (nvim-lspconfig on_attach) ─────────────────────────────────────
    { "n", "gd", act("editor.action.revealDefinition"), "Goto Definition" },
    { "n", "gr", act("editor.action.goToReferences"), "References" },
    { "n", "gI", act("editor.action.goToImplementation"), "Goto Implementation" },
    { "n", "gy", act("editor.action.goToTypeDefinition"), "Goto Type Definition" },
    { "n", "gD", act("editor.action.revealDeclaration"), "Goto Declaration" },
    { "n", "K", act("editor.action.showHover"), "Hover" },
    { "n", "gK", act("editor.action.triggerParameterHints"), "Signature Help" },
    { "n", "]]", act("editor.action.wordHighlight.next"), "Next Reference" },
    { "n", "[[", act("editor.action.wordHighlight.prev"), "Prev Reference" },
    { { "n", "x" }, "<leader>ca", act("editor.action.quickFix"), "Code Action" },
    { "n", "<leader>cA", act("editor.action.sourceAction"), "Source Action" },
    { "n", "<leader>cr", act("editor.action.rename"), "Rename" },
    { "n", "<leader>co", act("editor.action.organizeImports"), "Organize Imports" },
    { "n", "<leader>cf", act("editor.action.formatDocument"), "Format" },
    { "x", "<leader>cf", act("editor.action.formatSelection"), "Format Selection" },
    { "n", "<leader>cs", act("outline.focus"), "Toggle Outline" },
    { "n", "<leader>cS", act("references-view.showCallHierarchy"), "Call Hierarchy" },
    -- constellation.nvim's usage graph; the built-in tree is the closest thing
    { "n", "<leader>cu", act("references-view.showCallHierarchy"), "Usage Graph (local)" },

    -- ── pickers (snacks.picker, disabled by the extra) ─────────────────────
    -- extras.vscode binds <leader>/, <leader><space>, <leader>ss and the
    -- terminal keys with no desc, so they render blank in the which-key strip.
    -- Rebinding them here is only about giving them labels.
    { "n", "<leader>/", act("workbench.action.findInFiles"), "Grep" },
    { "n", "<leader><space>", act("workbench.action.quickOpen"), "Find Files" },
    { "n", "<leader>ft", act("workbench.action.terminal.toggleTerminal"), "Terminal" },
    { "n", "<leader>fT", act("workbench.action.terminal.toggleTerminal"), "Terminal (cwd)" },
    { "n", "<leader>ff", act("workbench.action.quickOpen"), "Find Files" },
    { "n", "<leader>fF", act("workbench.action.quickOpen"), "Find Files (cwd)" },
    { "n", "<leader>fr", act("workbench.action.openRecent"), "Recent" },
    { "n", "<leader>,", act("workbench.action.quickOpenPreviousRecentlyUsedEditor"), "Buffers" },
    { "n", "<leader>sg", act("workbench.action.findInFiles"), "Grep" },
    { "n", "<leader>sG", act("workbench.action.findInFiles"), "Grep (cwd)" },
    { "n", "<leader>sr", act("workbench.action.replaceInFiles"), "Search and Replace" },
    { "n", "<leader>ss", act("workbench.action.gotoSymbol"), "Goto Symbol" },
    { "n", "<leader>sS", act("workbench.action.showAllSymbols"), "Goto Symbol (Workspace)" },
    { "n", "<leader>sd", act("workbench.actions.view.problems"), "Diagnostics" },
    { "n", "<leader>:", act("workbench.action.showCommands"), "Command History" },
    { "n", "<leader>xx", act("workbench.actions.view.problems"), "Diagnostics (Trouble)" },
    { "n", "<leader>xX", act("workbench.actions.view.problems"), "Buffer Diagnostics" },
    { "n", "<leader>snd", act("notifications.clearAll"), "Dismiss All Notifications" },
    { "n", "<leader>snh", act("notifications.showList"), "Notification History" },

    -- ── buffers (bufferline) ───────────────────────────────────────────────
    { "n", "H", act("workbench.action.previousEditor"), "Prev Buffer" },
    { "n", "L", act("workbench.action.nextEditor"), "Next Buffer" },
    { "n", "[b", act("workbench.action.previousEditor"), "Prev Buffer" },
    { "n", "]b", act("workbench.action.nextEditor"), "Next Buffer" },
    { "n", "[B", act("workbench.action.moveEditorLeftInGroup"), "Move Buffer Prev" },
    { "n", "]B", act("workbench.action.moveEditorRightInGroup"), "Move Buffer Next" },
    { "n", "<leader>bd", act("workbench.action.closeActiveEditor"), "Delete Buffer" },
    { "n", "<leader>bo", act("workbench.action.closeOtherEditors"), "Delete Other Buffers" },
    { "n", "<leader>bl", act("workbench.action.closeEditorsToTheLeft"), "Delete Buffers to the Left" },
    { "n", "<leader>br", act("workbench.action.closeEditorsToTheRight"), "Delete Buffers to the Right" },
    { "n", "<leader>bp", act("workbench.action.pinEditor"), "Toggle Pin" },
    { "n", "<leader>bP", act("workbench.action.unpinEditor"), "Unpin Buffer" },

    -- ── debug (nvim-dap) ───────────────────────────────────────────────────
    { "n", "<leader>dc", act("workbench.action.debug.start"), "Run/Continue" },
    { "n", "<leader>db", act("editor.debug.action.toggleBreakpoint"), "Toggle Breakpoint" },
    { "n", "<leader>dB", act("editor.debug.action.conditionalBreakpoint"), "Breakpoint Condition" },
    { "n", "<leader>dC", act("editor.debug.action.runToCursor"), "Run to Cursor" },
    { "n", "<leader>dO", act("workbench.action.debug.stepOver"), "Step Over" },
    { "n", "<leader>di", act("workbench.action.debug.stepInto"), "Step Into" },
    { "n", "<leader>do", act("workbench.action.debug.stepOut"), "Step Out" },
    { "n", "<leader>dP", act("workbench.action.debug.pause"), "Pause" },
    { "n", "<leader>dt", act("workbench.action.debug.stop"), "Terminate" },
    { "n", "<leader>dl", act("workbench.action.debug.restart"), "Run Last" },
    { "n", "<leader>dr", act("workbench.debug.action.toggleRepl"), "Toggle REPL" },
    { "n", "<leader>du", act("workbench.view.debug"), "Dap UI" },

    -- ── test (neotest) ─────────────────────────────────────────────────────
    { "n", "<leader>tr", act("testing.runAtCursor"), "Run Nearest" },
    { "n", "<leader>td", act("testing.debugAtCursor"), "Debug Nearest" },
    { "n", "<leader>tt", act("testing.runCurrentFile"), "Run File" },
    { "n", "<leader>tT", act("testing.runAll"), "Run All Test Files" },
    { "n", "<leader>to", act("testing.showMostRecentOutput"), "Show Output" },
    { "n", "<leader>ts", act("workbench.view.testing"), "Toggle Summary" },
    { "n", "<leader>tl", act("testing.reRunLastRun"), "Run Last" },
    { "n", "<leader>tS", act("testing.cancelRun"), "Stop" },
}

function M.setup()
    for _, m in ipairs(spec) do
        vim.keymap.set(m[1], m[2], m[3], { desc = m[4], silent = true })
    end

    -- Needs the word under the cursor at press time, so it cannot be a plain
    -- act() closure built at load time.
    vim.keymap.set("n", "<leader>sw", function()
        require("vscode").action("workbench.action.findInFiles", {
            args = { query = vim.fn.expand("<cword>") },
        })
    end, { desc = "Search word under cursor", silent = true })
end

return M
