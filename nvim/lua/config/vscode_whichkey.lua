-- which-key.nvim's popup, mirrored into VSCode as editor decorations.
--
-- which-key runs unchanged: triggers, getcharstr loop, tree, layout. Only its float is invisible, because
-- vscode-neovim never draws nvim floating windows. So every time which-key renders the popup text into that float
-- (view.lua: text:render(M.view.buf)), the same segments are sent to VSCode and drawn over the editor, one
-- decoration per segment on a character grid. Decorations never take focus, so keys keep flowing to nvim.
--
-- VSCode keeps only the first line of a decoration's contentText, and pastes textDecoration into CSS verbatim,
-- which is what lets each segment carry its own position:absolute.

local M = {}

local RENDER = [[
  const { lines, w, title } = args;
  const editor = vscode.window.activeTextEditor;
  const g = globalThis.__whichkey ||
    (globalThis.__whichkey = { type: vscode.window.createTextEditorDecorationType({}) });
  if (g.editor && g.editor !== editor) {
    try { g.editor.setDecorations(g.type, []); } catch {}
  }
  g.editor = editor;
  if (!editor || editor.visibleRanges.length === 0) return 0;

  const ranges = editor.visibleRanges;
  const first = ranges[0].start.line;
  const last = ranges[ranges.length - 1].end.line;
  const h = lines.length;
  const cursor = editor.selection.active.line;

  // Grow up from the second-to-last visible line, like which-key's bottom placement. Grow down from the top
  // instead when that would run off the top or cover the cursor. Growing down may run past the last line of a
  // short file; that space is still editor, and anything past the editor's edge is clipped.
  let anchor = Math.max(ranges[ranges.length - 1].start.line, last - 1);
  let top = 1 - h;
  if (anchor + top < first || (cursor >= anchor + top && cursor <= anchor)) {
    anchor = first;
    top = 0;
  }

  const COLORS = {
    WhichKey: "symbolIcon.functionForeground",
    WhichKeyGroup: "symbolIcon.keywordForeground",
    WhichKeySeparator: "descriptionForeground",
    WhichKeyTitle: "descriptionForeground",
  };
  const range = new vscode.Range(anchor, 0, anchor, 0);
  const box = {
    range,
    renderOptions: { after: {
      contentText: "",
      textDecoration: `none; position:absolute; z-index:10; top:calc(${top} * 1lh); left:0;
        width:calc(${w} * 1ch); height:calc(${h} * 1lh); box-sizing:border-box;
        background:var(--vscode-editorHoverWidget-background);
        border:1px solid var(--vscode-editorHoverWidget-border)`,
    } },
  };
  const text = (row, col, t, hl) => ({
    range,
    renderOptions: { after: {
      contentText: t,
      color: new vscode.ThemeColor(COLORS[hl] || "editor.foreground"),
      textDecoration: `none; position:absolute; z-index:11; white-space:pre;
        top:calc(${top + row} * 1lh); left:calc(${col} * 1ch)`,
    } },
  });

  const decorations = [box];
  // editor.experimentalGpuAcceleration paints text on a canvas stacked above the DOM lines, where no z-index
  // reaches. A line with an `after` decoration falls back to DOM rendering, so tag every line under the box.
  for (let l = Math.max(0, anchor + top); l < Math.min(editor.document.lineCount, anchor + top + h); l++) {
    if (l !== anchor) {
      decorations.push({ range: new vscode.Range(l, 0, l, 0), renderOptions: { after: { contentText: "" } } });
    }
  }
  // row 0 is which-key's top padding line, free for the breadcrumb
  if (title) decorations.push(text(0, 2, title, "WhichKeyTitle"));
  lines.forEach((segs, r) => segs.forEach((s) => decorations.push(text(r, s.c, s.t, s.h))));
  editor.setDecorations(g.type, decorations);
  return decorations.length;
]]

local HIDE = [[
  const g = globalThis.__whichkey;
  if (!g || !g.editor) return 0;
  try { g.editor.setDecorations(g.type, []); } catch {}
  g.editor = undefined;
  return 1;
]]

---@param code string
---@param a? table
local function eval(code, a)
    require("vscode").eval_async(code, { args = a })
end

--- Segments with their display column; blank ones dropped. segment.width is a byte count (text.lua append), which
--- is right for which-key's extmarks but not for screen columns once a separator like ➜ is involved.
---@param text wk.Text
local function payload(text)
    local lines = {}
    for l, line in ipairs(text._lines) do
        local segs, col = {}, 0
        for _, s in ipairs(line) do
            local lead, body = s.str:match("^( *)(.-)%s*$")
            if body ~= "" then
                segs[#segs + 1] = { c = col + #lead, t = body, h = s.hl }
            end
            col = col + vim.fn.strdisplaywidth(s.str)
        end
        lines[l] = segs
    end

    local trail = require("which-key.view").trail(require("which-key.state").state.node, { title = true }) or {}
    local title = vim.trim(table.concat(vim.tbl_map(function(s)
        return s[1]
    end, trail)))

    return { lines = lines, w = text:width(), title = title }
end

function M.setup()
    local Text = require("which-key.text")
    local View = require("which-key.view")
    local shown = false

    local render = Text.render
    Text.render = function(self, buf)
        render(self, buf)
        -- the footer renders into its own buffer first; only the main popup is mirrored
        if View.view and buf == View.view.buf then
            shown = true
            eval(RENDER, payload(self))
        end
    end

    local hide = View.hide
    View.hide = function()
        hide()
        if shown then
            shown = false
            eval(HIDE)
        end
    end
end

return M
