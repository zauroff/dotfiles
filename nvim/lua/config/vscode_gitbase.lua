-- gitsigns change_base for VSCode.
--
-- nvim's signcolumn never reaches Monaco, so the marks come from VSCode's own
-- QuickDiffProvider instead. window.registerQuickDiffProvider is proposal-gated
-- and vscode-neovim ships no enabledApiProposals; scm.createSourceControl is
-- stable as long as you pass only the first three arguments.

local M = {}

---@type { sha: string, ref: string }|nil
M.base = nil

-- ------------------------------------------------------------------- git

---@param args string[]
---@return string[] lines, boolean ok
local function git(args)
    local cmd = vim.list_extend({ "git", "-c", "core.quotepath=false" }, args)
    local out = vim.fn.systemlist(cmd)
    return out, vim.v.shell_error == 0
end

---@return string|nil
local function repo_root()
    local out, ok = git({ "rev-parse", "--show-toplevel" })
    return ok and out[1] or nil
end

local TRUNK = { main = true, master = true, develop = true, dev = true, trunk = true }

---@return string[]
local function candidates()
    local refs = git({
        "for-each-ref",
        "--sort=-committerdate",
        "--format=%(refname:short)",
        "refs/heads",
        "refs/remotes",
    })
    local head = git({ "rev-parse", "--abbrev-ref", "HEAD" })[1]

    local preferred, rest = {}, {}
    for _, r in ipairs(refs) do
        if r ~= head and not r:match("/HEAD$") then
            if TRUNK[(r:gsub("^[^/]+/", ""))] then
                preferred[#preferred + 1] = r
            else
                rest[#rest + 1] = r
            end
        end
    end
    return vim.list_extend(preferred, rest)
end

---@param ref string
---@return { path: string, status: string }[]|nil
local function changed(ref)
    local lines, ok = git({ "diff", "--name-status", ref })
    if not ok then return nil end

    local out = {}
    for _, line in ipairs(lines) do
        local fields = vim.split(line, "\t", { plain = true })
        -- renames arrive as "R100<TAB>old<TAB>new"
        local path = fields[#fields]
        if path and path ~= "" then
            out[#out + 1] = { path = path, status = fields[1]:sub(1, 1) }
        end
    end
    return out
end

-- ------------------------------------------------------------------ vscode

local APPLY = [[
  const { root, ref, label, files } = args;
  const g = globalThis.__gitbase || (globalThis.__gitbase = {});
  g.root = root;
  g.ref = ref;

  const at = (uri, r) =>
    uri.with({ scheme: "git", query: JSON.stringify({ path: uri.fsPath, ref: r }) });

  if (!g.scm) {
    g.scm = vscode.scm.createSourceControl("gitbase", "Diff Base", vscode.Uri.file(root));
    g.group = g.scm.createResourceGroup("changed", "Changed");
    g.group.hideWhenEmpty = true;
  }
  g.scm.label = "Base: " + label;
  g.scm.count = files.length;

  // a plain reassign keeps serving blobs from the previous ref
  g.scm.quickDiffProvider = undefined;
  g.scm.quickDiffProvider = {
    provideOriginalResource(uri) {
      if (uri.scheme !== "file") return null;
      if (!uri.fsPath.startsWith(g.root)) return null;
      return at(uri, g.ref);
    },
  };

  const WORD = { A: "Added", M: "Modified", D: "Deleted", R: "Renamed", C: "Copied" };
  g.group.resourceStates = files.map(({ path, status }) => {
    const uri = vscode.Uri.file(root + "/" + path);
    return {
      resourceUri: uri,
      command: {
        title: "Open Diff",
        command: "vscode.diff",
        arguments: [at(uri, ref), uri, path + " (vs " + label + ")"],
      },
      decorations: {
        strikeThrough: status === "D",
        faded: status === "D",
        tooltip: (WORD[status] || status) + " vs " + label,
      },
    };
  });

  return files.length;
]]

local CLEAR = [[
  const g = globalThis.__gitbase;
  if (!g || !g.scm) return 0;
  g.scm.dispose();
  globalThis.__gitbase = undefined;
  return 1;
]]

local OPEN_MULTI = [[
  const { root, files, ref, title } = args;
  const resources = files.map((f) => {
    const uri = vscode.Uri.file(root + "/" + f);
    const left = uri.with({
      scheme: "git",
      query: JSON.stringify({ path: uri.fsPath, ref }),
    });
    return [uri, left, uri];
  });
  await vscode.commands.executeCommand("vscode.changes", title, resources);
  return resources.length;
]]

local OPEN_SINGLE = [[
  const { file, ref, title } = args;
  const uri = vscode.Uri.file(file);
  const left = uri.with({
    scheme: "git",
    query: JSON.stringify({ path: uri.fsPath, ref }),
  });
  await vscode.commands.executeCommand("vscode.diff", left, uri, title);
  return 1;
]]

---@param code string
---@param a table
local function eval(code, a)
    require("vscode").eval_async(code, { args = a })
end

-- --------------------------------------------------------------- commands

---@param quiet? boolean
function M.apply(quiet)
    if not M.base then return end

    local root = repo_root()
    if not root then
        vim.notify("Not a git repository", vim.log.levels.WARN)
        return
    end

    local files = changed(M.base.sha)
    if not files then
        vim.notify("git diff failed against " .. M.base.ref, vim.log.levels.ERROR)
        return
    end

    eval(APPLY, { root = root, ref = M.base.sha, label = M.base.ref, files = files })

    if not quiet then
        vim.notify(("Diff base: %s (%d file%s)"):format(M.base.ref, #files, #files == 1 and "" or "s"))
    end
end

---@param branch string
---@return boolean ok
function M.set(branch)
    local out, ok = git({ "merge-base", branch, "HEAD" })
    if not ok or not out[1] then
        vim.notify("No merge-base with " .. branch, vim.log.levels.ERROR)
        return false
    end
    M.base = { sha = out[1], ref = branch }
    M.apply()
    return true
end

function M.pick()
    if not repo_root() then
        vim.notify("Not a git repository", vim.log.levels.WARN)
        return
    end

    local branches = candidates()
    if #branches == 0 then
        vim.notify("No other branches to compare against", vim.log.levels.WARN)
        return
    end

    vim.ui.select(branches, { prompt = "Diff base branch" }, function(choice)
        if choice then M.set(choice) end
    end)
end

function M.reset()
    M.base = nil
    eval(CLEAR, {})
    vim.notify("Diff base: HEAD")
end

function M.open()
    local root = repo_root()
    if not root then
        vim.notify("Not a git repository", vim.log.levels.WARN)
        return
    end

    local ref = M.base and M.base.sha or "HEAD"
    local label = M.base and M.base.ref or "HEAD"

    local files = changed(ref)
    if not files then
        vim.notify("git diff failed against " .. label, vim.log.levels.ERROR)
        return
    end
    if #files == 0 then
        vim.notify("No changes against " .. label)
        return
    end

    local paths = vim.tbl_map(function(f) return f.path end, files)
    eval(OPEN_MULTI, {
        root = root,
        files = paths,
        ref = ref,
        title = "Changes vs " .. label .. " (" .. #paths .. ")",
    })
end

function M.file()
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then return end

    local ref = M.base and M.base.sha or "HEAD"
    local label = M.base and M.base.ref or "HEAD"

    eval(OPEN_SINGLE, {
        file = path,
        ref = ref,
        title = vim.fn.fnamemodify(path, ":t") .. " (vs " .. label .. ")",
    })
end

---@return string
function M.status()
    return M.base and (M.base.ref .. " @ " .. M.base.sha:sub(1, 8)) or "HEAD"
end

function M.setup()
    local map = function(lhs, fn, desc)
        vim.keymap.set("n", lhs, fn, { desc = desc, silent = true })
    end

    map("<leader>grb", M.pick, "Diff base: pick branch (merge-base)")
    map("<leader>grr", M.reset, "Diff base: reset to HEAD")
    map("<leader>grd", M.open, "Diff base: open branch changes")
    map("<leader>grf", M.file, "Diff base: this file")

    vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
        group = vim.api.nvim_create_augroup("VscodeGitBase", { clear = true }),
        callback = function()
            if M.base then M.apply(true) end
        end,
    })

    vim.api.nvim_create_user_command("DiffBase", function(o)
        if o.args == "" then
            vim.notify("Diff base: " .. M.status())
        elseif o.args == "reset" then
            M.reset()
        else
            M.set(o.args)
        end
    end, {
        nargs = "?",
        desc = "Set or show the diff base branch",
        complete = function() return vim.list_extend({ "reset" }, candidates()) end,
    })
end

return M
