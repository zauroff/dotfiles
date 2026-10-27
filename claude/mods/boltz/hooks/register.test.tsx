import { expect, mock, test } from "claude-code/testing";

import { cleanCopy } from "./copy";
import { columnWidths } from "./markdown";
import { PALETTES } from "./palette";

const CALL = { isRunning: false, isErrored: false, isInterrupted: false };

const TOOL_GROUP = {
  plugin: "boltz",
  surface: "terminal",
  component: "ToolGroup",
  props: {
    calls: [
      { ...CALL, tool: "Read", input: { file_path: "/a/b.go" } },
      { ...CALL, tool: "Read", input: { file_path: "/a/c.go" } },
      { ...CALL, tool: "Grep", input: { pattern: "foo" } },
    ],
    isActive: false,
    isExpanded: false,
  },
} as const;

const BASH_ROW = {
  plugin: "boltz",
  surface: "terminal",
  component: "ToolUse",
  requestId: "t1",
  props: {
    ...CALL,
    tool_use_id: "t1",
    tool: "Bash",
    input: { command: "go test ./..." },
  },
} as const;

const REPLY = [
  "# Findings",
  "",
  "The planner drops **agent-3** because `viableNodes` filters it out.",
  "",
  "## Root cause",
  "",
  "1. Agent-3 rejoined late.",
  "2. Modules never re-published.",
  "",
  "- [x] reproduced",
  "- [ ] fix reconnect",
  "",
  "| Agent | Modules |",
  "| ----- | ------- |",
  "| a-1   | 14      |",
].join("\n");

const SUBMIT = {
  origin: { kind: "composer" },
  presentation: { isFullscreen: false, columns: 120 },
} as const;

type DrawnNode = {
  type?: string;
  props?: Record<string, unknown>;
  children?: unknown[];
};

function childrenOf(node: unknown): unknown[] {
  return typeof node === "object" && node !== null
    ? ((node as DrawnNode).children ?? [])
    : [];
}

function textOf(node: unknown): string {
  return typeof node === "string"
    ? node
    : childrenOf(node).map(textOf).join("");
}

function boxesOf(node: unknown): DrawnNode[] {
  if (typeof node !== "object" || node === null) return [];
  const own = (node as DrawnNode).type === "Box" ? [node as DrawnNode] : [];
  return [...own, ...childrenOf(node).flatMap(boxesOf)];
}

test("leaves prompts as Claude Code draws them", async ($, on) => {
  on("ui.render", { component: "UserMessage" }, ($, e) => {
    const { Text } = $.ui.resolve(e);
    return <Text>stock {e.props.text}</Text>;
  });
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "UserMessage",
    requestId: "prompt-stock",
    props: {
      text: "why is agent-3 skipped?",
      origin: { kind: "composer" },
      isExpanded: false,
    },
  });

  expect(
    await ui.find({ type: "Text", text: "stock why is agent-3 skipped?" }),
  ).toBeDefined();
  expect(await ui.find({ type: "Text", text: /▶/ })).toBeUndefined();
  await ui.unmount();
});

test("numbers only the first block of each reply", async ($, on) => {
  const opening = "BFS over an adjacency list returns nodes in visit order.";
  const closing = "That covers the reconnect path and the backoff case too.";
  on("session.messages", () => ({
    value: [
      { role: "user", text: "give me a go snippet for bfs", toolUses: [] },
      { role: "assistant", text: opening, toolUses: [] },
      { role: "assistant", text: closing, toolUses: [] },
    ],
  }));
  const reply = (requestId: string, text: string) =>
    $.ui.mount({
      plugin: "boltz",
      surface: "terminal",
      component: "AssistantMessage",
      requestId,
      props: { text, isFirstOfReply: true },
    });
  const first = await reply("reply-open", opening);
  const second = await reply("reply-close", closing);

  expect(await first.find({ type: "Text", text: "01" })).toBeDefined();
  expect(await second.find({ type: "Text", text: "01" })).toBeUndefined();
  await first.unmount();
  await second.unmount();
});

