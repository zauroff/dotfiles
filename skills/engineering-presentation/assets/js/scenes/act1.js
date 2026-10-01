/**
 * The worked example. Six scenes on the path of one HTTP request.
 *
 * Between them they use every feature the engine has: cover, ghosts, chips,
 * halo, notes, states, meters, flow, focus, compact, swarm and stats. Delete
 * them and write your own; keep the shape.
 */

import {
  BOUND_LINKS,
  CHAIN_LINKS,
  PATH_FLOW,
  PATH_LINKS,
  PEER_LINKS,
  RUNNING,
  SERVERS,
  STAGES,
  STATE_LINKS,
  oneWay,
  roundTrip,
} from "./common.js";

export const ACT1 = [
  {
    id: "title",
    rail: "Title",
    layout: "empty",
    // A cover scene replaces the narration card with the title card.
    cover: `
      A request arrives at one address, is routed to one of many identical servers, runs a short
      chain of work, and touches state on the way back out. <strong>Every layer is a queue.</strong>
    `,
    nodes: [],
    links: [],
  },

  {
    id: "fleet",
    rail: "Fleet",
    layout: "fleet",
    title: "One door, many servers",
    text: `
      A request lands on the <strong>balancer</strong>. It holds no state: it picks a healthy
      server and forwards.
      <br /><br />
      The faint shapes behind are the rest of the fleet. Health checks travel between peers.
      Requests do not.
    `,
    nodes: ["client", "lb", ...SERVERS],
    ghosts: true,
    chips: { lb: ["round robin", "3 healthy · 0 draining"] },
    halo: { "app-b": "warm pool" },
    links: [
      ["client", "lb", "solid"],
      ...SERVERS.map((s) => ["lb", s, "pipe"]),
      ...PEER_LINKS,
    ],
    flow: [
      ["client", "lb", "solid", { count: 3, speed: 0.5 }],
      ["lb", "app-b", "pipe", { count: 2, speed: 0.45 }],
    ],
    notes: [{ x: 640, y: 570, align: "middle", lines: ["the balancer chooses; it does not queue"] }],
  },

  {
    id: "chain",
    rail: "Chain",
    layout: "chain",
    title: "The handler is a chain",
    text: `
      Three stages, in order. Decode the body, check the caller, build the answer.
      <br /><br />
      A stage names <strong>work</strong>, never a host. Nothing here says which machine runs it,
      which is what lets the next scene move it.
    `,
    nodes: STAGES,
    links: CHAIN_LINKS,
    notes: [{ x: 640, y: 470, align: "middle", lines: ["a stage names work, not a host"] }],
  },

  {
    id: "binding",
    rail: "Binding",
    layout: "bound",
    title: "Each stage is bound to a server",
    text: `
      Now the chain has an address for every stage. The dashed line under each box is the binding:
      this work, on that server.
      <br /><br />
      The <strong>pipes</strong> between servers are the only path a request takes. There is no
      broker in the middle.
    `,
    nodes: RUNNING,
    compact: true,
    links: [...PATH_LINKS, ...BOUND_LINKS, ...STATE_LINKS],
    states: { "app-a": "active", "app-b": "active", "app-c": "active" },
    focus: [...STAGES, ...SERVERS],
    flow: [
      ...PATH_FLOW,
      ["app-b", "app-c", "pipe", { count: 3, speed: 0.45 }],
      ...roundTrip("app-b", "cache"),
      ...oneWay("app-c", "db"),
    ],
    notes: [{ x: 520, y: 84, align: "start", lines: ["work is bound to a host,", "not written against one"] }],
  },

  {
    id: "saturation",
    rail: "Saturation",
    layout: "bound",
    title: "A backlog names the wrong layer",
    text: `
      The database stops answering. The last stage cannot finish, so it stops accepting, so the
      stage before it stops, and so on back to the door.
      <br /><br />
      The meters make the trap visible: <strong>the deepest backlog is furthest from the
      fault.</strong> Walk downstream to the last layer still draining.
    `,
    nodes: RUNNING,
    compact: true,
    links: [
      ...PATH_LINKS,
      ...BOUND_LINKS,
      ["app-b", "cache", "solid"],
      ["app-c", "db", "broken"],
    ],
    states: { db: "down", "app-c": "warn" },
    meters: {
      "app-a": { total: 8, done: 1, tone: "crit", unit: "queued" },
      "app-b": { total: 7, done: 2, tone: "warn", unit: "queued" },
      "app-c": { total: 4, done: 4 },
    },
    flow: [
      ...PATH_FLOW,
      ["app-b", "app-c", "pipe", { count: 5, speed: 0.16, pile: true }],
      ...roundTrip("app-b", "cache"),
    ],
    notes: [{ x: 520, y: 84, align: "start", lines: ["most lag is upstream;", "the cause is at the far end"] }],
  },

  {
    id: "scale",
    rail: "At scale",
    layout: "empty",
    title: "The same shape, larger",
    text: `
      That was one request through three stages on three servers.
      <br /><br />
      Production works exactly the way you just watched. There is simply rather more of it.
    `,
    nodes: [],
    links: [],
    swarm: true,
    stats: [
      { value: "hundreds", label: "servers" },
      { value: "thousands", label: "routes" },
      { value: "billions", label: "requests a day" },
    ],
  },
];
