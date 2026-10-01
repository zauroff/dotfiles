/**
 * Scene validator: `node check.js`. Plumbing. Run it after every edit.
 *
 * It catches the mistakes that fail silently in the browser: a node with no
 * position, a link to something not on stage, two nodes on top of each other,
 * or anything parked underneath the narration card where nobody will see it.
 */

import { BOX_SIZE, ENTITIES, GHOST_SETS, KIND, LAYOUTS, RADIUS, STATES, resolveLayout } from "./js/model.js";
import { SCENES } from "./js/scenes/index.js";

const VIEW = { w: 1280, h: 780 };

/** Must match LINK_STYLE in js/engine.js. */
const LINK_KINDS = [
  "solid",
  "mesh",
  "bond",
  "signal",
  "feed",
  "edge",
  "candidate",
  "propose",
  "pending",
  "bound",
  "pipe",
  "broken",
];

/** Minimum centre-to-centre distance before two round nodes read as crowded. */
const MIN_GAP = 88;

/** Clear space demanded between two node outlines, whatever their shape. */
const EDGE_MARGIN = 24;

/**
 * How far a node's outline extends toward (dx, dy). A BOX is a rectangle, and
 * two of them stacked over one node sit closer than MIN_GAP on purpose: a
 * plain centre-to-centre rule would reject a layout that is actually fine.
 */
function halfExtent(kind, dx, dy) {
  if (kind !== KIND.BOX) return RADIUS[kind];

  const t = 1 / Math.max(Math.abs(dx) / (BOX_SIZE.w / 2), Math.abs(dy) / (BOX_SIZE.h / 2), 1e-6);
  return Math.hypot(dx * t, dy * t);
}

/** Distance from a node's centre to the bottom of its second label line. */
const LABEL_DROP = 60;

/**
 * Regions of the viewBox covered by fixed HTML chrome. Nodes placed here are
 * hidden behind the narration card, the transport or the scene rail. Tested
 * against the bottom of the node's labels, not its centre: the label is what
 * collides first. Generous, because the SVG scales with the window and the
 * overlap worsens on short viewports.
 */
const FIXED_RESERVED = [
  { name: "transport controls", test: (x, y) => x > 1090 && y > 668 },
  { name: "scene rail", test: (x) => x > 1160 },
];

/**
 * The narration card is bottom-anchored and grows upward with its copy, so how
 * much of the diagram it covers differs per scene. Modelled rather than fixed:
 * the constants are fitted against three measured scenes (396/466/529 chars ->
 * 350/348/423px tall) and predict the rest to within a few pixels.
 */
const CARD = {
  right: 415, // viewBox x of the card's right edge
  bottom: 928, // screen y of its bottom edge, at the 1600x980 reference size
  base: 61,
  perChar: 0.55,
  perTitleLine: 36,
  titleWrap: 28,
  margin: 25,
};

/** Caps on copy, so a scene cannot quietly grow the card over the whole diagram. */
const MAX_TITLE_CHARS = 52;
const MIN_CARD_TOP = 330;

/** Top edge of the narration card for one scene, in viewBox units. */
function cardTop(title, body) {
  const titleLines = Math.max(1, Math.ceil(title.length / CARD.titleWrap));
  const height = CARD.base + body.length * CARD.perChar + titleLines * CARD.perTitleLine + CARD.margin;
  return (CARD.bottom - height - 2.5) / 1.25;
}

function reservedFor(title, body) {
  const top = cardTop(title, body);
  return [{ name: "narration card", test: (x, y) => x < CARD.right && y > top }, ...FIXED_RESERVED];
}

const plain = (html) =>
  html
    .replace(/<[^>]+>/g, "")
    .replace(/&[a-z]+;/g, "-")
    .replace(/\s+/g, " ")
    .trim();

/** Rough ink extent of an annotation, in viewBox units. */
function noteBounds(note) {
  const w = Math.max(...note.lines.map((l) => l.length)) * 6.1;
  const h = 14 * (note.lines.length - 1);

  const x0 = note.align === "start" ? note.x : note.align === "end" ? note.x - w : note.x - w / 2;
  return { x0, x1: x0 + w, y0: note.y - 14, y1: note.y + h + 4 };
}

let problems = 0;
const fail = (scene, msg) => {
  console.log(`  \x1b[31m✗\x1b[0m ${msg}`);
  problems++;
};

