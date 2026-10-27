import { expect, mock, test } from "claude-code/testing";
import type { On } from "claude-code";

import { parseBtwArgs } from "./btw";

const SUBMIT = {
  origin: { kind: "composer" },
  presentation: { isFullscreen: false, columns: 120 },
} as const;

const USAGE = {
  input_tokens: 1,
  output_tokens: 1,
  cache_creation_input_tokens: 0,
  cache_read_input_tokens: 0,
};

const MESSAGES = [
  { role: "user", text: "why is agent-3 skipped?", toolUses: [] },
  { role: "assistant", text: "The planner filters it out.", toolUses: [] },
  { role: "user", text: "fix it", toolUses: [] },
  { role: "assistant", text: "Patched `viableNodes`.", toolUses: [] },
] as const;

const PANE_PROPS = {
  title: "btw · 01",
  isFocused: true,
  bodyColumns: 80,
  placement: "inline",
  scroll: { offset: 0, bodyRows: 20 },
  view: {},
} as const;

function mockSession(on: On, answers: string[]): string[] {
  const prompts: string[] = [];
  on("session.messages", () => ({
    value: MESSAGES.map((m) => ({ ...m, toolUses: [] })),
  }));
  on("model.fork", (_$, e) => {
    prompts.push(e.prompt);
    return {
      value: {
        isAnswered: true,
        text: answers[prompts.length - 1] ?? "",
        usage: USAGE,
      },
    };
  });
  on("ui.open", () => ({ value: { isPlaced: true } }));
  on("ui.scroll", () => ({}));
  return prompts;
}

test("parses the turn number and the question", () => {
  expect(parseBtwArgs("5 why that order?")).toEqual({
    turn: 5,
    question: "why that order?",
  });
  expect(parseBtwArgs("#05 and then?")).toEqual({
    turn: 5,
    question: "and then?",
  });
  expect(parseBtwArgs("3")).toEqual({ turn: 3, question: "" });
  expect(parseBtwArgs("what was that?")).toEqual({
    turn: null,
    question: "what was that?",
  });
});

test("registers /aside as an immediate command", async ($, on) => {
  mock.clock(on);
  const specs: { name: string; immediate?: true }[] = [];
  on("command.register", (_$, e) => {
    specs.push(e);
    return { value: { command: e.name } };
  });
  on("settings.read", () => ({ value: {} }));
  on("session.start", (_$, e) => ({ cwd: e.cwd }));
  await $.session.start({ cwd: "/", surface: "terminal", isInteractive: true });

  expect(specs).toContainEqual(
    expect.objectContaining({ name: "aside", immediate: true }),
  );
});

test("asks about turn 1 on the side and draws the thread", async ($, on) => {
  const clock = mock.clock(on);
  const prompts = mockSession(on, ["Because it rejoined late."]);

  await $.command.run({ command: "aside", args: "1 why late?", ...SUBMIT });
  await clock.settle();

  expect(prompts).toHaveLength(1);
  expect(prompts[0]).toContain("why is agent-3 skipped?");
  expect(prompts[0]).toContain("The planner filters it out.");
  expect(prompts[0]).not.toContain("Patched");
  expect(prompts[0]).toContain("why late?");

  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "Pane",
    requestId: "btw-1",
    props: PANE_PROPS,
  });
  expect(await ui.find({ type: "Text", text: "▶ 01" })).toBeDefined();
  expect(await ui.find({ type: "Text", text: "why late?" })).toBeDefined();
  expect(await ui.find({ type: "Text", text: /rejoined late/ })).toBeDefined();
  await ui.unmount();
});

test("submits a follow-up with the earlier questions in the prompt", async ($, on) => {
  const clock = mock.clock(on);
  const prompts = mockSession(on, ["First answer.", "Second answer."]);

  await $.command.run({ command: "aside", args: "2 what changed?", ...SUBMIT });
  await clock.settle();
  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "Pane",
    requestId: "btw-2",
    props: { ...PANE_PROPS, title: "btw · 02" },
  });
  await ui.input({ key: "ask", text: "is it tested?" });
  await clock.settle();

  expect(prompts).toHaveLength(2);
  expect(prompts[1]).toContain("Patched `viableNodes`.");
  expect(prompts[1]).toContain("what changed?");
  expect(prompts[1]).toContain("First answer.");
  expect(prompts[1]).toContain("is it tested?");
  expect(await ui.find({ type: "Text", text: "is it tested?" })).toBeDefined();
  expect(await ui.find({ type: "Text", text: /Second answer/ })).toBeDefined();
  await ui.unmount();
});

test("defaults to the latest reply and shows a failed fork", async ($, on) => {
  const clock = mock.clock(on);
  on("session.messages", () => ({
    value: MESSAGES.map((m) => ({ ...m, toolUses: [] })),
  }));
  on("model.fork", () => ({
    value: { isAnswered: false, reason: "empty-reply", usage: USAGE },
  }));
  on("ui.open", () => ({ value: { isPlaced: true } }));
  on("ui.scroll", () => ({}));

  const ran = await $.command.run({
    command: "aside",
    args: "huh?",
    ...SUBMIT,
  });
  await clock.settle();
  expect(ran.text).toContain("turn 02");

  const ui = await $.ui.mount({
    plugin: "boltz",
    surface: "terminal",
    component: "Pane",
    requestId: "btw-2",
    props: PANE_PROPS,
  });
  expect(
    await ui.find({ type: "Text", text: /without any text/ }),
  ).toBeDefined();
  await ui.unmount();
});
