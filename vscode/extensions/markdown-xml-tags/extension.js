const vscode = require("vscode");

const NAME = "[A-Za-z_][\\w.:-]*";
// An open tag alone on its line: not a closing tag, not self-closing.
const OPEN_LINE = new RegExp(`^\\s*<${NAME}(?:\\s[^<>]*)?(?<!/)>\\s*$`);
const CLOSE_AHEAD = new RegExp(`^\\s*</${NAME}\\s*>`);
// An open tag ending at the cursor. The lookbehind skips generics such as List<String>.
const OPEN_BEHIND = new RegExp(`(?<!\\w)<(${NAME})(?:\\s[^<>]*)?(?<!/)>$`);

function activate(context) {
    context.subscriptions.push(
        // Markdown ships no onEnterRules, so this replaces nothing. Same two rules as VSCode's html config, but only
        // for tags alone on their line, so Enter after a tag mentioned mid-sentence does not indent.
        vscode.languages.setLanguageConfiguration("markdown", {
            onEnterRules: [
                {
                    beforeText: OPEN_LINE,
                    afterText: CLOSE_AHEAD,
                    action: { indentAction: vscode.IndentAction.IndentOutdent },
                },
                { beforeText: OPEN_LINE, action: { indentAction: vscode.IndentAction.Indent } },
            ],
        }),
        vscode.workspace.onDidChangeTextDocument(closeTag),
    );
}

function closeTag({ document, contentChanges, reason }) {
    const editor = vscode.window.activeTextEditor;
    if (document.languageId !== "markdown" || reason || contentChanges.length !== 1 || editor?.document !== document) {
        return;
    }

    // rangeLength 1 is VSCode typing over the > it auto-paired with <.
    const change = contentChanges[0];
    if (change.text !== ">" || change.rangeLength > 1) {
        return;
    }

    const line = document.lineAt(change.range.start.line).text;
    const end = change.range.start.character + 1;
    const name = line.slice(0, end).match(OPEN_BEHIND)?.[1];
    if (!name || line.startsWith(`</${name}>`, end)) {
        return;
    }

    editor.insertSnippet(new vscode.SnippetString(`$0</${name}>`), change.range.start.translate(0, 1));
}

module.exports = { activate };
