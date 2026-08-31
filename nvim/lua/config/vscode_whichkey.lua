-- which-key for vscode-neovim, on vim.ui.select.

local M = {}

-- Copied from LazyVim's which-key spec (plugins/editor.lua:68-93) so the group
-- labels read the same in both editors.
local GROUPS = {
    ["<tab>"] = "tabs",
    b = "buffer",
    c = "code",
    d = "debug",
    dp = "profiler",
    f = "file/find",
    g = "git",
    gh = "hunks",
    q = "quit/session",
    s = "search",
    t = "test",
    u = "ui",
    w = "windows",
    x = "diagnostics/quickfix",
}

--- Extra keys that open the picker, on top of <leader>.
---
--- Empty on purpose. Claiming a key here shadows every Vim builtin under it:
--- "g" covers gg, gv, gJ, gq, gu, gU, gf, g;, g~ and dozens more, "[" and "]"
--- cover ]}, ]), ]m, ]s, ]p. Since an unmatched sequence now closes instead of
--- being forwarded, any builtin under a claimed prefix stops working.
---
--- `:WhichKey g` browses a prefix on demand without claiming the key.
local EXTRA_PREFIXES = {}

local function leader()
    return vim.g.mapleader or "\\"
end

---@param tok string
---@return string raw bytes for the token
local function raw(tok)
    return vim.api.nvim_replace_termcodes(tok, true, true, true)
end

---Split a keymap lhs into display tokens, keeping <Tab>/<C-x>/<CR> whole.
---@param lhs string
---@return string[]
local function tokenize(lhs)
    local toks, i = {}, 1
    while i <= #lhs do
        local c = lhs:sub(i, i)
        if c == "<" then
            local j = lhs:find(">", i + 1, true)
            local candidate = j and lhs:sub(i, j) or nil
            -- only a key name if it looks like one and actually translates
            if candidate and candidate:match("^<[%w%-_]+>$") and raw(candidate) ~= candidate then
                toks[#toks + 1] = candidate
                i = j + 1
            else
                toks[#toks + 1] = c
                i = i + 1
            end
        else
            toks[#toks + 1] = c
            i = i + 1
        end
    end
    return toks
end

---@param prefix string raw byte prefix including leader
---@return string
local function prefix_label(prefix)
    local ldr = leader()
    local rest = prefix
    local head = ""
    if ldr ~= "" and vim.startswith(prefix, ldr) then
        head, rest = "<leader>", prefix:sub(#ldr + 1)
    end
    return head .. vim.fn.keytrans(rest)
end

---The mapping bound to exactly `seq`, if any.
---@param mode string
---@param seq string raw byte sequence
---@return table|nil
local function exact(mode, seq)
    for _, list in ipairs({ vim.api.nvim_buf_get_keymap(0, mode), vim.api.nvim_get_keymap(mode) }) do
        for _, m in ipairs(list) do
            if (m.lhsraw or m.lhs) == seq then return m end
        end
    end
    return nil
end

---Collapse everything under `prefix` down to its next keystroke, which-key
---style: one row per distinct next key, branches shown as +group.
---@param mode string "n" or "x"
---@param prefix string raw byte prefix
---@return table[] rows
local function next_keys(mode, prefix)
    local ldr = leader()
    local buckets, order, seen = {}, {}, {}

    local function consider(m)
        if seen[m.lhs] or m.desc == "which_key_ignore" then return end
        seen[m.lhs] = true

        -- walk tokens until their raw bytes equal the prefix, then the token
        -- after that is the key this mapping contributes
        local toks = tokenize(m.lhs)
        local acc = ""
        for i, t in ipairs(toks) do
            if acc == prefix then
                local b = buckets[t]
                if not b then
                    b = { n = 0 }
                    buckets[t] = b
                    order[#order + 1] = t
                end
                b.n = b.n + 1
                if i == #toks then b.leaf = m end
                return
            end
            acc = acc .. raw(t)
            if #acc > #prefix then return end
        end
    end

    for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do consider(m) end
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do consider(m) end

    local rows = {}
    for _, t in ipairs(order) do
        local b = buckets[t]
        local desc, group
        if b.n == 1 and b.leaf then
            desc = b.leaf.desc or "…"
        else
            -- name the branch from LazyVim's group table when it knows it
            local path = prefix .. raw(t)
            if vim.startswith(path, ldr) then path = path:sub(#ldr + 1) end
            group = GROUPS[vim.fn.keytrans(path):lower()] or GROUPS[path]
            desc = "+" .. (group or vim.fn.keytrans(path))
            group = group or true
        end
        rows[#rows + 1] = { t = t, k = t == " " and "␣" or t, d = desc, g = group ~= nil }
    end

    table.sort(rows, function(a, b)
        if a.k:lower() ~= b.k:lower() then return a.k:lower() < b.k:lower() end
        return a.k < b.k
    end)

    -- A sequence can be both a mapping and a prefix: <leader>gh is Diffview
    -- Branch History and also the +hunks group. Vim resolves that by waiting
    -- out timeoutlen, which the getcharstr loop cannot do, so the group would
    -- win and the leaf become unreachable. Offer it on <cr> instead.
    --
    -- Guarded on #rows > 0: without children this row would be the only one,
    -- and the caller reads a non-empty result as "this is a group, descend",
    -- which would trap plain leaves like <leader>ghs one level short.
    if #rows > 0 and not buckets["<CR>"] then
        local leaf = exact(mode, prefix)
        if leaf then
            table.insert(rows, 1, { t = "<CR>", k = "<cr>", d = leaf.desc or "…", g = false, here = true })
        end
    end
    return rows
end

-- ------------------------------------------------------------------- picker

local KEYW = 8

---@param row table
---@return string
local function label(row)
    return row.k .. string.rep(" ", math.max(1, KEYW - vim.fn.strdisplaywidth(row.k))) .. row.d
end

---@param start? string raw prefix to open on; defaults to <leader>
function M.run(start)
    local root = start or leader()

    local m = vim.api.nvim_get_mode().mode:sub(1, 1)
    local visual = m == "v" or m == "V" or m == "\22"
    local mode = visual and "x" or "n"

    local function fire(seq)
        vim.api.nvim_feedkeys((visual and "gv" or "") .. seq, "m", false)
    end

    local descend
    descend = function(prefix)
        local rows = next_keys(mode, prefix)
        if #rows == 0 then
            if exact(mode, prefix) then fire(prefix) end
            return
        end

        vim.ui.select(rows, {
            prompt = prefix_label(prefix),
            format_item = label,
        }, function(row)
            if not row then return end

            if row.here then
                fire(prefix)
                return
            end

            local nextp = prefix .. raw(row.t)
            if row.g then
                descend(nextp)
            elseif exact(mode, nextp) then
                fire(nextp)
            end
        end)
    end

    descend(root)
end

function M.setup()
    vim.opt.timeoutlen = 500

    vim.keymap.set({ "n", "x" }, "<leader>", function()
        M.run()
    end, { desc = "Which-key" })

    for _, p in ipairs(EXTRA_PREFIXES) do
        vim.keymap.set({ "n", "x" }, p, function()
            M.run(p)
        end, { desc = "Which-key: " .. p })
    end

    vim.api.nvim_create_user_command("WhichKey", function(o)
        M.run(o.args ~= "" and o.args or nil)
    end, { nargs = "?", desc = "Which-key picker for a prefix" })
end

return M