test("draws a reply with no border rows or margin around code", async ($) => {
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "AssistantMessage",
    viewport: { columns: 60, rows: 40 },
    props: {
      text: "BFS over a list.\n\n```go\nfunc BFS() {}\n```\n\n> quoted",
      isFirstOfReply: true,
    },
  });
  const boxes = boxesOf(await ui.drawn());
  const bordered = boxes.filter((box) => box.props?.borderStyle);

  expect(bordered).toEqual([]);
  expect(boxes.filter((box) => box.props?.backgroundColor).length).toBe(1);
  expect(
    boxes.filter((box) => box.props?.position === "absolute").length,
  ).toBeGreaterThan(0);
  await ui.unmount();
});

test("draws a tool row with a category label", async ($) => {
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "ToolUse",
    requestId: "t1",
    props: {
      ...CALL,
      tool_use_id: "t1",
      tool: "Bash",
      input: { command: "go test ./..." },
    },
  });

  expect(await ui.find({ type: "Text", text: "BASH" })).toBeDefined();
  expect(await ui.find({ type: "Text", text: "go test ./..." })).toBeDefined();
  await ui.unmount();
});

test("folds a tool group into one summary line", async ($) => {
  const ui = await $.ui.mount(TOOL_GROUP);

  expect(
    await ui.find({ type: "Text", text: "READ 2 · GREP 1" }),
  ).toBeDefined();
  await ui.unmount();
});

test("renders the reply without a title, with dot-matrix h1 and numbered h2", async ($) => {
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "AssistantMessage",
    props: { text: REPLY, isFirstOfReply: true },
  });

  expect(await ui.find({ type: "Text", text: "CLAUDE" })).toBeUndefined();
  expect(await ui.find({ type: "Text", text: "● " })).toBeDefined();
  expect(await ui.find({ type: "Text", text: " 01 " })).toBeDefined();
  expect(await ui.find({ type: "Text", text: /ROOT CAUSE/ })).toBeDefined();
  expect(await ui.find({ type: "Text", text: " 2 " })).toBeDefined();
  expect(await ui.find({ type: "Text", text: "☑" })).toBeDefined();
  expect(await ui.find({ type: "Text", text: "MODULES" })).toBeDefined();
  await ui.unmount();
});

test("/boltz off reverts the tool group to stock", async ($, on) => {
  on("ui.render", { component: "ToolGroup" }, ($, e) => {
    const { Text } = $.ui.resolve(e);
    return <Text>stock</Text>;
  });
  await $.command.run({ command: "boltz", args: "off", ...SUBMIT });
  const ui = await $.ui.mount(TOOL_GROUP);

  expect(await ui.find({ type: "Text", text: /READ 2/ })).toBeUndefined();
  expect(await ui.find({ type: "Text", text: "stock" })).toBeDefined();
  await ui.unmount();
});

const THEME_CASES = [
  { name: "light", setting: "light", files: {}, want: "light" },
  {
    name: "daltonized dark",
    setting: "dark-daltonized",
    files: {},
    want: "dark",
  },
  {
    name: "custom theme with a light base",
    setting: "custom:paper",
    files: { "/home/u/.claude/themes/paper.json": '{"base":"light"}' },
    want: "light",
  },
  {
    name: "custom theme named light without a file",
    setting: "custom:my-light",
    files: {},
    want: "light",
  },
  {
    name: "unknown theme falls back to the toggle file",
    setting: "auto",
    files: { "/home/u/.config/.current-theme": "light\n" },
    want: "light",
  },
] as const;

for (const tc of THEME_CASES) {
  test(`/boltz auto follows the ${tc.name} theme`, async ($, on) => {
    const files: Record<string, string> = tc.files;
    mock.env(on, { HOME: "/home/u" });
    on("settings.read", () => ({ value: { theme: tc.setting } }));
    on("fs.read", (_$, e) => {
      const text = files[e.path];
      return text === undefined ? { deny: "ENOENT" } : { value: text };
    });
    const ran = await $.command.run({
      command: "boltz",
      args: "auto",
      ...SUBMIT,
    });
    const ui = await $.ui.mount(BASH_ROW);

    expect(ran.text).toBe(`boltz auto (${tc.want}).`);
    expect((await ui.find({ type: "Text", text: "BASH" }))?.props.color).toBe(
      PALETTES[tc.want].orange,
    );
    await ui.unmount();
  });
}

