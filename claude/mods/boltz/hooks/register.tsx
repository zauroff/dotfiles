import { atom, read, update } from "claude-code";
import type { EngineInterface, Register, SessionMessage, Settings, UiPressArgument } from "claude-code";

import type { Theme, ThemeChoice } from "../types";
import { cleanCopy } from "./copy";
import { renderMarkdown } from "./markdown";
import { isPrompt, replyTurn, turnForOrdinal } from "./turns";
import { registerToc } from "./toc";
import { registerBtw } from "./btw";
import {
  PALETTES,
  THEMES,
  type Palette,
  THEME_CHOICES,
  themeFromCustom,
  themeFromName,
  categoryColor,
  categoryOf,
  toolLabel,
} from "./palette";

const GUTTER_WIDTH = 5;
const MAX_DURATIONS = 300;
const THEME_POLL_MS = 2000;

const VERBS = [
  ["SEQUENCING", "SEQUENCED"],
  ["SAMPLING", "SAMPLED"],
  ["BOUNCING", "BOUNCED"],
  ["MIXING", "MIXED"],
  ["PATCHING", "PATCHED"],
  ["TRACKING", "TRACKED"],
  ["TUNING", "TUNED"],
  ["LOOPING", "LOOPED"],
] as const;

const METER_FRAMES = ["▁▃▅▇", "▃▅▇▅", "▅▇▅▃", "▇▅▃▁", "▅▃▁▃", "▃▁▃▅"];
const RUNNING_FRAMES = ["·  ", "·· ", "···", " ··", "  ·", "   "];

const isOn = atom({ plugin: "boltz", key: "isOn" } as const, true);
const theme = atom({ plugin: "boltz", key: "theme" } as const, "dark");
const themeChoice = atom(
  { plugin: "boltz", key: "themeChoice" } as const,
  "auto",
);
const phase = atom({ plugin: "boltz", key: "phase" } as const, 0);
const isWorking = atom({ plugin: "boltz", key: "isWorking" } as const, false);
const liveTurn = atom({ plugin: "boltz", key: "liveTurn" } as const, null);
const replyNumbers = atom({ plugin: "boltz", key: "replyNumbers" } as const, {});
const MAX_SAVED_REPLY_NUMBERS = 500;
const durations = atom({ plugin: "boltz", key: "durations" } as const, {});

function hashOf(text: string): number {
  let hash = 0;
  for (const ch of text) hash = (hash * 31 + ch.charCodeAt(0)) >>> 0;
  return hash;
}

function verbFor(word: string, tense: 0 | 1): string {
  return VERBS[hashOf(word) % VERBS.length]![tense];
}

function formatDuration(ms: number): string {
  if (ms < 60_000) return `${(ms / 1000).toFixed(ms < 10_000 ? 2 : 1)}s`;
  return `${Math.floor(ms / 60_000)}m${String(Math.round((ms % 60_000) / 1000)).padStart(2, "0")}s`;
}

function describeInput(input: unknown): string {
  if (typeof input !== "object" || input === null) return "";
  const fields = input as Record<string, unknown>;
  for (const key of [
    "command",
    "file_path",
    "notebook_path",
    "pattern",
    "url",
    "query",
    "description",
    "skill",
    "prompt",
  ]) {
    const value = fields[key];
    if (typeof value !== "string" || value === "") continue;
    if (key.endsWith("_path")) return value.split("/").slice(-3).join("/");
    return value.split("\n")[0]!;
  }
  return "";
}

function withDuration(
  recorded: Record<string, number>,
  id: string,
  ms: number,
): Record<string, number> {
  const ids = Object.keys(recorded);
  const kept =
    ids.length >= MAX_DURATIONS
      ? ids.slice(ids.length - MAX_DURATIONS + 1)
      : ids;
  return Object.fromEntries([
    ...kept.map((key) => [key, recorded[key]!] as const),
    [id, ms],
  ]);
}

async function advancePhase($: EngineInterface): Promise<void> {
  if (!(await read($, isWorking)) || !(await read($, isOn))) return;
  await update($, phase, (n) => (n + 1) % 1_000_000);
}

async function readText($: EngineInterface, path: string): Promise<string> {
  return $.fs.read(path).then(
    (text) => (typeof text === "string" ? text : ""),
    () => "",
  );
}

