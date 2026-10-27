import type { On } from "claude-code";
import { expect, mock, test } from "claude-code/testing";

import { tocRows } from "./toc";

const PANE = {
  plugin: "boltz",
  surface: "terminal",
  component: "Pane",
  requestId: "toc",
  props: {
    title: "Contents",
    isFocused: true,
    bodyColumns: 40,
    placement: "dock",
    scroll: { offset: 0, bodyRows: 20 },
    view: {},
  },
} as const;

const SUBMIT = {
  origin: { kind: "composer" },
  presentation: { isFullscreen: true, columns: 160 },
} as const;

function promptRow(requestId: string, text: string) {
  return {
    plugin: "boltz",
    surface: "terminal",
    component: "UserMessage",
    requestId,
    props: { text, origin: { kind: "composer" }, isExpanded: false },
  } as const;
}

function drawStockPrompts(on: On) {
  on("ui.render", { component: "UserMessage" }, ($, e) => {
    const { Text } = $.ui.resolve(e);
    return <Text>{e.props.text}</Text>;
  });
}

test("lists each drawn prompt as a turn row", async ($, on) => {
  mock.clock(on);
  drawStockPrompts(on);
  on("session.messages", () => ({ value: [] }));
  const first = await $.ui.mount(promptRow("toc-a", "why is agent-3 skipped?"));
  const second = await $.ui.mount(
    promptRow("toc-b", "fix the reconnect path\nand add a test"),
  );
  const pane = await $.ui.mount(PANE);

  const rows = await pane.findAll({ type: "Button" });
  expect(rows.length).toBeGreaterThanOrEqual(2);
  expect(
    await pane.find({ type: "Button", text: /why is agent-3 skipped\?/ }),
  ).toBeDefined();
  expect(
    await pane.find({ type: "Button", text: /fix the reconnect path$/ }),
  ).toBeDefined();

  await pane.unmount();
  await first.unmount();
  await second.unmount();
});

test("pressing a row asks ui.scroll for that prompt", async ($, on) => {
  mock.clock(on);
  drawStockPrompts(on);
  on("session.messages", () => ({ value: [] }));
  const prompt = await $.ui.mount(promptRow("toc-c", "jump here"));
  const pane = await $.ui.mount(PANE);

  await expect(pane.press({ key: "toc:toc-c" })).rejects.toThrow(
    /no implementation for ui\.scroll/,
  );

  await pane.unmount();
  await prompt.unmount();
});

test("lists session prompts not drawn yet without a jump", () => {
  const drawn = { number: 1, requestId: "r1", text: "second" };

  expect(tocRows([drawn], ["first", "second"])).toEqual([
    { number: null, requestId: null, text: "first" },
    drawn,
  ]);
});

test("/toc opens the pane when closed and closes it when open", async ($, on) => {
  let isUp = false;
  on("ui.panes", () => ({
    value: isUp
      ? [
          {
            id: "toc",
            title: "Contents",
            isShown: true,
            isFocused: true,
            isPlaced: true,
          },
        ]
      : [],
  }));
  on("ui.open", () => {
    isUp = true;
    return { value: { isPlaced: true } };
  });
  on("ui.close", () => {
    isUp = false;
    return { value: undefined };
  });

  await $.command.run({ command: "toc", args: "", ...SUBMIT });
  expect(isUp).toBe(true);
  await $.command.run({ command: "toc", args: "", ...SUBMIT });
  expect(isUp).toBe(false);
});
