import type { SessionMessage } from "claude-code";

export type Turn = { number: number; requestId: string; text: string };

const turnsByRequest = new Map<string, Turn>();

export function recordTurn(requestId: string, text: string): Turn {
  const known = turnsByRequest.get(requestId);
  if (known !== undefined) return known;
  const turn = { number: turnsByRequest.size + 1, requestId, text };
  turnsByRequest.set(requestId, turn);
  return turn;
}

export function listTurns(): Turn[] {
  return [...turnsByRequest.values()];
}

export function findTurn(number: number): Turn | undefined {
  return listTurns().find((turn) => turn.number === number);
}

const NOT_PROMPTS = /^<(local-command|command-|system-reminder|task-notification)/;
const MIN_PARTIAL_MATCH = 20;

export function normalized(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

export function isPrompt(message: SessionMessage): boolean {
  return (
    message.role === "user" &&
    message.text.trim() !== "" &&
    (message.toolResults ?? []).length === 0 &&
    !NOT_PROMPTS.test(message.text.trimStart())
  );
}

export function textMatches(a: string, b: string): boolean {
  const left = normalized(a);
  const right = normalized(b);
  if (left === "" || right === "") return false;
  if (left === right) return true;
  const [shorter, longer] = left.length <= right.length ? [left, right] : [right, left];
  return shorter.length >= MIN_PARTIAL_MATCH && longer.includes(shorter);
}

export function nearest(candidates: number[], target: number): number | undefined {
  return [...candidates].sort((a, b) => Math.abs(a - target) - Math.abs(b - target))[0];
}

export function turnForOrdinal(ordinal: number, text: string): number {
  const matching = listTurns()
    .filter((turn) => textMatches(turn.text, text))
    .map((turn) => turn.number);
  return nearest(matching, ordinal + 1) ?? ordinal + 1;
}

export type ReplyTurn = { turn: number; isFirst: boolean };

export function replyTurn(messages: SessionMessage[], replyText: string): ReplyTurn | null {
  const opening = normalized(replyText).slice(0, MIN_PARTIAL_MATCH * 2);
  let ordinal = -1;
  let promptIndex = -1;
  let firstReplyIndex = -1;
  let found: ReplyTurn | null = null;

  messages.forEach((message, index) => {
    if (isPrompt(message)) {
      ordinal += 1;
      promptIndex = index;
      firstReplyIndex = -1;
      return;
    }
    if (message.role !== "assistant" || message.text.trim() === "" || ordinal < 0) return;
    if (firstReplyIndex === -1) firstReplyIndex = index;
    if (!textMatches(message.text, replyText)) return;
    found = {
      turn: turnForOrdinal(ordinal, messages[promptIndex]!.text),
      isFirst: index === firstReplyIndex && normalized(message.text).startsWith(opening),
    };
  });

  return found;
}