test("/boltz dark overrides a light Claude Code theme", async ($, on) => {
  on("settings.read", () => ({ value: { theme: "light" } }));
  await $.command.run({ command: "boltz", args: "dark", ...SUBMIT });
  const ui = await $.ui.mount(BASH_ROW);

  expect((await ui.find({ type: "Text", text: "BASH" }))?.props.color).toBe(
    PALETTES.dark.orange,
  );
  await ui.unmount();
});

test("picks up a theme change made outside the session", async ($, on) => {
  const clock = mock.clock(on);
  let setting = "dark";
  on("settings.read", () => ({ value: { theme: setting } }));
  on("session.start", (_$, e) => ({ cwd: e.cwd }));
  on("command.register", (_$, e) => ({ value: { command: e.name } }));
  await $.session.start({ cwd: "/", surface: "terminal", isInteractive: true });
  setting = "light";
  await clock.advance(2000);
  const ui = await $.ui.mount(BASH_ROW);

  expect((await ui.find({ type: "Text", text: "BASH" }))?.props.color).toBe(
    PALETTES.light.orange,
  );
  await ui.unmount();
});

test("fits table columns to the width without going below each longest word", () => {
  expect(columnWidths([10, 20], [5, 8], 40)).toEqual([10, 20]);
  expect(columnWidths([13, 90, 50], [13, 14, 14], 68)).toEqual([13, 33, 22]);
  expect(columnWidths([13, 90, 50], [13, 14, 14], 30)).toBeNull();
});

test("stacks a table into label rows when the pane is too narrow", async ($) => {
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "AssistantMessage",
    viewport: { columns: 34, rows: 40 },
    props: {
      text: [
        "| Reviewer | Issue | Your reply |",
        "| --- | --- | --- |",
        "| pr-review-bot | Forwarded cookies leak the session | Fixed |",
      ].join("\n"),
      isFirstOfReply: true,
    },
  });

  expect(await ui.find({ type: "Text", text: "REVIEWER" })).toBeDefined();
  expect(await ui.find({ type: "Text", text: "pr-review-bot" })).toBeDefined();
  await ui.unmount();
});

test("numbers a reply while it is still being written", async ($, on) => {
  let stored: {
    role: "user" | "assistant";
    text: string;
    toolUses: never[];
  }[] = [
    { role: "user", text: "first question", toolUses: [] },
    { role: "assistant", text: "first answer", toolUses: [] },
  ];
  on("session.messages", () => ({ value: stored }));
  on("prompt.submit", (_$, e) => ({ text: e.text }));
  await $.prompt.submit({
    text: "second question",
    wait: false,
    origin: { kind: "composer" },
  });
  stored = [...stored, { role: "user", text: "second question", toolUses: [] }];
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "AssistantMessage",
    requestId: "live-reply",
    props: { text: "Streaming the second answer now", isFirstOfReply: true },
  });

  expect(await ui.find({ type: "Text", text: "02" })).toBeDefined();
  await ui.unmount();
});

test("strips rails, gutters and code rules from copied text", () => {
  const copied = [
    "02   ▎ Run the tests first:",
    "     ▎",
    "── BASH ──────────────────",
    "go test ./server/...",
    "──────────────────────────",
    "│ legacy boxed line │",
  ].join("\n");

  expect(cleanCopy(copied)).toBe(
    [
      "Run the tests first:",
      "",
      "go test ./server/...",
      "legacy boxed line",
    ].join("\n"),
  );
});

test("copies a code block's exact source from its copy button", async ($, on) => {
  const copies: string[] = [];
  on("ui.copy", (_$, e) => {
    copies.push(e.text);
    return { value: { isCopied: true } };
  });
  on("ui.toast", () => ({ value: undefined }));
  const source = "│ tree\n──────\nfunc main() {}";
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "AssistantMessage",
    requestId: "copy-reply",
    props: {
      text: `Here:\n\n\`\`\`go\n${source}\n\`\`\``,
      isFirstOfReply: true,
    },
  });

  await ui.press({ key: "copy:1" });

  expect(copies).toEqual([source]);
  await ui.unmount();
});