async function detectTheme(
  $: EngineInterface,
  setting?: unknown,
): Promise<Theme> {
  const name =
    setting ?? (await $.settings.read().catch((): Settings => ({}))).theme;
  const home = await $.env.get("HOME").catch(() => undefined);
  if (typeof name === "string" && name.startsWith("custom:")) {
    const custom = name.slice("custom:".length);
    const definition =
      home === undefined
        ? ""
        : await readText($, `${home}/.claude/themes/${custom}.json`);
    const fromCustom = themeFromCustom(custom, definition);
    if (fromCustom !== null) return fromCustom;
  }
  const fromSetting = themeFromName(name);
  if (fromSetting !== null || home === undefined) return fromSetting ?? "dark";
  const current = await readText($, `${home}/.config/.current-theme`);
  return themeFromName(current.trim()) ?? "dark";
}

async function syncTheme(
  $: EngineInterface,
  setting?: unknown,
): Promise<Theme> {
  const choice = await read($, themeChoice);
  const effective = choice === "auto" ? await detectTheme($, setting) : choice;
  if ((await read($, theme)) !== effective)
    await update($, theme, () => effective);
  return effective;
}

async function paletteOf($: EngineInterface): Promise<Palette> {
  return PALETTES[await read($, theme)];
}

function usageText(): string {
  return [
    "/boltz              toggle boltz",
    "/boltz on | off     force it on or off",
    `/boltz <theme>      one of ${THEME_CHOICES.join(", ")}; auto follows Claude Code`,
    "/boltz next         switch between dark and light",
  ].join("\n");
}

const exactCopies = new Set<string>();

function copyCode($: EngineInterface, source: string, press: UiPressArgument): void {
  exactCopies.add(source);
  $.ui
    .copy({ text: source, surface: press.surface })
    .then((copied) => $.ui.toast(copied.isCopied ? "Copied code block." : `Couldn't copy: ${copied.reason}.`))
    .catch(() => exactCopies.delete(source));
}

const COMMAND_BLOCKS_SECTION = {
  id: "boltz:command-blocks",
  scope: "session",
  text: [
    "When you give the user a shell command to run, put it in its own fenced code block tagged with its shell (```bash),",
    "one command or one runnable sequence per block, with no prompt characters such as $ and no commentary inside the block.",
    "The interface draws a copy button on every code block, so a command the user may want to run must never appear only",
    "as inline code or in prose.",
  ].join(" "),
} as const;

const replyLabels = new Map<string, number | null>();
const labeledTurns = new Set<number>();

function rememberLabel(requestId: string, label: number | null): number | null {
  replyLabels.set(requestId, label);
  if (label !== null) labeledTurns.add(label);
  return label;
}

async function saveReplyNumbers($: EngineInterface): Promise<void> {
  if (replyLabels.size === 0) return;
  await update($, replyNumbers, (saved) =>
    Object.fromEntries(Object.entries({ ...saved, ...Object.fromEntries(replyLabels) }).slice(-MAX_SAVED_REPLY_NUMBERS)),
  );
}

const MESSAGES_TTL_MS = 2000;
let messagesSnapshot: { at: number; messages: Promise<SessionMessage[] | null> } | null = null;

function recentMessages($: EngineInterface): Promise<SessionMessage[] | null> {
  const now = Date.now();
  if (messagesSnapshot === null || now - messagesSnapshot.at > MESSAGES_TTL_MS) {
    messagesSnapshot = { at: now, messages: $.session.messages().catch(() => null) };
  }
  return messagesSnapshot.messages;
}

async function replyLabelOf(
  $: EngineInterface,
  requestId: string,
  text: string,
  isFirstOfReply: boolean,
): Promise<number | null> {
  const known = replyLabels.get(requestId);
  if (known !== undefined) return known;
  const saved = (await read($, replyNumbers))[requestId];
  if (saved !== undefined) return rememberLabel(requestId, saved);

  const live = await read($, liveTurn);
  const liveLabel = () =>
    rememberLabel(requestId, live !== null && isFirstOfReply && !labeledTurns.has(live) ? live : null);
  if (await read($, isWorking)) return liveLabel();

  const messages = await recentMessages($);
  const found = messages === null ? null : replyTurn(messages, text);
  if (found === null) return isFirstOfReply && live !== null && !labeledTurns.has(live) ? liveLabel() : null;
  return rememberLabel(requestId, found.isFirst ? found.turn : null);
}

