import type { Elements, RenderNode, UiPressArgument } from "claude-code";

import { dotMatrixRows } from "./dotmatrix";
import type { Palette } from "./palette";

type TerminalElements = Elements["terminal"];

type SpanStyle = {
  bold?: true;
  italic?: true;
  strike?: true;
  code?: true;
  link?: true;
};

type Span = { text: string; style: SpanStyle };

type ListItem = {
  depth: number;
  ordinal: number | null;
  task: "open" | "done" | null;
  text: string;
};

type Alignment = "left" | "center" | "right";

type Block =
  | { kind: "paragraph"; text: string }
  | { kind: "heading"; level: number; text: string }
  | { kind: "list"; items: ListItem[] }
  | { kind: "code"; language: string; source: string }
  | { kind: "quote"; source: string; blocks: Block[] }
  | { kind: "callout"; label: string; title: string; blocks: Block[] }
  | {
      kind: "table";
      alignments: Alignment[];
      header: string[];
      rows: string[][];
    }
  | { kind: "rule" };

export type CopyCode = (source: string, press: UiPressArgument) => void;

type MarkdownContext = {
  els: TerminalElements;
  palette: Palette;
  columns: number;
  sections: { count: number };
  codeBlocks: { count: number };
  onCopy?: CopyCode;
};