for (const scene of SCENES) {
  console.log(`\x1b[2m${scene.id}\x1b[0m (${scene.layout})`);

  if (!LAYOUTS[scene.layout]) {
    fail(scene, `unknown layout "${scene.layout}"`);
    continue;
  }

  const pos = resolveLayout(scene.layout);
  const shown = new Set(scene.nodes);

  for (const id of scene.nodes) {
    if (!ENTITIES[id]) fail(scene, `${id} is not in ENTITIES`);
    if (!pos[id]) fail(scene, `${id} has no position in layout "${scene.layout}"`);
  }

  for (const [from, to, kind] of scene.links ?? []) {
    if (!LINK_KINDS.includes(kind)) fail(scene, `link ${from}->${to} has unknown kind "${kind}"`);
    if (!shown.has(from)) fail(scene, `link ${from}->${to}: ${from} is not on stage`);
    if (!shown.has(to)) fail(scene, `link ${from}->${to}: ${to} is not on stage`);
  }

  for (const id of Object.keys(scene.chips ?? {})) {
    if (!shown.has(id)) fail(scene, `chips declared for ${id}, which is not on stage`);
  }

  for (const id of Object.keys(scene.halo ?? {})) {
    if (!shown.has(id)) fail(scene, `halo declared for ${id}, which is not on stage`);
  }

  for (const [id, name] of Object.entries(scene.states ?? {})) {
    if (!shown.has(id)) fail(scene, `state declared for ${id}, which is not on stage`);
    if (!STATES[name]) fail(scene, `${id} has unknown state "${name}"`);
  }

  for (const [id, meter] of Object.entries(scene.meters ?? {})) {
    if (!shown.has(id)) fail(scene, `meter declared for ${id}, which is not on stage`);
    if (meter.done > meter.total) fail(scene, `meter on ${id} has done ${meter.done} over total ${meter.total}`);
  }

  for (const id of scene.focus ?? []) {
    if (!shown.has(id)) fail(scene, `focus names ${id}, which is not on stage`);
  }

  for (const [from, to, kind] of scene.flow ?? []) {
    const exists = (scene.links ?? []).some(([a, b, k]) => a === from && b === to && k === kind);
    if (!exists) fail(scene, `flow ${from}->${to} (${kind}) has no matching link`);
  }

  const title = plain(scene.title ?? "");
  const body = plain(scene.text ?? "");

  const RESERVED = reservedFor(title, body);
  const top = cardTop(title, body);

  if (title.length > MAX_TITLE_CHARS) {
    fail(scene, `title is ${title.length} chars, over the ${MAX_TITLE_CHARS} the layout allows for`);
  }
  if (top < MIN_CARD_TOP) {
    fail(
      scene,
      `narration (${body.length} chars) pushes the card up to y=${top.toFixed(0)}; keep it below y=${MIN_CARD_TOP}`,
    );
  }

  const placed = scene.nodes.filter((id) => pos[id]).map((id) => [id, pos[id]]);

  // Annotations are ink too, and unlike nodes they are hand-placed with no
  // layout to anchor them, which is exactly why they drift into things.
  for (const note of scene.notes ?? []) {
    const b = noteBounds(note);
    const corners = [
      [b.x0, b.y0],
      [b.x1, b.y0],
      [b.x0, b.y1],
      [b.x1, b.y1],
    ];

    for (const [cx, cy] of corners) {
      const hit = RESERVED.find((r) => r.test(cx, cy));
      if (hit) {
        fail(scene, `note "${note.lines[0]}" overlaps the ${hit.name}`);
        break;
      }
    }

    for (const [id, [x, y]] of placed) {
      const kind = ENTITIES[id].kind;
      const halfW = kind === KIND.BOX ? BOX_SIZE.w / 2 : RADIUS[kind];
      const nearX = Math.max(b.x0, Math.min(x, b.x1));
      const nearY = Math.max(b.y0, Math.min(y, b.y1));

      // Node labels hang below the centre, so the vertical reach is asymmetric.
      if (Math.abs(nearX - x) < halfW + 6 && nearY - y > -RADIUS[kind] - 6 && nearY - y < LABEL_DROP) {
        fail(scene, `note "${note.lines[0]}" overlaps ${id}`);
        break;
      }
    }
  }

  for (const [id, [x, y]] of placed) {
    if (x < 60 || x > VIEW.w - 60 || y < 60 || y > VIEW.h - 60) {
      fail(scene, `${id} at ${x.toFixed(0)},${y.toFixed(0)} is outside the safe area`);
    }

    const hit = RESERVED.find((r) => r.test(x, y + LABEL_DROP));
    if (hit) fail(scene, `${id} at ${x.toFixed(0)},${y.toFixed(0)} sits under the ${hit.name}`);
  }

  for (let i = 0; i < placed.length; i++) {
    for (let j = i + 1; j < placed.length; j++) {
      const [idA, [ax, ay]] = placed[i];
      const [idB, [bx, by]] = placed[j];
      const kindA = ENTITIES[idA].kind;
      const kindB = ENTITIES[idB].kind;

      const dx = bx - ax;
      const dy = by - ay;
      const d = Math.hypot(dx, dy);

      const boxed = kindA === KIND.BOX || kindB === KIND.BOX;
      const need = halfExtent(kindA, dx, dy) + halfExtent(kindB, -dx, -dy) + EDGE_MARGIN;
      const required = boxed ? need : Math.max(MIN_GAP, need);

      if (d < required) {
        fail(scene, `${idA} and ${idB} are ${d.toFixed(0)}px apart, need ${required.toFixed(0)}`);
      }
    }
  }

  // Ghosts are unlabelled, so they only need to clear the real nodes and the
  // chrome. But each set shares one position list across every scene that
  // shows it, which is exactly how one drifts under a foreground node
  // unnoticed. Both sets are checked, whichever is currently the default.
  if (!scene.ghosts) continue;

  for (const [setName, set] of Object.entries(GHOST_SETS)) {
    const clearance = 70 + set.r;

    for (const [gx, gy] of set.positions) {
      const outside = gx < 60 || gx > VIEW.w - 60 || gy < 60 || gy > VIEW.h - 60;
      if (outside && !set.clip) fail(scene, `${setName} ghost at ${gx},${gy} is outside the safe area`);

      const hit = RESERVED.find((r) => r.test(gx, gy));
      if (hit && !(set.clip && hit.name === "scene rail")) {
        fail(scene, `${setName} ghost at ${gx},${gy} sits under the ${hit.name}`);
      }

      for (const [id, [x, y]] of placed) {
        const d = Math.hypot(gx - x, gy - y);
        if (d < clearance) fail(scene, `${setName} ghost at ${gx},${gy} is ${d.toFixed(0)}px from ${id}`);
      }
    }
  }
}

console.log(problems ? `\n\x1b[31m${problems} problem(s)\x1b[0m` : `\n\x1b[32m✓\x1b[0m ${SCENES.length} scenes valid`);
process.exit(problems ? 1 : 0);
