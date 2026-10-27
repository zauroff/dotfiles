import { atom, read, update } from "claude-code";
import type { EngineInterface, Register, SessionMessage } from "claude-code";

import { listTurns, recordTurn } from "./turns";
import type { Turn } from "./turns";

type Registrar = Parameters<Register>[0];

type TocRow = { number: number | null; requestId: string | null; text: string };

const PANE = "toc";
const TITLE = "Contents";
const NUMBER_WIDTH = 6;
const HOTKEY_WIDTH = 3;

const isOpen = atom({ plugin: "boltz", key: "tocIsOpen" } as const, false);
const version = atom({ plugin: "boltz", key: "tocVersion" } as const, 0);

const shownRequests = new Set<string>();

function bumpVersion($: EngineInterface): Promise<unknown> {
  return update($, version, (n) => (n + 1) % 1_000_000);
}

function firstLine(text: string): string {
  return text.trim().split("\n")[0]!.trim();
}

function truncate(text: string, width: number): string {
  if (width <= 0) return "";
  const chars = [...text];
  if (chars.length <= width) return text;
  return `${chars.slice(0, Math.max(0, width - 1)).join("")}…`;
}

function promptTexts(messages: readonly SessionMessage[]): string[] {
  return messages
    .filter(
      (m) =>
        m.role === "user" &&
        (m.toolResults ?? []).length === 0 &&
        m.text.trim() !== "" &&
        !m.text.trimStart().startsWith("<"),
    )
    .map((m) => m.text);
}

export function tocRows(
  turns: readonly Turn[],
  prompts: readonly string[],
): TocRow[] {
  const turnRows = turns.map((t) => ({ ...t }));
  if (prompts.length <= turns.length) return turnRows;

  const unmatched = [...turns];
  const rows: TocRow[] = prompts.map((text) => {
    const at = unmatched.findIndex((t) => t.text.trim() === text.trim());
    if (at < 0) return { number: null, requestId: null, text };
    const [turn] = unmatched.splice(at, 1);
    return { ...turn! };
  });
  return [...rows, ...unmatched];
}

async function togglePane($: EngineInterface): Promise<boolean> {
  const panes = await $.ui.panes();
  if (panes.some((pane) => pane.id === PANE)) {
    await $.ui.close({ id: PANE });
    await update($, isOpen, () => false);
    return false;
  }
  const opened = await $.ui.open({
    id: PANE,
    title: TITLE,
    focus: true,
    closeOnEscape: true,
  });
  await update($, isOpen, () => true);
  if (!opened.isPlaced) $.ui.toast("toc: widen the terminal to see it");
  return true;
}

async function jumpTo($: EngineInterface, requestId: string): Promise<void> {
  const scrolled = await $.ui.scroll({ to: { requestId }, block: "start" });
  if (scrolled.deny !== undefined) $.ui.toast(`toc: ${scrolled.deny}`);
}

export function registerToc(on: Registrar): void {
  on("session.start", { isInteractive: true }, async ($, e, next) => {
    await $.command.register({
      name: "toc",
      description: "Toggle a table of contents of your prompts",
      immediate: true,
    });

    return next(e);
  }).catch(($, e, next) => next(e));

  on("command.run", { command: "toc" }, async ($) => {
    await togglePane($);

    return {};
  });

  on("ui.close", { id: PANE }, async ($, e, next) => {
    await update($, isOpen, () => false);

    return next(e);
  });

  on("prompt.submit", { origin: { kind: "composer" } }, async ($, e, next) => {
    const submitted = await next(e);
    await bumpVersion($);

    return submitted;
  }).catch(($, e, next) => next(e));

  on(
    "ui.render",
    { component: "UserMessage", props: { origin: { kind: "composer" } } },
    async ($, e, next) => {
      const known = listTurns().length;
      recordTurn(e.requestId, e.props.text);
      const wasShown = shownRequests.has(e.requestId);
      const isShown = e.props.onScreen != null;
      if (isShown) shownRequests.add(e.requestId);
      else shownRequests.delete(e.requestId);
      if (listTurns().length !== known || wasShown !== isShown)
        $.clock.after(0, () => {
          bumpVersion($).catch(() => {});
        });

      return next(e);
    },
  );

  on("ui.render", { component: "Pane", requestId: PANE }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e);
    await read($, version);
    const rows = tocRows(
      listTurns(),
      promptTexts(await $.session.messages().catch(() => [])),
    );
    const textWidth = e.props.bodyColumns - HOTKEY_WIDTH - NUMBER_WIDTH;

    return (
      <Box flexDirection="column">
        {rows.length === 0 && <Text dimColor>No prompts yet.</Text>}
        {rows.map((row) => {
          const label = truncate(firstLine(row.text), textWidth);
          const number =
            row.number === null
              ? "▶ ··"
              : `▶ ${String(row.number).padStart(2, "0")}`;
          if (row.requestId === null)
            return (
              <Text dimColor>
                {" ".repeat(HOTKEY_WIDTH)}
                {number.padEnd(NUMBER_WIDTH)}
                {label}
              </Text>
            );

          const requestId = row.requestId;
          const isShown = shownRequests.has(requestId);
          const hotkey =
            row.number !== null && row.number >= 1 && row.number <= 9
              ? String(row.number)
              : undefined;
          return (
            <Button
              key={`toc:${requestId}`}
              plain
              {...(hotkey === undefined ? {} : { hotkey })}
              dimColor={shownRequests.size > 0 && !isShown}
              onPress={() => jumpTo($, requestId)}
            >
              {hotkey === undefined ? " ".repeat(HOTKEY_WIDTH) : ""}
              <Text bold={isShown}>{number.padEnd(NUMBER_WIDTH)}</Text>
              {label}
            </Button>
          );
        })}
        {rows.some((row) => row.requestId === null) && (
          <Text dimColor>
            ▶ ·· not drawn since load: scroll past it once to jump.
          </Text>
        )}
      </Box>
    );
  });
}