export const register: Register = (on) => {
  registerToc(on);
  registerBtw(on);
  on("session.start", async ($, e, next) => {
    await $.command.register({
      name: "boltz",
      description: "Toggle boltz or switch it between dark and light",
      argumentHint: "[on|off|next|auto|dark|light]",
      immediate: true,
    });
    $.clock.every(140, () => {
      advancePhase($).catch(() => {});
    });
    await syncTheme($).catch(() => {});
    $.clock.every(THEME_POLL_MS, () => {
      syncTheme($).catch(() => {});
    });
    if (await read($, isOn))
      $.ui.toast("boltz on. /boltz off reverts to stock.");

    return next(e);
  });

  on("command.run", { command: "boltz" }, async ($, e) => {
    const verb = e.args.trim();

    if (verb === "" || verb === "on" || verb === "off") {
      const nowOn = verb === "" ? !(await read($, isOn)) : verb === "on";
      await update($, isOn, () => nowOn);
      return {
        text: nowOn ? "boltz on." : "boltz off. Claude Code is back to stock.",
      };
    }

    if (verb === "next") {
      const current = await read($, theme);
      const nextTheme = THEMES[(THEMES.indexOf(current) + 1) % THEMES.length]!;
      await update($, themeChoice, () => nextTheme);
      await syncTheme($);
      return { text: `boltz ${nextTheme}.` };
    }

    if ((THEME_CHOICES as string[]).includes(verb)) {
      await update($, themeChoice, () => verb as ThemeChoice);
      const effective = await syncTheme($);
      return {
        text: verb === "auto" ? `boltz auto (${effective}).` : `boltz ${verb}.`,
      };
    }

    return { text: usageText() };
  });

  on("config.set", { key: "theme" }, async ($, e, next) => {
    const written = await next(e);
    if (written.deny === undefined)
      await syncTheme($, written.value).catch(() => {});

    return written;
  }).catch(($, e, next) => next(e));

  on("prompt.submit", async ($, e, next) => {
    await update($, isWorking, () => true);
    await saveReplyNumbers($);
    if (e.origin.kind === "composer") {
      const prompts = (await $.session.messages()).filter(isPrompt);
      await update($, liveTurn, () => turnForOrdinal(prompts.length, e.text));
    }

    return next(e);
  }).catch(($, e, next) => next(e));

  on("prompt.compose", async ($, e, next) => {
    const composed = await next(e);
    if (!e.surfaces.includes("terminal") || !(await read($, isOn))) return composed;

    return { sections: [...composed.sections, COMMAND_BLOCKS_SECTION] };
  });

  on("ui.copy", async ($, e, next) => {
    if (exactCopies.delete(e.text) || !(await read($, isOn))) return next(e);

    return next({ ...e, text: cleanCopy(e.text) });
  }).catch(($, e, next) => next(e));

  on("tool.call", async ($, e, next) => {
    const startedAt = await $.clock.now();
    const ran = await next(e);
    const elapsed = (await $.clock.now()) - startedAt;
    await update($, durations, (recorded) =>
      withDuration(recorded, e.tool_use_id, elapsed),
    );

    return ran;
  }).catch(($, e, next) => next(e));

  on("turn.complete", async ($, e, next) => {
    const completed = await next(e);
    if (e.agentId === undefined) {
      await update($, isWorking, () => false);
      await saveReplyNumbers($);
    }

    return completed;
  });

  on("ui.render", { component: "AssistantMessage" }, async ($, e, next) => {
    if (
      e.surface !== "terminal" ||
      e.props.text.length > 40_000 ||
      !(await read($, isOn))
    ) {
      return next(e);
    }

    const basePalette = await paletteOf($);
    const palette = e.props.isSummary ? { ...basePalette, ink: basePalette.grey } : basePalette;
    const els = $.ui.resolve(e);
    const { Box, Text } = els;
    const columns = Math.max(
      20,
      (e.viewport?.columns ?? 80) - GUTTER_WIDTH - 1,
    );
    const label = await replyLabelOf($, e.requestId, e.props.text, e.props.isFirstOfReply);

    return (
      <Box flexDirection="row" marginTop={1}>
        <Box width={GUTTER_WIDTH} flexShrink={0}>
          {label !== null && (
            <Text bold color={palette.orange}>
              {String(label).padStart(2, "0")}
            </Text>
          )}
        </Box>
        <Box flexDirection="column" flexGrow={1} flexShrink={1}>
          {renderMarkdown(els, palette, columns, e.props.text, (source, press) => copyCode($, source, press))}
        </Box>
      </Box>
    );
  });

  on("ui.render", { component: "ToolUse" }, async ($, e, next) => {
    if (e.surface !== "terminal" || !(await read($, isOn))) return next(e);

    const palette = await paletteOf($);
    const { Box, Text } = $.ui.resolve(e);
    const { tool, tool_use_id, input, isRunning, isErrored, isInterrupted } =
      e.props;
    const color = categoryColor(palette, categoryOf(tool));
    const elapsed = isRunning
      ? undefined
      : (await read($, durations))[tool_use_id];
    const outcome = isInterrupted ? (
      <Text color={palette.grey}>⊘ stopped</Text>
    ) : isErrored ? (
      <Text color={palette.red}>✗ failed</Text>
    ) : isRunning ? (
      <Text color={palette.grey}>
        {RUNNING_FRAMES[(await read($, phase)) % RUNNING_FRAMES.length]}
      </Text>
    ) : (
      <Text>
        <Text color={palette.green}>✓</Text>
        <Text color={palette.grey}>
          {elapsed === undefined
            ? ""
            : ` ${formatDuration(elapsed).padStart(6)}`}
        </Text>
      </Text>
    );

    return (
      <Box marginLeft={GUTTER_WIDTH} flexDirection="row" columnGap={1}>
        <Text color={color}>■</Text>
        <Box width={7} flexShrink={0}>
          <Text bold color={color} wrap="truncate-end">
            {toolLabel(tool)}
          </Text>
        </Box>
        <Box flexGrow={1} flexShrink={1}>
          <Text color={palette.grey} wrap="truncate-end">
            {describeInput(input)}
          </Text>
        </Box>
        <Box flexShrink={0}>{outcome}</Box>
      </Box>
    );
  });

  on("ui.render", { component: "ToolGroup" }, async ($, e, next) => {
    if (
      e.surface !== "terminal" ||
      e.props.isExpanded ||
      !(await read($, isOn))
    )
      return next(e);

    const palette = await paletteOf($);
    const { Box, Text } = $.ui.resolve(e);
    const recorded = await read($, durations);
    const counts = new Map<string, number>();
    for (const call of e.props.calls)
      counts.set(
        toolLabel(call.tool),
        (counts.get(toolLabel(call.tool)) ?? 0) + 1,
      );
    const summary = [...counts]
      .map(([label, n]) => `${label} ${n}`)
      .join(" · ");
    const total = e.props.calls.reduce(
      (sum, call) =>
        sum + (call.tool_use_id ? (recorded[call.tool_use_id] ?? 0) : 0),
      0,
    );
    const isRunning = e.props.calls.some((call) => call.isRunning);

    return (
      <Box marginLeft={GUTTER_WIDTH} flexDirection="row" columnGap={1}>
        <Text>
          {e.props.calls.map((call) => (
            <Text color={categoryColor(palette, categoryOf(call.tool))}>■</Text>
          ))}
        </Text>
        <Box flexGrow={1} flexShrink={1}>
          <Text color={palette.grey} wrap="truncate-end">
            {summary}
          </Text>
        </Box>
        {!isRunning && (
          <Text>
            <Text color={palette.green}>✓</Text>
            <Text color={palette.grey}>
              {total > 0 ? ` ${formatDuration(total).padStart(6)}` : ""}
            </Text>
          </Text>
        )}
      </Box>
    );
  });

  on("ui.render", { component: "Spinner" }, async ($, e, next) => {
    if (e.surface !== "terminal" || !(await read($, isOn))) return next(e);

    const frame = METER_FRAMES[(await read($, phase)) % METER_FRAMES.length]!;

    return next({
      ...e,
      props: {
        ...e.props,
        word: verbFor(e.props.word, 0),
        suffix: ` ${frame}`,
      },
    });
  });

  on("ui.render", { component: "TurnDuration" }, async ($, e, next) => {
    if (!(await read($, isOn))) return next(e);

    const palette = await paletteOf($);
    const { Box, Text } = $.ui.resolve(e);

    return (
      <Box marginLeft={GUTTER_WIDTH} marginTop={1} columnGap={1}>
        <Text>
          <Text color={palette.orange}>■ </Text>
          <Text bold color={palette.ink}>
            {verbFor(e.props.word, 1)}
          </Text>
          <Text color={palette.grey}>
            {"  "}
            {formatDuration(e.props.durationMs)}
          </Text>
        </Text>
      </Box>
    );
  });
};
