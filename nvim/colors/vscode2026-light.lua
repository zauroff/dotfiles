-- VS Code "2026 Light" counterpart to vscode2026.lua.
--
-- UI chrome follows VS Code Light+ defaults. Syntax token colors use the
-- GitHub Light palette (the light counterpart of GitHub Dark, which
-- vscode2026.lua's tokenColors are ported from) rather than reusing the dark
-- file's token hexes verbatim: those are pastel colors tuned for a dark
-- background and are close to unreadable on white.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
end
vim.o.background = "light"
vim.o.termguicolors = true
vim.g.colors_name = "vscode2026-light"

local c = {
    -- editor chrome
    bg = "#FFFFFF", -- editor.background
    bg_alt = "#F3F3F3", -- sideBar / panel / statusBar.background
    bg_widget = "#F3F3F3", -- editorWidget.background
    bg_hl = "#F0F0F0", -- editor.lineHighlightBackground
    bg_sel_list = "#E4E6F1", -- list.inactiveSelectionBackground
    border = "#D4D4D4", -- *.border
    fg = "#000000", -- editor.foreground
    fg_ui = "#3B3B3B", -- foreground
    fg_dim = "#6C6C6C", -- descriptionForeground
    fg_faint = "#A5A5A5", -- disabledForeground
    line_nr = "#237893", -- editorLineNumber.foreground
    indent = "#D3D3D3", -- editorIndentGuide.background1 over bg
    indent_on = "#939393", -- editorIndentGuide.activeBackground1
    accent = "#005FB8", -- focusBorder / panelTitle.activeBorder
    link = "#006AB1", -- textLink.foreground
    sel = "#ADD6FF", -- editor.selectionBackground
    sel_dim = "#D6ECFF", -- editor.findMatchBackground
    match = "#B4D8FD", -- editorBracketMatch.background

    -- syntax (GitHub Light tokenColors)
    comment = "#6e7781",
    keyword = "#cf222e",
    constant = "#0550ae",
    string = "#0a3069",
    func = "#8250df",
    tag = "#116329",
    variable = "#953800",
    text = "#1f2328",
    invalid = "#82071e",

    -- diagnostics / git
    error = "#cd3131",
    warn = "#bf8803",
    info = "#1a85ff",
    hint = "#6c6c6c",
    added = "#587c0c",
    modified = "#895503",
    deleted = "#ad0707",
    gutter_add = "#2E7D32",
    gutter_del = "#C62828",
    gutter_mod = "#0078D4",

    -- diff backgrounds
    diff_add = "#e6ffec",
    diff_del = "#ffebe9",
    diff_add_text = "#abf2bc",
    diff_del_text = "#ffc0c0",
    diff_change = "#ddf4ff",
    diff_change_text = "#b6e3ff",
}

-- VS Code Light+'s built-in terminal defaults; matches
-- ghostty/themes/vscode-2026-light and wezterm.lua's light_colors.
local ansi = {
    "#000000", "#cd3131", "#00bc00", "#949800",
    "#0451a5", "#bc05bc", "#0598bc", "#555555",
    "#666666", "#cd3131", "#14ce14", "#b5ba00",
    "#0451a5", "#bc05bc", "#0598bc", "#a5a5a5",
}
for i, hex in ipairs(ansi) do
    vim.g["terminal_color_" .. (i - 1)] = hex
end

local groups = {
    -- base UI
    Normal = { fg = c.fg, bg = c.bg },
    NormalNC = { fg = c.fg, bg = c.bg },
    NormalFloat = { fg = c.fg_ui, bg = c.bg_widget },
    FloatBorder = { fg = c.border, bg = c.bg_widget },
    FloatTitle = { fg = c.fg_ui, bg = c.bg_widget, bold = true },
    ColorColumn = { bg = c.bg_hl },
    Conceal = { fg = c.fg_dim },
    Cursor = { fg = c.bg, bg = c.fg },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    CursorLine = { bg = c.bg_hl },
    CursorColumn = { bg = c.bg_hl },
    CursorLineNr = { fg = c.fg, bold = true },
    LineNr = { fg = c.line_nr },
    LineNrAbove = { fg = c.line_nr },
    LineNrBelow = { fg = c.line_nr },
    SignColumn = { bg = c.bg },
    FoldColumn = { fg = c.line_nr, bg = c.bg },
    Folded = { fg = c.fg_dim, bg = c.bg_hl },
    Directory = { fg = c.constant },
    EndOfBuffer = { fg = c.bg },
    NonText = { fg = c.indent },
    SpecialKey = { fg = c.indent_on },
    Whitespace = { fg = c.indent },
    VertSplit = { fg = c.border },
    WinSeparator = { fg = c.border },
    MatchParen = { bg = c.match, bold = true },
    Visual = { bg = c.sel },
    VisualNOS = { bg = c.sel },
    Search = { bg = c.sel_dim },
    IncSearch = { bg = "#ADD6FF", fg = "#000000" },
    CurSearch = { link = "IncSearch" },
    Substitute = { link = "IncSearch" },
    Title = { fg = c.constant, bold = true },
    Question = { fg = c.constant },
    MoreMsg = { fg = c.constant },
    ModeMsg = { fg = c.fg_ui, bold = true },
    ErrorMsg = { fg = c.error },
    WarningMsg = { fg = c.warn },
    QuickFixLine = { bg = c.bg_sel_list },
    SpellBad = { sp = c.error, undercurl = true },
    SpellCap = { sp = c.warn, undercurl = true },
    SpellLocal = { sp = c.info, undercurl = true },
    SpellRare = { sp = c.hint, undercurl = true },

    StatusLine = { fg = c.fg_dim, bg = c.bg_alt },
    StatusLineNC = { fg = c.fg_faint, bg = c.bg_alt },
    WinBar = { fg = c.fg_dim, bg = c.bg },
    WinBarNC = { fg = c.fg_faint, bg = c.bg },
    TabLine = { fg = c.fg_dim, bg = c.bg_alt },
    TabLineFill = { bg = c.bg_alt },
    TabLineSel = { fg = c.fg_ui, bg = c.bg },

    Pmenu = { fg = c.fg_ui, bg = c.bg_widget },
    PmenuSel = { bg = "#D6EBFF" }, -- editorSuggestWidget.selectedBackground
    PmenuSbar = { bg = c.bg_widget },
    PmenuThumb = { bg = "#C2C2C2" },
    PmenuMatch = { fg = c.link, bold = true },
    PmenuMatchSel = { fg = c.link, bg = "#D6EBFF", bold = true },
    WildMenu = { link = "PmenuSel" },

    -- legacy syntax groups
    Comment = { fg = c.comment, italic = true },
    Constant = { fg = c.constant },
    String = { fg = c.string },
    Character = { fg = c.keyword },
    Number = { fg = c.constant },
    Boolean = { fg = c.constant },
    Float = { fg = c.constant },
    Identifier = { fg = c.text },
    Function = { fg = c.func },
    Statement = { fg = c.keyword },
    Conditional = { fg = c.keyword },
    Repeat = { fg = c.keyword },
    Label = { fg = c.keyword },
    Operator = { fg = c.text },
    Keyword = { fg = c.keyword },
    Exception = { fg = c.keyword },
    PreProc = { fg = c.keyword },
    Include = { fg = c.keyword },
    Define = { fg = c.keyword },
    Macro = { fg = c.constant },
    PreCondit = { fg = c.keyword },
    Type = { fg = c.tag },
    StorageClass = { fg = c.keyword },
    Structure = { fg = c.tag },
    Typedef = { fg = c.tag },
    Special = { fg = c.variable },
    SpecialChar = { fg = c.tag },
    Tag = { fg = c.tag },
    Delimiter = { fg = c.text },
    SpecialComment = { fg = c.comment, italic = true },
    Debug = { fg = c.variable },
    Underlined = { fg = c.link, underline = true },
    Ignore = { fg = c.fg_faint },
    Error = { fg = c.invalid },
    Todo = { fg = c.bg, bg = c.warn, bold = true },

    -- diff
    DiffAdd = { bg = c.diff_add },
    DiffChange = { bg = c.diff_change },
    DiffDelete = { bg = c.diff_del },
    DiffText = { bg = c.diff_add_text },
    diffAdded = { fg = c.added },
    diffRemoved = { fg = c.deleted },
    diffChanged = { fg = c.modified },
    diffFile = { fg = c.constant },
    diffLine = { fg = c.func, bold = true },

    -- diagnostics
    DiagnosticError = { fg = c.error },
    DiagnosticWarn = { fg = c.warn },
    DiagnosticInfo = { fg = c.info },
    DiagnosticHint = { fg = c.hint },
    DiagnosticOk = { fg = c.added },
    DiagnosticUnderlineError = { sp = c.error, undercurl = true },
    DiagnosticUnderlineWarn = { sp = c.warn, undercurl = true },
    DiagnosticUnderlineInfo = { sp = c.info, undercurl = true },
    DiagnosticUnderlineHint = { sp = c.hint, undercurl = true },
    DiagnosticUnderlineOk = { sp = c.added, undercurl = true },
    DiagnosticVirtualTextError = { fg = c.error, bg = "#FDE7E9" },
    DiagnosticVirtualTextWarn = { fg = c.warn, bg = "#FFF3CD" },
    DiagnosticVirtualTextInfo = { fg = c.info, bg = "#DCEEFF" },
    DiagnosticVirtualTextHint = { fg = c.hint, bg = "#F0F0F0" },
    DiagnosticUnnecessary = { fg = c.fg_faint },
    DiagnosticDeprecated = { fg = c.fg_faint, strikethrough = true },

    -- LSP
    LspReferenceText = { bg = "#E4F0FA" }, -- editor.wordHighlightBackground
    LspReferenceRead = { bg = "#E4F0FA" },
    LspReferenceWrite = { bg = "#CDE6FA" },
    LspSignatureActiveParameter = { fg = c.variable, bold = true },
    LspInlayHint = { fg = c.fg_dim, bg = c.bg_hl },
    LspCodeLens = { fg = c.fg_dim },

    -- treesitter
    ["@comment"] = { link = "Comment" },
    ["@comment.error"] = { fg = c.error },
    ["@comment.warning"] = { fg = c.warn },
    ["@comment.todo"] = { link = "Todo" },
    ["@comment.note"] = { fg = c.info },
    ["@constant"] = { fg = c.constant },
    ["@constant.builtin"] = { fg = c.constant },
    ["@constant.macro"] = { fg = c.constant },
    ["@string"] = { fg = c.string },
    ["@string.escape"] = { fg = c.tag, bold = true },
    ["@string.regexp"] = { fg = c.string },
    ["@string.special"] = { fg = c.constant },
    ["@string.special.url"] = { fg = c.string, underline = true },
    ["@character"] = { fg = c.keyword },
    ["@character.special"] = { fg = c.tag },
    ["@number"] = { fg = c.constant },
    ["@boolean"] = { fg = c.constant },
    ["@float"] = { fg = c.constant },
    ["@function"] = { fg = c.func },
    ["@function.builtin"] = { fg = c.func },
    ["@function.call"] = { fg = c.func },
    ["@function.macro"] = { fg = c.func },
    ["@function.method"] = { fg = c.func },
    ["@function.method.call"] = { fg = c.func },
    ["@constructor"] = { fg = c.tag },
    ["@parameter"] = { fg = c.text },
    ["@variable.parameter"] = { fg = c.text },
    ["@keyword"] = { fg = c.keyword },
    ["@keyword.function"] = { fg = c.keyword },
    ["@keyword.operator"] = { fg = c.keyword },
    ["@keyword.return"] = { fg = c.keyword },
    ["@keyword.import"] = { fg = c.keyword },
    ["@keyword.exception"] = { fg = c.keyword },
    ["@keyword.conditional"] = { fg = c.keyword },
    ["@keyword.repeat"] = { fg = c.keyword },
    ["@keyword.directive"] = { fg = c.keyword },
    ["@operator"] = { fg = c.text },
    ["@punctuation.delimiter"] = { fg = c.text },
    ["@punctuation.bracket"] = { fg = c.text },
    ["@punctuation.special"] = { fg = c.keyword },
    ["@type"] = { fg = c.tag },
    ["@type.builtin"] = { fg = c.tag },
    ["@type.definition"] = { fg = c.tag },
    ["@type.qualifier"] = { fg = c.keyword },
    ["@attribute"] = { fg = c.variable },
    ["@property"] = { fg = c.constant },
    ["@field"] = { fg = c.text },
    ["@variable"] = { fg = c.text },
    ["@variable.builtin"] = { fg = c.constant },
    ["@variable.member"] = { fg = c.text },
    ["@module"] = { fg = c.variable },
    ["@namespace"] = { fg = c.variable },
    ["@label"] = { fg = c.keyword },
    ["@tag"] = { fg = c.tag },
    ["@tag.builtin"] = { fg = c.tag },
    ["@tag.attribute"] = { fg = c.constant },
    ["@tag.delimiter"] = { fg = c.text },

    -- markdown
    ["@markup.heading"] = { fg = c.constant, bold = true },
    ["@markup.strong"] = { fg = c.text, bold = true },
    ["@markup.italic"] = { fg = c.text, italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.raw"] = { fg = c.constant },
    ["@markup.link"] = { fg = c.string },
    ["@markup.link.url"] = { fg = c.string, underline = true },
    ["@markup.link.label"] = { fg = c.constant },
    ["@markup.list"] = { fg = c.variable },
    ["@markup.quote"] = { fg = c.tag, italic = true },
    ["@diff.plus"] = { fg = c.added },
    ["@diff.minus"] = { fg = c.deleted },
    ["@diff.delta"] = { fg = c.modified },

    -- LSP semantic tokens
    ["@lsp.type.class"] = { fg = c.tag },
    ["@lsp.type.decorator"] = { fg = c.variable },
    ["@lsp.type.enum"] = { fg = c.tag },
    ["@lsp.type.enumMember"] = { fg = c.constant },
    ["@lsp.type.function"] = { fg = c.func },
    ["@lsp.type.interface"] = { fg = c.tag },
    ["@lsp.type.macro"] = { fg = c.func },
    ["@lsp.type.method"] = { fg = c.func },
    ["@lsp.type.namespace"] = { fg = c.variable },
    ["@lsp.type.parameter"] = { fg = c.text },
    ["@lsp.type.property"] = { fg = c.constant },
    ["@lsp.type.struct"] = { fg = c.tag },
    ["@lsp.type.type"] = { fg = c.tag },
    ["@lsp.type.typeParameter"] = { fg = c.tag },
    ["@lsp.type.variable"] = { fg = c.text },
    ["@lsp.mod.readonly"] = { fg = c.constant },
    ["@lsp.typemod.variable.readonly"] = { fg = c.constant },

    -- gitsigns
    GitSignsAdd = { fg = c.gutter_add },
    GitSignsChange = { fg = c.gutter_mod },
    GitSignsDelete = { fg = c.gutter_del },
    GitSignsAddLn = { bg = c.diff_add },
    GitSignsChangeLn = { bg = c.diff_change },
    GitSignsDeleteLn = { bg = c.diff_del },
    GitSignsCurrentLineBlame = { fg = c.fg_faint },

    -- athena (PR review). Sits above gitsigns in the signcolumn, so both the
    -- PR diff and your uncommitted changes are visible at once.
    AthenaAdd = { fg = c.gutter_add },
    AthenaChange = { fg = c.gutter_mod },
    AthenaDelete = { fg = c.gutter_del },
    AthenaAddLn = { bg = c.diff_add },
    AthenaChangeLn = { bg = c.diff_change },
    -- the cursor line needs to stay visible on top of a tinted line
    AthenaAddCul = { bg = c.diff_add_text },
    AthenaChangeCul = { bg = c.diff_change_text },
    AthenaThread = { fg = c.info },
    AthenaThreadResolved = { fg = c.fg_faint },
    AthenaThreadHeader = { fg = c.fg_ui, bold = true },
    AthenaThreadBody = { fg = c.fg },
    AthenaThreadPending = { fg = c.warn },
    AthenaSidebarDir = { fg = c.fg_faint },
    AthenaSidebarAdd = { fg = c.added },
    AthenaSidebarDel = { fg = c.deleted },
    AthenaSidebarViewed = { fg = c.fg_faint },
    AthenaSidebarUnviewed = { fg = c.accent },

    -- telescope
    TelescopeNormal = { fg = c.fg_ui, bg = c.bg_widget },
    TelescopeBorder = { fg = c.border, bg = c.bg_widget },
    TelescopeTitle = { fg = c.fg_ui, bold = true },
    TelescopePromptNormal = { fg = c.fg_ui, bg = c.bg_widget },
    TelescopePromptBorder = { fg = c.border, bg = c.bg_widget },
    TelescopePromptPrefix = { fg = c.accent },
    TelescopeSelection = { bg = c.bg_sel_list, fg = "#111111" },
    TelescopeMatching = { fg = c.link, bold = true },

    -- snacks / lazy / mason / which-key
    SnacksNormal = { fg = c.fg_ui, bg = c.bg_widget },
    SnacksWinBar = { fg = c.fg_ui, bg = c.bg_widget },
    SnacksBackdrop = { bg = "#000000" },
    SnacksDashboardHeader = { fg = c.accent },
    SnacksDashboardIcon = { fg = c.variable },
    SnacksDashboardDesc = { fg = c.fg_ui },
    SnacksDashboardKey = { fg = c.func },
    SnacksDashboardFooter = { fg = c.fg_dim },
    SnacksIndent = { fg = c.indent },
    SnacksIndentScope = { fg = c.indent_on },
    SnacksPickerDir = { fg = c.fg_dim },
    SnacksPickerMatch = { fg = c.link, bold = true },
    LazyNormal = { fg = c.fg_ui, bg = c.bg_widget },
    MasonNormal = { fg = c.fg_ui, bg = c.bg_widget },
    WhichKey = { fg = c.func },
    WhichKeyGroup = { fg = c.constant },
    WhichKeyDesc = { fg = c.fg_ui },
    WhichKeySeparator = { fg = c.fg_faint },
    WhichKeyNormal = { fg = c.fg_ui, bg = c.bg_widget },

    -- treesitter-context, illuminate, rainbow-delimiters
    TreesitterContext = { bg = c.bg_hl },
    TreesitterContextLineNumber = { fg = c.line_nr, bg = c.bg_hl },
    IlluminatedWordText = { bg = "#E4F0FA" },
    IlluminatedWordRead = { bg = "#E4F0FA" },
    IlluminatedWordWrite = { bg = "#CDE6FA" },
    RainbowDelimiterYellow = { fg = c.warn },
    RainbowDelimiterViolet = { fg = c.func },
    RainbowDelimiterBlue = { fg = c.constant },
    RainbowDelimiterOrange = { fg = c.variable },
    RainbowDelimiterGreen = { fg = c.tag },
    RainbowDelimiterRed = { fg = c.keyword },
    RainbowDelimiterCyan = { fg = c.link },
}

for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
end