const MAX_RAIL_ROWS = 2000;
const COPY_LABEL = "copy";
const FENCE = /^\s{0,3}(`{3,}|~{3,})\s*([\w+#.-]*)/;
const HEADING = /^\s{0,3}(#{1,6})\s+(.*?)\s*#*\s*$/;
const RULE = /^\s{0,3}([-*_])(\s*\1){2,}\s*$/;
const LIST_ITEM = /^(\s*)([-*+]|\d+[.)])\s+(?:\[([ xX])\]\s+)?(.*)$/;
const QUOTE = /^\s{0,3}>\s?(.*)$/;
const CALLOUT = /^\[!(\w+)\][+-]?\s*(.*)$/;
const TABLE_DIVIDER = /^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$/;
const TABLE_GAP = 2;
const MIN_TABLE_COLUMN = 3;
const MAX_TABLE_FLOOR = 14;
const NUMERIC = /^[-+]?[\d.,]+\s*(%|[a-zA-Z]{0,3})$/;
const INLINE =
  /(`+)([^`][\s\S]*?)\1(?!`)|\*\*([\s\S]+?)\*\*|__([\s\S]+?)__|~~([\s\S]+?)~~|\*([^*\s][^*]*?)\*|(?<!\w)_([^_\s][^_]*?)_(?!\w)|\[([^\]]+)\]\(([^)\s]+)\)|(https?:\/\/[^\s<>()]+[^\s<>().,;:!?'"])/g;

function splitRow(line: string): string[] {
  return line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split(/(?<!\\)\|/)
    .map((cell) => cell.trim());
}

function alignmentOf(cell: string): Alignment {
  if (cell.startsWith(":") && cell.endsWith(":")) return "center";
  if (cell.endsWith(":")) return "right";
  return "left";
}

function startsBlock(line: string, nextLine: string | undefined): boolean {
  return (
    FENCE.test(line) ||
    HEADING.test(line) ||
    RULE.test(line) ||
    LIST_ITEM.test(line) ||
    QUOTE.test(line) ||
    (line.includes("|") &&
      nextLine !== undefined &&
      TABLE_DIVIDER.test(nextLine))
  );
}

export function parseBlocks(markdown: string): Block[] {
  const blocks: Block[] = [];
  const lines = markdown.split("\n");
  let i = 0;

  while (i < lines.length) {
    const line = lines[i]!;

    if (line.trim() === "") {
      i++;
      continue;
    }

    const fence = line.match(FENCE);
    if (fence) {
      const closer = fence[1]!;
      const sources: string[] = [];
      for (i++; i < lines.length && !lines[i]!.trim().startsWith(closer); i++)
        sources.push(lines[i]!);
      i++;
      blocks.push({
        kind: "code",
        language: fence[2] ?? "",
        source: sources.join("\n"),
      });
      continue;
    }

    const heading = line.match(HEADING);
    if (heading) {
      blocks.push({
        kind: "heading",
        level: heading[1]!.length,
        text: heading[2]!,
      });
      i++;
      continue;
    }

    if (RULE.test(line)) {
      blocks.push({ kind: "rule" });
      i++;
      continue;
    }

    if (line.includes("|") && TABLE_DIVIDER.test(lines[i + 1] ?? "")) {
      const header = splitRow(line);
      const alignments = splitRow(lines[i + 1]!).map(alignmentOf);
      const rows: string[][] = [];
      for (
        i += 2;
        i < lines.length && lines[i]!.includes("|") && lines[i]!.trim() !== "";
        i++
      ) {
        rows.push(splitRow(lines[i]!));
      }
      blocks.push({ kind: "table", alignments, header, rows });
      continue;
    }

    if (QUOTE.test(line)) {
      const quoted: string[] = [];
      for (; i < lines.length && QUOTE.test(lines[i]!); i++)
        quoted.push(lines[i]!.match(QUOTE)![1]!);
      const callout = quoted[0]!.match(CALLOUT);
      if (callout) {
        blocks.push({
          kind: "callout",
          label: callout[1]!.toUpperCase(),
          title: callout[2]!,
          blocks: parseBlocks(quoted.slice(1).join("\n")),
        });
      } else {
        const source = quoted.join("\n");
        blocks.push({ kind: "quote", source, blocks: parseBlocks(source) });
      }
      continue;
    }

    if (LIST_ITEM.test(line)) {
      const items: ListItem[] = [];
      while (i < lines.length) {
        const current = lines[i]!;
        const match = current.match(LIST_ITEM);
        if (match) {
          const marker = match[2]!;
          const box = match[3];
          items.push({
            depth: Math.floor(match[1]!.replace(/\t/g, "  ").length / 2),
            ordinal: /\d/.test(marker) ? parseInt(marker, 10) : null,
            task: box === undefined ? null : box === " " ? "open" : "done",
            text: match[4]!,
          });
          i++;
          continue;
        }
        if (
          /^\s{2,}\S/.test(current) &&
          !startsBlock(current.trim(), lines[i + 1])
        ) {
          items.at(-1)!.text += ` ${current.trim()}`;
          i++;
          continue;
        }
        if (current.trim() === "" && LIST_ITEM.test(lines[i + 1] ?? "")) {
          i++;
          continue;
        }
        break;
      }
      blocks.push({ kind: "list", items });
      continue;
    }

    const paragraph: string[] = [];
    for (
      ;
      i < lines.length &&
      lines[i]!.trim() !== "" &&
      !startsBlock(lines[i]!, lines[i + 1]);
      i++
    ) {
      paragraph.push(lines[i]!.trim());
    }
    if (paragraph.length === 0) {
      paragraph.push(line.trim());
      i++;
    }
    blocks.push({ kind: "paragraph", text: paragraph.join(" ") });
  }

  return blocks;
}

function parseInline(text: string, style: SpanStyle = {}): Span[] {
  const spans: Span[] = [];
  let last = 0;

  for (const match of text.matchAll(INLINE)) {
    const start = match.index!;
    if (start > last) spans.push({ text: text.slice(last, start), style });

    const [
      ,
      ,
      code,
      bold,
      boldAlt,
      strike,
      italic,
      italicAlt,
      linkText,
      ,
      bareUrl,
    ] = match;
    if (code !== undefined)
      spans.push({ text: code.trim(), style: { ...style, code: true } });
    else if (bold !== undefined || boldAlt !== undefined) {
      spans.push(...parseInline((bold ?? boldAlt)!, { ...style, bold: true }));
    } else if (strike !== undefined)
      spans.push(...parseInline(strike, { ...style, strike: true }));
    else if (italic !== undefined || italicAlt !== undefined) {
      spans.push(
        ...parseInline((italic ?? italicAlt)!, { ...style, italic: true }),
      );
    } else if (linkText !== undefined)
      spans.push(...parseInline(linkText, { ...style, link: true }));
    else if (bareUrl !== undefined)
      spans.push({ text: bareUrl, style: { ...style, link: true } });

    last = start + match[0].length;
  }

  if (last < text.length) spans.push({ text: text.slice(last), style });
  return spans;
}

function plainText(text: string): string {
  return parseInline(text)
    .map((span) => span.text)
    .join("");
}

function chip(
  ctx: MarkdownContext,
  label: string,
  background: string,
): RenderNode {
  const { Text } = ctx.els;
  return (
    <Text bold color={ctx.palette.onChip} backgroundColor={background}>
      {` ${label} `}
    </Text>
  );
}

function renderSpans(
  ctx: MarkdownContext,
  text: string,
  color: string,
  extra: SpanStyle = {},
): RenderNode {
  const { Text } = ctx.els;
  const { palette } = ctx;

  return (
    <Text color={color} wrap="wrap">
      {parseInline(text, extra).map(({ text: spanText, style }) => (
        <Text
          color={
            style.code ? palette.blue : style.link ? palette.orange : color
          }
          backgroundColor={style.bold ? palette.highlight : undefined}
          bold={style.bold}
          italic={style.italic}
          strikethrough={style.strike}
          underline={style.link}
        >
          {spanText}
        </Text>
      ))}
    </Text>
  );
}

function renderHeading(
  ctx: MarkdownContext,
  level: number,
  text: string,
): RenderNode {
  const { Box, Text } = ctx.els;
  const { palette, columns } = ctx;
  const title = plainText(text);

  if (level === 1) {
    const rows = dotMatrixRows(title, columns);
    if (rows === null) {
      return (
        <Text bold color={palette.ink}>
          {title.toUpperCase().split("").join(" ")}
        </Text>
      );
    }
    return (
      <Box flexDirection="column">
        {rows.map((row) => (
          <Text>
            {row.map((dot) =>
              dot === "on" ? (
                <Text color={palette.ink}>● </Text>
              ) : dot === "off" ? (
                <Text color={palette.dim}>· </Text>
              ) : (
                " "
              ),
            )}
          </Text>
        ))}
      </Box>
    );
  }

  if (level === 2) {
    ctx.sections.count += 1;
    return (
      <Text>
        {chip(ctx, String(ctx.sections.count).padStart(2, "0"), palette.ink)}
        <Text bold color={palette.ink}>
          {"  "}
          {title.toUpperCase()}
        </Text>
      </Text>
    );
  }

  return (
    <Text bold color={palette.grey}>
      {level === 3 ? "— " : ""}
      {title.toUpperCase()}
    </Text>
  );
}

function renderList(ctx: MarkdownContext, items: ListItem[]): RenderNode {
  const { Box, Text } = ctx.els;
  const { palette } = ctx;

  return (
    <Box flexDirection="column">
      {items.map((item) => {
        const isDone = item.task === "done";
        const marker =
          item.task === "done" ? (
            <Text color={palette.green}>☑</Text>
          ) : item.task === "open" ? (
            <Text color={palette.orange}>☐</Text>
          ) : item.ordinal !== null ? (
            chip(ctx, String(item.ordinal), palette.orange)
          ) : (
            <Text color={palette.orange}>▪</Text>
          );

        return (
          <Box flexDirection="row" paddingLeft={item.depth * 2} columnGap={1}>
            <Box flexShrink={0}>{marker}</Box>
            <Box flexGrow={1} flexShrink={1}>
              {renderSpans(
                ctx,
                item.text,
                isDone ? palette.grey : palette.ink,
                isDone ? { strike: true } : {},
              )}
            </Box>
          </Box>
        );
      })}
    </Box>
  );
}

function longestWord(text: string): number {
  return Math.max(0, ...text.split(/\s+/).map((word) => word.length));
}

export function columnWidths(
  naturals: number[],
  floors: number[],
  available: number,
): number[] | null {
  const floorTotal = floors.reduce((sum, width) => sum + width, 0);
  if (floorTotal > available) return null;
  if (naturals.reduce((sum, width) => sum + width, 0) <= available)
    return naturals;

  const wants = naturals.map((natural, c) => natural - floors[c]!);
  const wantTotal = wants.reduce((sum, want) => sum + want, 0);
  const spare = available - floorTotal;
  const widths = floors.map(
    (floor, c) => floor + Math.floor((spare * wants[c]!) / wantTotal),
  );
  let leftover = available - widths.reduce((sum, width) => sum + width, 0);
  for (let c = 0; leftover > 0; c = (c + 1) % widths.length) {
    if (widths[c]! < naturals[c]!) {
      widths[c] = widths[c]! + 1;
      leftover -= 1;
    }
  }
  return widths;
}

function renderStackedTable(
  ctx: MarkdownContext,
  block: Extract<Block, { kind: "table" }>,
  columnCount: number,
): RenderNode {
  const { Box, Text } = ctx.els;
  const { palette } = ctx;
  const labels = Array.from({ length: columnCount }, (_, c) =>
    plainText(block.header[c] ?? "").toUpperCase(),
  );
  const labelWidth = Math.min(
    Math.max(...labels.map((label) => label.length)),
    Math.floor(ctx.columns / 3),
  );

  return (
    <Box flexDirection="column">
      <Text color={palette.rule}>{"─".repeat(ctx.columns)}</Text>
      {block.rows.map((row) => (
        <Box flexDirection="column">
          {labels.map((label, c) => (
            <Box flexDirection="row" columnGap={TABLE_GAP}>
              <Box width={labelWidth} flexShrink={0}>
                <Text color={palette.grey} wrap="truncate-end">
                  {label}
                </Text>
              </Box>
              <Box flexGrow={1} flexShrink={1}>
                {renderSpans(ctx, row[c] ?? "", palette.ink)}
              </Box>
            </Box>
          ))}
          <Text color={palette.rule}>{"─".repeat(ctx.columns)}</Text>
        </Box>
      ))}
    </Box>
  );
}

function renderTable(
  ctx: MarkdownContext,
  block: Extract<Block, { kind: "table" }>,
): RenderNode {
  const { Box, Text } = ctx.els;
  const { palette } = ctx;
  const columnCount = Math.max(
    block.header.length,
    ...block.rows.map((row) => row.length),
  );
  const cellsOf = (c: number) => [
    plainText(block.header[c] ?? "").toUpperCase(),
    ...block.rows.map((row) => plainText(row[c] ?? "")),
  ];
  const naturals = Array.from({ length: columnCount }, (_, c) =>
    Math.max(MIN_TABLE_COLUMN, ...cellsOf(c).map((cell) => cell.length)),
  );
  const floors = naturals.map((natural, c) =>
    Math.min(
      natural,
      Math.max(MIN_TABLE_COLUMN, Math.min(MAX_TABLE_FLOOR, ...cellsOf(c).map(longestWord))),
    ),
  );
  const widths = columnWidths(
    naturals,
    floors,
    ctx.columns - TABLE_GAP * (columnCount - 1),
  );
  if (widths === null) return renderStackedTable(ctx, block, columnCount);

  const isNumeric = (c: number) =>
    block.rows.length > 0 &&
    block.rows.every((row) => NUMERIC.test(plainText(row[c] ?? "").trim()));
  const justifyOf = (c: number) => {
    const alignment =
      block.alignments[c] === "left" && isNumeric(c)
        ? "right"
        : block.alignments[c];
    return alignment === "right"
      ? "flex-end"
      : alignment === "center"
        ? "center"
        : "flex-start";
  };
  const rule = "─".repeat(
    widths.reduce((sum, width) => sum + width, 0) + TABLE_GAP * (columnCount - 1),
  );

  return (
    <Box flexDirection="column">
      <Box flexDirection="row" columnGap={TABLE_GAP}>
        {widths.map((width, c) => (
          <Box width={width} flexShrink={0} justifyContent={justifyOf(c)}>
            <Text color={palette.grey} wrap="wrap">
              {plainText(block.header[c] ?? "").toUpperCase()}
            </Text>
          </Box>
        ))}
      </Box>
      <Text color={palette.rule}>{rule}</Text>
      {block.rows.map((row) => (
        <Box flexDirection="row" columnGap={TABLE_GAP}>
          {widths.map((width, c) => (
            <Box width={width} flexShrink={0} justifyContent={justifyOf(c)}>
              {renderSpans(ctx, row[c] ?? "", palette.ink)}
            </Box>
          ))}
        </Box>
      ))}
      <Text color={palette.rule}>{rule}</Text>
    </Box>
  );
}

function renderBlock(ctx: MarkdownContext, block: Block): RenderNode {
  const { Box, Text, Code } = ctx.els;
  const { palette } = ctx;

  switch (block.kind) {
    case "paragraph":
      return renderSpans(ctx, block.text, palette.ink);
    case "heading":
      return renderHeading(ctx, block.level, block.text);
    case "list":
      return renderList(ctx, block.items);
    case "table":
      return renderTable(ctx, block);
    case "rule":
      return <Text color={palette.rule}>{"─".repeat(ctx.columns)}</Text>;
    case "code": {
      const { Button } = ctx.els;
      const { onCopy } = ctx;
      ctx.codeBlocks.count += 1;
      const copyKey = `copy:${ctx.codeBlocks.count}`;
      const hasHeader = block.language !== "" || onCopy !== undefined;
      return (
        <Box flexDirection="column" backgroundColor={palette.codeBg} paddingX={1}>
          {hasHeader && (
            <Box flexDirection="row" justifyContent="space-between">
              <Text color={palette.grey}>{block.language.toUpperCase()}</Text>
              {onCopy !== undefined && (
                <Button key={copyKey} plain onPress={(press) => onCopy(block.source, press)}>
                  <Text color={palette.grey}>{COPY_LABEL}</Text>
                </Button>
              )}
            </Box>
          )}
          <Code source={block.source} language={block.language || undefined} />
        </Box>
      );
    }
    case "quote":
      return (
        <Box paddingLeft={2} flexDirection="column">
          {rail(
            ctx.els,
            palette.rule,
            wrappedRows(block.source, ctx.columns - 2),
          )}
          {renderBlocks(
            {
              ...ctx,
              columns: ctx.columns - 2,
              palette: { ...palette, ink: palette.grey },
            },
            block.blocks,
          )}
        </Box>
      );
    case "callout":
      return (
        <Box flexDirection="column" rowGap={1}>
          <Text>
            {chip(ctx, block.label, palette.orange)}
            {block.title !== "" && (
              <Text bold color={palette.ink}>
                {"  "}
                {block.title}
              </Text>
            )}
          </Text>
          {renderBlocks(ctx, block.blocks)}
        </Box>
      );
  }
}

export function wrappedRows(text: string, width: number): number {
  return text
    .split("\n")
    .reduce(
      (rows, line) =>
        rows + Math.max(1, Math.ceil(line.length / Math.max(1, width))),
      0,
    );
}

export function rail(
  els: TerminalElements,
  color: string,
  rows: number,
): RenderNode {
  const { Box, Text } = els;

  return (
    <Box
      position="absolute"
      top={0}
      bottom={0}
      left={0}
      width={1}
      overflow="hidden"
      flexDirection="column"
    >
      <Text color={color}>
        {Array.from(
          { length: Math.max(1, Math.min(rows, MAX_RAIL_ROWS)) },
          () => "▎",
        ).join("\n")}
      </Text>
    </Box>
  );
}

function renderBlocks(ctx: MarkdownContext, blocks: Block[]): RenderNode {
  const { Box } = ctx.els;

  return (
    <Box flexDirection="column" rowGap={1}>
      {blocks.map((block) => renderBlock(ctx, block))}
    </Box>
  );
}

export function renderMarkdown(
  els: TerminalElements,
  palette: Palette,
  columns: number,
  markdown: string,
  onCopy?: CopyCode,
): RenderNode {
  return renderBlocks(
    { els, palette, columns, sections: { count: 0 }, codeBlocks: { count: 0 }, onCopy },
    parseBlocks(markdown),
  );
}
