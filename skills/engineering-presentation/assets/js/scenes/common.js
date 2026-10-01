/**
 * Shared scene fragments.
 *
 * Scenes declare their complete visible state, which keeps the engine simple
 * but makes later scenes repetitive: the system is the same in all of them.
 * These bundles are the answer. Spread one, then add what the scene is about.
 */

import { STAGE_HOST } from "../model.js";

export const SERVERS = ["app-a", "app-b", "app-c"];
export const STAGES = ["stage-parse", "stage-auth", "stage-render"];

/** Health checks between peers. Membership, not payload. */
export const PEER_LINKS = [
  ["app-a", "app-b", "mesh"],
  ["app-b", "app-c", "mesh"],
];

/** The chain as a chain, with nothing yet to say where it runs. */
export const CHAIN_LINKS = [
  ["stage-parse", "stage-auth", "edge"],
  ["stage-auth", "stage-render", "edge"],
];

/** Each stage against the server that runs it. */
export const BOUND_LINKS = STAGES.map((s) => [s, STAGE_HOST[s], "bound"]);

/** Everything on stage once a request is in flight. */
export const RUNNING = [...STAGES, "lb", "client", ...SERVERS, "cache", "db"];

/** The live path a request travels, hop by hop. */
export const PATH_LINKS = [
  ["client", "lb", "solid"],
  ["lb", "app-a", "pipe"],
  ["app-a", "app-b", "pipe"],
  ["app-b", "app-c", "pipe"],
];

/** Reads and writes against the things that hold state. */
export const STATE_LINKS = [
  ["app-b", "cache", "solid"],
  ["app-c", "db", "solid"],
];

/** The path, with particles on it. */
export const PATH_FLOW = [
  ["client", "lb", "solid", { count: 2, speed: 0.5 }],
  ["lb", "app-a", "pipe", { count: 2, speed: 0.45 }],
  ["app-a", "app-b", "pipe", { count: 3, speed: 0.45 }],
];

/**
 * `roundTrip` is for a request and its answer: two offset streams on one link,
 * out and back. `oneWay` is for a send with nothing coming back.
 */
export const oneWay = (from, to, kind = "solid", count = 2) => [[from, to, kind, { count, speed: 0.5 }]];

export const roundTrip = (from, to, kind = "solid", count = 2) => [
  [from, to, kind, { count, speed: 0.5, offset: 5 }],
  [from, to, kind, { count, speed: 0.5, offset: -5, reverse: true }],
];
