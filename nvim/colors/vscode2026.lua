-- VS Code "2026 Dark", ported from microsoft/vscode
-- extensions/theme-defaults/themes/2026-dark.json (UI chrome) plus its
-- tokenColors block (syntax, which is the GitHub Dark palette).
--
-- VS Code colors carry an alpha channel; Neovim highlight groups do not. Where
-- the source value was translucent, the hex below is that color pre-blended
-- over the editor background.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.o.termguicolors = true
vim.g.colors_name = "vscode2026"

local c = {
    -- editor chrome
    bg = "#121314", -- editor.background
    bg_alt = "#191A1B", -- sideBar / panel / statusBar.background
    bg_widget = "#202122", -- editorWidget.background
    bg_hl = "#242526", -- editor.lineHighlightBackground
    bg_sel_list = "#2C2D2E", -- list.inactiveSelectionBackground
    border = "#2A2B2C", -- *.border
    fg = "#BBBEBF", -- editor.foreground
    fg_ui = "#bfbfbf", -- foreground
    fg_dim = "#8C8C8C", -- descriptionForeground
    fg_faint = "#555555", -- disabledForeground
    line_nr = "#858889", -- editorLineNumber.foreground
    indent = "#343536", -- editorIndentGuide.background1 over bg
    indent_on = "#838485", -- editorIndentGuide.activeBackground1
    accent = "#3994BC", -- focusBorder / panelTitle.activeBorder
    link = "#48A0C7", -- textLink.foreground
    sel = "#245C73", -- editor.selectionBackground over bg
    sel_dim = "#1E4252", -- editor.findMatchBackground over bg
    match = "#1F3E4C", -- editorBracketMatch.background over bg

    -- syntax (2026-dark tokenColors)
    comment = "#8b949e",
    keyword = "#ff7b72",
    constant = "#79c0ff",
    string = "#a5d6ff",
    func = "#d2a8ff",
    tag = "#7ee787",
    variable = "#ffa657",
    text = "#c9d1d9",
    invalid = "#ffa198",

    -- diagnostics / git
    error = "#f48771",
    warn = "#e5ba7d",
    info = "#3a94bc",
    hint = "#8C8C8C",
    added = "#73c991",
    modified = "#e5ba7d",
    deleted = "#f48771",
    gutter_add = "#72C892",
    gutter_del = "#F28772",
    gutter_mod = "#0078D4",

    -- diff backgrounds, pre-blended over bg
    diff_add = "#172319",
    diff_del = "#2D1919",
    diff_add_text = "#274129",
    diff_del_text = "#562F2D",
    diff_change = "#1E4252",
}

-- VS Code's built-in dark ANSI defaults; 2026 Dark does not override them.
local ansi = {
    "#000000", "#cd3131", "#0dbc79", "#e5e510",
    "#2472c8", "#bc3fbc", "#11a8cd", "#e5e5e5",
    "#666666", "#f14c4c", "#23d18b", "#f5f543",
    "#3b8eea", "#d670d6", "#29b8db", "#e5e5e5",
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
    IncSearch = { bg = "#276782", fg = "#FFFFFF" },
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
    PmenuSel = { bg = "#33353A" }, -- editorSuggestWidget.selectedBackground over widget bg
    PmenuSbar = { bg = c.bg_widget },
    PmenuThumb = { bg = "#5A5B5C" },
    PmenuMatch = { fg = c.link, bold = true },
    PmenuMatchSel = { fg = c.link, bg = "#33353A", bold = true },
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
    DiagnosticVirtualTextError = { fg = c.error, bg = "#241819" },
    DiagnosticVirtualTextWarn = { fg = c.warn, bg = "#23211C" },
    DiagnosticVirtualTextInfo = { fg = c.info, bg = "#17202A" },
    DiagnosticVirtualTextHint = { fg = c.hint, bg = "#1D1E1F" },
    DiagnosticUnnecessary = { fg = c.fg_faint },
    DiagnosticDeprecated = { fg = c.fg_faint, strikethrough = true },

    -- LSP
    LspReferenceText = { bg = "#1B3B49" }, -- editor.wordHighlightBackground over bg
    LspReferenceRead = { bg = "#1B3B49" },
    LspReferenceWrite = { bg = "#1E4252" },
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

    -- telescope
    TelescopeNormal = { fg = c.fg_ui, bg = c.bg_widget },
    TelescopeBorder = { fg = c.border, bg = c.bg_widget },
    TelescopeTitle = { fg = c.fg_ui, bold = true },
    TelescopePromptNormal = { fg = c.fg_ui, bg = c.bg_widget },
    TelescopePromptBorder = { fg = c.border, bg = c.bg_widget },
    TelescopePromptPrefix = { fg = c.accent },
    TelescopeSelection = { bg = c.bg_sel_list, fg = "#ededed" },
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
    IlluminatedWordText = { bg = "#1B3B49" },
    IlluminatedWordRead = { bg = "#1B3B49" },
    IlluminatedWordWrite = { bg = "#1E4252" },
    RainbowDelimiterYellow = { fg = "#e5ba7d" },
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
