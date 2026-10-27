const RULE_LINE = /^\s*[─━]+(\s+[A-Z0-9+#._-]+\s+[─━]*)?\s*$/;
const RAIL_PREFIX = /^\s*(\d{2,}\s+)?▎ ?/;
const BOX_PREFIX = /^\s*│ ?/;
const BOX_SUFFIX = / ?│\s*$/;

export function cleanCopy(text: string): string {
  return text
    .split("\n")
    .filter((line) => !RULE_LINE.test(line))
    .map((line) => line.replace(RAIL_PREFIX, "").replace(BOX_PREFIX, "").replace(BOX_SUFFIX, ""))
    .join("\n");
}