test("keeps numbering the reply when a subagent's turn ends mid-turn", async ($, on) => {
  const stored = [
    { role: "user" as const, text: "first question", toolUses: [] },
    { role: "assistant" as const, text: "first answer", toolUses: [] },
  ];
  on("session.messages", () => ({ value: stored }));
  on("prompt.submit", (_$, e) => ({ text: e.text }));
  on("turn.complete", (_$, e) => ({ text: e.answer }));
  await $.prompt.submit({
    text: "second question",
    wait: false,
    origin: { kind: "composer" },
  });
  await $.turn.complete({
    turnId: "sub-1",
    agentId: "agent-1",
    reason: "answer",
    answer: "subagent done",
    durationMs: 1200,
    isAborted: false,
  });
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "AssistantMessage",
    requestId: "after-subagent",
    props: {
      text: "Most likely yes, the queue is constantly full",
      isFirstOfReply: true,
    },
  });

  expect(await ui.find({ type: "Text", text: "02" })).toBeDefined();
  await ui.unmount();
});

test("colours diff blocks line by line, with or without hunk headers", async ($) => {
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "AssistantMessage",
    viewport: { columns: 80, rows: 40 },
    props: {
      text: [
        "```diff",
        "--- a/app.ts",
        "+++ b/app.ts",
        "@@ -1,3 +1,3 @@",
        "   useEffect(() => {",
        "-    if (!enabled) {",
        "+    if (enabled) {",
        "--- removed lua comment",
        "```",
      ].join("\n"),
      isFirstOfReply: true,
    },
  });
  const colorOf = async (text: string) =>
    (await ui.find({ type: "Text", text }))?.props.color;
  const palette = PALETTES.dark;

  expect(await colorOf("--- a/app.ts")).toBe(palette.grey);
  expect(await colorOf("+++ b/app.ts")).toBe(palette.grey);
  expect(await colorOf("@@ -1,3 +1,3 @@")).toBe(palette.blue);
  expect(await colorOf("   useEffect(() => {")).toBe(palette.ink);
  expect(await colorOf("-    if (!enabled) {")).toBe(palette.red);
  expect(await colorOf("+    if (enabled) {")).toBe(palette.green);
  expect(await colorOf("--- removed lua comment")).toBe(palette.red);
  await ui.unmount();
});

test("draws summary blocks in the reply layout, in grey", async ($) => {
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "AssistantMessage",
    requestId: "summary-block",
    props: {
      text: "Found it: the flag clears early.",
      isFirstOfReply: false,
      isSummary: true,
    },
  });
  const root = (await ui.drawn()) as DrawnNode;

  expect(root.props?.flexDirection).toBe("row");
  expect(
    (await ui.find({ type: "Text", text: "Found it: the flag clears early." }))
      ?.props.color,
  ).toBe(PALETTES.dark.grey);
  await ui.unmount();
});

test("asks Claude to put runnable commands in copyable code blocks", async ($, on) => {
  on("prompt.compose", () => ({
    sections: [{ id: "intro", text: "You are Claude Code.", scope: "shared" }],
  }));
  const composed = await $.prompt.compose({
    model: "claude-opus-5-5",
    promptModel: "claude-opus-5-5",
    surfaces: ["terminal"],
    tools: [],
    outputStyle: null,
    traits: [],
  });

  expect(composed.sections.map((section) => section.id)).toEqual([
    "intro",
    "boltz:command-blocks",
  ]);
  expect(composed.sections[1]?.text).toContain("copy button");
});

test("saves reply numbers to session state when the turn ends", async ($, on) => {
  const writes: { key: string; value: unknown }[] = [];
  on("state.set", (_$, e, next) => {
    writes.push({ key: e.key, value: e.value });
    return next(e);
  });
  on("session.messages", () => ({
    value: [{ role: "user", text: "first question", toolUses: [] }],
  }));
  on("prompt.submit", (_$, e) => ({ text: e.text }));
  on("turn.complete", (_$, e) => ({ text: e.answer }));
  await $.prompt.submit({
    text: "second question",
    wait: false,
    origin: { kind: "composer" },
  });
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "AssistantMessage",
    requestId: "persisted-reply",
    props: { text: "The answer to the second question", isFirstOfReply: true },
  });
  await $.turn.complete({
    turnId: "t2",
    reason: "answer",
    answer: "done",
    durationMs: 900,
    isAborted: false,
  });

  const saved = writes.filter((write) => write.key === "replyNumbers").at(-1)
    ?.value as Record<string, number>;
  expect(saved["persisted-reply"]).toBe(2);
  await ui.unmount();
});
