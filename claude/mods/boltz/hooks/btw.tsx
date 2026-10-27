import { atom, read, update } from "claude-code";
import type {
  EngineInterface,
  ModelForkResult,
  On,
  SessionMessage,
} from "claude-code";

import type { BtwThread, BtwQuestion } from "../types";
import { renderMarkdown } from "./markdown";
import { PALETTES } from "./palette";
import { findTurn, isPrompt, nearest, normalized, textMatches, turnForOrdinal } from "./turns";

const COMMAND = "aside";
const PANE_PREFIX = "btw-";
const INPUT_KEY = "ask";
const MAX_PROMPT_CHARS = 4_000;
const MAX_REPLY_CHARS = 24_000;

const theme = atom({ plugin: "boltz", key: "theme" } as const, "dark");
const threads = atom({ plugin: "boltz", key: "btwThreads" } as const, {});

type Exchange = { turn: number; prompt: string; reply: string };

export function parseBtwArgs(args: string): {
  turn: number | null;
  question: string;
} {
  const match = args.trim().match(/^#?(\d+)(?:\s+([\s\S]*))?$/);
  if (match === null) return { turn: null, question: args.trim() };
  return { turn: Number(match[1]), question: (match[2] ?? "").trim() };
}

export function turnLabel(turn: number): string {
  return String(turn).padStart(2, "0");
}

function paneId(turn: number): string {
  return `${PANE_PREFIX}${turn}`;
}

function clipped(text: string, max: number): string {
  return text.length <= max ? text : `${text.slice(0, max)}\n…`;
}




function replyAfter(
  messages: SessionMessage[],
  from: number,
  until: number,
): string {
  return messages
    .slice(from + 1, until)
    .filter(
      (message) => message.role === "assistant" && message.text.trim() !== "",
    )
    .map((message) => message.text.trim())
    .join("\n\n");
}


function ordinalForTurn(
  messages: SessionMessage[],
  promptIndexes: number[],
  turn: number,
): number {
  const known = findTurn(turn);
  const matching =
    known === undefined
      ? []
      : promptIndexes
          .map((index, ordinal) => ({ index, ordinal }))
          .filter(({ index }) => textMatches(messages[index]!.text, known.text))
          .map(({ ordinal }) => ordinal);
  return nearest(matching, turn - 1) ?? turn - 1;
}

export function findExchange(
  messages: SessionMessage[],
  turn: number | null,
): Exchange | null {
  const promptIndexes = messages.flatMap((message, index) =>
    isPrompt(message) ? [index] : [],
  );
  const exchangeAt = (ordinal: number) => {
    const index = promptIndexes[ordinal];
    if (index === undefined) return null;
    const until = promptIndexes[ordinal + 1] ?? messages.length;
    return {
      index,
      prompt: messages[index]!.text,
      reply: replyAfter(messages, index, until),
    };
  };

  if (turn === null) {
    for (let ordinal = promptIndexes.length - 1; ordinal >= 0; ordinal--) {
      const found = exchangeAt(ordinal);
      if (found === null || found.reply === "") continue;
      return {
        turn: turnForOrdinal(ordinal, found.prompt),
        prompt: clipped(found.prompt, MAX_PROMPT_CHARS),
        reply: clipped(found.reply, MAX_REPLY_CHARS),
      };
    }
    return null;
  }

  const found = exchangeAt(ordinalForTurn(messages, promptIndexes, turn));
  if (found === null) return null;
  return {
    turn,
    prompt: clipped(found.prompt, MAX_PROMPT_CHARS),
    reply: clipped(found.reply, MAX_REPLY_CHARS),
  };
}

export function forkPrompt(thread: BtwThread, question: string): string {
  const label = turnLabel(thread.turn);
  const history = thread.questions
    .filter((asked) => asked.answer !== null)
    .map(
      (asked) =>
        `<question>\n${asked.question}\n</question>\n<answer>\n${asked.answer}\n</answer>`,
    );
  return [
    `This is a side conversation about one earlier exchange in this session, turn ${label}, quoted below. ` +
      "It is separate from the main task: do not continue, resume or comment on the main work, and do not use tools. " +
      `Answer the question directly, focused on turn ${label}; draw on the rest of the conversation only where it helps.`,
    `<exchange turn="${label}">\n<prompt>\n${thread.prompt}\n</prompt>\n<reply>\n${thread.reply || "(no reply text yet)"}\n</reply>\n</exchange>`,
    ...(history.length > 0
      ? [`<side_conversation>\n${history.join("\n")}\n</side_conversation>`]
      : []),
    `Question about turn ${label}:\n${question}`,
  ].join("\n\n");
}

function failureText(reply: ModelForkResult): string {
  if (reply.isAnswered) return "";
  switch (reply.reason) {
    case "nothing-to-fork":
      return "Nothing to ask over yet: the conversation has no reply.";
    case "api-error":
      return `The API answered with an error (${reply.error}${reply.status === null ? ", no response" : `, ${reply.status}`}).`;
    case "empty-reply":
      return "The model replied without any text.";
    case "aborted":
      return "Cut off before an answer arrived.";
  }
}

function isPending(thread: BtwThread): boolean {
  const last = thread.questions.at(-1);
  return last !== undefined && last.answer === null && last.error === null;
}

function withQuestion(
  all: Record<string, BtwThread>,
  id: string,
  index: number,
  asked: BtwQuestion,
): Record<string, BtwThread> {
  const thread = all[id];
  if (thread === undefined) return all;
  const questions = [...thread.questions];
  questions[index] = asked;
  return { ...all, [id]: { ...thread, questions } };
}

async function ask(
  $: EngineInterface,
  id: string,
  question: string,
): Promise<void> {
  let prompt: string | null = null;
  let index = -1;
  await update($, threads, (all) => {
    const thread = all[id];
    prompt = null;
    if (thread === undefined || isPending(thread)) return all;
    prompt = forkPrompt(thread, question);
    index = thread.questions.length;
    return withQuestion(all, id, index, { question, answer: null, error: null });
  });
  if (prompt === null) return;

  const reply = await $.model
    .fork({ prompt })
    .catch((error: unknown): ModelForkResult | string =>
      error instanceof Error ? error.message : String(error),
    );
  const asked: BtwQuestion =
    typeof reply === "string"
      ? { question, answer: null, error: reply }
      : reply.isAnswered
        ? { question, answer: reply.text, error: null }
        : { question, answer: null, error: failureText(reply) };
  await update($, threads, (all) => withQuestion(all, id, index, asked));
  await $.ui.scroll({ in: id, to: "end" }).catch(() => {});
}

function askLater($: EngineInterface, id: string, question: string): void {
  $.clock.after(0, () => {
    ask($, id, question).catch(() => {});
  });
}

function usageText(): string {
  return [
    `/${COMMAND} <question>       ask about the latest reply on the side`,
    `/${COMMAND} <n> <question>   ask about turn n (the ▶ number) on the side`,
    `/${COMMAND} <n>              open turn n's side conversation`,
  ].join("\n");
}

export function registerBtw(on: On): void {
  on("session.start", { isInteractive: true }, async ($, e, next) => {
    await $.command.register({
      name: COMMAND,
      description: "Ask a side question about one reply, in its own pane",
      argumentHint: "[n] <question>",
      immediate: true,
    });

    return next(e);
  });

  on("command.run", { command: COMMAND }, async ($, e) => {
    const { turn, question } = parseBtwArgs(e.args);
    if (turn === null && question === "") return { text: usageText() };

    const exchange = findExchange(await $.session.messages(), turn);
    if (exchange === null) {
      return {
        text:
          turn === null
            ? "No reply to ask about yet."
            : `No turn ${turnLabel(turn)} in this conversation.`,
      };
    }

    const id = paneId(exchange.turn);
    const label = turnLabel(exchange.turn);
    await update($, threads, (all) => ({
      ...all,
      [id]: {
        turn: exchange.turn,
        prompt: exchange.prompt,
        reply: exchange.reply,
        questions: all[id]?.questions ?? [],
      },
    }));
    if (question !== "") askLater($, id, question);
    const opened = await $.ui.open({
      id,
      title: `btw · ${label}`,
      focus: true,
      closeOnEscape: true,
    });

    return {
      text: opened.isPlaced
        ? `Side conversation on turn ${label} opened.`
        : `Side conversation on turn ${label} is waiting for room: ${opened.reason}`,
    };
  });

  on("ui.render", { component: "Pane" }, async ($, e, next) => {
    if (!e.requestId.startsWith(PANE_PREFIX)) return next(e);

    const palette = PALETTES[await read($, theme)];
    const thread = (await read($, threads))[e.requestId];
    const els = $.ui.resolve(e);
    const { Box, Text } = els;
    if (thread === undefined) {
      return (
        <Text color={palette.grey}>
          This side conversation is gone. Close it and run /{COMMAND} again.
        </Text>
      );
    }

    const id = e.requestId;
    const label = turnLabel(thread.turn);
    const columns = Math.max(20, e.props.bodyColumns - 2);
    const pending = isPending(thread);
    const answerOf = (text: string) =>
      e.surface === "terminal" ? (
        renderMarkdown($.ui.resolve(e), palette, columns, text)
      ) : (
        <Text color={palette.ink}>{text}</Text>
      );

    return (
      <Box flexDirection="column" rowGap={1}>
        <Box flexDirection="row">
          <Box width={5} flexShrink={0}>
            <Text bold color={palette.orange}>
              ▶ {label}
            </Text>
          </Box>
          <Box flexShrink={1}>
            <Text color={palette.grey} wrap="truncate-end">
              {normalized(thread.prompt)}
            </Text>
          </Box>
        </Box>
        {thread.questions.map((asked) => (
          <Box flexDirection="column">
            <Text>
              <Text bold color={palette.orange}>
                ?{" "}
              </Text>
              <Text bold color={palette.ink}>
                {asked.question}
              </Text>
            </Text>
            <Box
              borderStyle="quote"
              borderColor={palette.dim}
              paddingLeft={1}
              flexDirection="column"
            >
              {asked.answer !== null ? (
                answerOf(asked.answer)
              ) : asked.error !== null ? (
                <Text color={palette.red}>✗ {asked.error}</Text>
              ) : (
                <Text color={palette.grey}>◌ asking about {label}…</Text>
              )}
            </Box>
          </Box>
        ))}
        {"Input" in els && (
          <els.Input
            key={INPUT_KEY}
            value=""
            autoFocus
            placeholder={
              pending
                ? "waiting for the answer…"
                : `ask a follow-up about ${label}`
            }
            submitLabel="ask"
            onSubmit={(value) => {
              const question = value.trim();
              if (question !== "") askLater($, id, question);
            }}
          />
        )}
      </Box>
    );
  });
}
