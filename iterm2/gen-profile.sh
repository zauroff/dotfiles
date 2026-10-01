#!/usr/bin/env bash
# Prints an iTerm2 dynamic profile (JSON) on stdout for the given theme mode.
#
# profile.json holds everything that does not change between light and dark.
# This script only adds the colors, read from ghostty/themes/asiimov-<mode>
# so the palette stays single-sourced, and wraps the result in the {"Profiles":
# [...]} envelope iTerm2 expects.
#
# iTerm2 has no custom-shader hook, so ghostty's crt*.glsl have no counterpart.
#
# Key names and the magic numbers in profile.json come from iTerm2's own source
# (sources/Settings/Profiles/ITAddressBookMgr.h and
# sources/Keyboard/iTermKeyBindingAction.h):
#   Cursor Type        2 = box
#   Option Key Sends   2 = Esc+ (ghostty macos-option-as-alt)
#   Window Type        0 = normal
#   Keyboard Map keys  "0x<charactersIgnoringModifiers>-0x<modifier mask>".
#                      shift 0x20000, control 0x40000, option 0x80000,
#                      command 0x100000, numeric pad 0x200000 (iTerm2 sets the
#                      numeric pad bit on every arrow key).
#   Keyboard Map Action  0 next tab, 2 previous tab, 11 hex code,
#                      18-21 select pane left/right/above/below,
#                      25 select menu item, 28 split horizontally,
#                      29 split vertically. Split actions take a profile GUID.
#
# Usage: gen-profile.sh [dark|light]
set -euo pipefail

MODE="${1:-dark}"
DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
THEME="$DOTFILES/ghostty/themes/asiimov-$MODE"
PROFILE="$DOTFILES/iterm2/profile.json"

for f in "$THEME" "$PROFILE"; do
    [ -f "$f" ] || {
        echo "gen-profile: missing $f" >&2
        exit 1
    }
done

# Ghostty theme -> iTerm2 color keys. iTerm2 stores no hex: every color is a
# dict of 0-1 floats, so #949800 becomes 0.580392/0.596078/0.0.
COLORS="$(awk '
    function hexval(s,   i, n) {
        n = 0; s = tolower(s)
        for (i = 1; i <= length(s); i++) n = n * 16 + index("0123456789abcdef", substr(s, i, 1)) - 1
        return n
    }
    function dict(hex,   h) {
        h = substr(hex, 2)
        return sprintf("{\"Color Space\":\"sRGB\",\"Red Component\":%.6f,\"Green Component\":%.6f,\"Blue Component\":%.6f,\"Alpha Component\":1}",
                       hexval(substr(h, 1, 2)) / 255, hexval(substr(h, 3, 2)) / 255, hexval(substr(h, 5, 2)) / 255)
    }
    BEGIN {
        m["foreground"]           = "Foreground Color"
        m["background"]           = "Background Color"
        m["cursor-color"]         = "Cursor Color"
        m["cursor-text"]          = "Cursor Text Color"
        m["selection-background"] = "Selection Color"
        m["selection-foreground"] = "Selected Text Color"
    }
    /^[[:space:]]*#/ { next }
    { gsub(/[[:space:]]/, "") }
    /^palette=/ { split($0, a, "="); out["Ansi " a[2] " Color"] = dict(a[3]); next }
    /=/ {
        split($0, a, "=")
        if (a[1] in m) out[m[a[1]]] = dict(a[2])
        # Bold text reuses the normal foreground; Use Bright Bold is off.
        if (a[1] == "foreground") out["Bold Color"] = dict(a[2])
    }
    END {
        printf "{"
        for (k in out) { printf "%s\"%s\":%s", sep, k, out[k]; sep = "," }
        print "}"
    }
' "$THEME")"

# 16 ANSI slots + 7 named colors. A short theme file would otherwise produce a
# profile that silently falls back to iTerm2 defaults for the missing ones.
count="$(printf '%s' "$COLORS" | tr ',' '\n' | grep -c '"Ansi ')"
[ "$count" -eq 16 ] || {
    echo "gen-profile: $THEME defined $count of 16 palette entries" >&2
    exit 1
}

jq -n --slurpfile profile "$PROFILE" --argjson colors "$COLORS" \
    '{ Profiles: [ $profile[0] + $colors ] }'
