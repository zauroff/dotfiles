#!/usr/bin/env bash
# PreToolUse hook (Edit|Write): code ships without explanatory comments.
#
# Advisory, not blocking — a hard block would reject shebangs, license headers,
# build directives, and pre-existing comments in files being edited.
#
# Opt out for a machine/checkout by creating ~/.claude/.no-comments-off.

[ -f "$HOME/.claude/.no-comments-off" ] && exit 0

case "$CLAUDE_FILE_PATH" in
  *.go | *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.py | *.rs | *.lua | \
    *.sh | *.bash | *.zsh | *.c | *.h | *.cc | *.cpp | *.hpp | *.java) ;;
  *) exit 0 ;; # not code, nothing to say
esac

cat <<'EOF'
DO NOT WRITE COMMENTS IN THIS CODE.

- No explanatory comments, no section banners, no "// BEFORE/AFTER" markers, no
  restating what the next line does. Name things well instead.
- Delete comments you were about to add before calling Edit/Write. If a snippet
  in your chat reply carried comments as a review aid, strip them from the edit.
- Leave existing comments in the file alone unless the code under them changed.
- Keep only machine-significant lines: shebangs, `//go:` and `#!`-style
  directives, license headers, linter pragmas, and doc comments the language
  tooling requires on exported symbols.
EOF

exit 0
