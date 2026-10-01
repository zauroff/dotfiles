/**
 * Rendering engine. Plumbing: a deck should never need to edit this file.
 *
 * One requestAnimationFrame loop owns a small mutable model; every frame it
 * eases each value toward its target and writes the result to the DOM. There
 * are no tween objects to manage and no animation lifecycle to unwind: a scene
 * change simply retargets, so jumping between scenes mid-transition is always
 * safe.
 */

import {
  ACCENTS,
  BOX_SIZE,
  ENTITIES,
  GHOST_REACH,
  GHOST_SETS,
  KIND,
  METER_OFFSET,
  RADIUS,
  STATES,
  SWARM,
  SWARM_LINK,
  resolveLayout,
} from "./model.js";

const NS = "http://www.w3.org/2000/svg";

/** Easing rate for position/opacity. Higher settles faster. */
const EASE = 5.2;
/** Easing rate for link draw-in, deliberately slower than node movement. */
const EASE_DRAW = 3.4;

/**
 * Jump straight to each scene's final state. Honours the OS reduced-motion
 * setting, and `?static` makes screenshots deterministic: headless Chrome runs
 * too few animation frames to ever settle on its own.
 */
export const SNAP =
  new URLSearchParams(location.search).has("static") ||
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/** Which background treatment to draw. `?ghosts=small` for the other one. */
export const GHOST_SET = GHOST_SETS[new URLSearchParams(location.search).get("ghosts")] ?? GHOST_SETS.full;

const css = getComputedStyle(document.documentElement);
const v = (name) => css.getPropertyValue(name).trim();

const COLOR = {
  primary: v("--primary"),
  secondary: v("--secondary"),
  neutral: v("--neutral"),
  ink: v("--ink"),
  inkDim: v("--ink-dim"),
  inkFaint: v("--ink-faint"),
  bgLift: v("--bg-lift"),
  warn: v("--warn"),
  crit: v("--crit"),
};

/** Accent names resolved to colours once, at load. */
const ACCENT_COLOR = Object.fromEntries(Object.entries(ACCENTS).map(([name, prop]) => [name, v(prop)]));

/**
 * Link kinds. Add one here and to LINK_KINDS in check.js.
 *
 *   color    null means "take the accent of the node it points at"
 *   curve    perpendicular bow, in user units; sign picks the side
 *   draw     true animates the line drawing itself in, once
 *   dash     a dash pattern; with `march`, the dashes travel
 */
const LINK_STYLE = {
  /** A plain, real connection between two things. */
  solid: { color: null, width: 1.2, opacity: 0.5, curve: 0, draw: true },
  /** Peer chatter: membership, health, replication. Not payload. */
  mesh: { color: COLOR.primary, width: 1, opacity: 0.34, curve: 30, dash: "1.5 7", march: 14 },
  /** A standing relationship between coordinators. */
  bond: { color: COLOR.secondary, width: 1.4, opacity: 0.55, curve: 26, draw: true },
  /** Control traffic: instructions travelling out from a coordinator. */
  signal: { color: COLOR.secondary, width: 1, opacity: 0.42, curve: 20, dash: "5 6", march: -9 },
  /** A poll or a subscription against a store. */
  feed: { color: COLOR.neutral, width: 1, opacity: 0.45, curve: 0, dash: "2 5", march: 18 },
  /** The abstract graph itself: stage to stage, independent of where it runs. */
  edge: { color: COLOR.inkDim, width: 1.3, opacity: 0.6, curve: 0, draw: true },
  /** Could run there. One of several options, none chosen yet. */
  candidate: { color: COLOR.inkFaint, width: 1, opacity: 0.55, curve: 14, dash: "2 6", march: 11 },
  /**
   * A proposal travelling a commit tree. Bows opposite to `mesh` so the two
   * are never mistaken for one line between the same pair.
   */
  propose: { color: COLOR.secondary, width: 1.3, opacity: 0.7, curve: -26, dash: "5 6", march: -11 },
  /** Proposed but not agreed. */
  pending: { color: COLOR.inkFaint, width: 1, opacity: 0.8, curve: 0, dash: "3 4", march: 0 },
  /** Agreed: this work runs here. */
  bound: { color: COLOR.primary, width: 1, opacity: 0.4, curve: 0, dash: "3 4", march: 0 },
  /** The live path payload actually travels. */
  pipe: { color: COLOR.primary, width: 1.8, opacity: 0.75, curve: 34, draw: true },
  /** Same path, severed. Draw it over the pipe's route so the break is in place. */
  broken: { color: COLOR.crit, width: 1.8, opacity: 0.8, curve: 34, dash: "7 6", march: 0 },
};

/** Opacity applied to anything outside a scene's `focus` set. */
const UNFOCUSED = 0.22;

function el(tag, attrs = {}) {
  const node = document.createElementNS(NS, tag);
  for (const [k, val] of Object.entries(attrs)) node.setAttribute(k, val);
  return node;
}

function textLines(lines, { cls, x = 0, y = 0, dy = 13, anchor }) {
  const t = el("text", { class: cls, x, y });
  if (anchor) t.setAttribute("text-anchor", anchor);

  lines.forEach((line, i) => {
    const span = el("tspan", { x, dy: i === 0 ? 0 : dy });
    span.textContent = line;
    t.appendChild(span);
  });

  return t;
}

function hexPath(r) {
  const pts = [];
  for (let i = 0; i < 6; i++) {
    const a = (Math.PI / 3) * i - Math.PI / 2;
    pts.push(`${(Math.cos(a) * r).toFixed(2)},${(Math.sin(a) * r).toFixed(2)}`);
  }
  return `M${pts.join("L")}Z`;
}

function linkPath(ax, ay, bx, by, curve) {
  if (!curve) return `M${ax.toFixed(1)},${ay.toFixed(1)}L${bx.toFixed(1)},${by.toFixed(1)}`;

  const dx = bx - ax;
  const dy = by - ay;
  const len = Math.hypot(dx, dy) || 1;
  const cx = (ax + bx) / 2 + (-dy / len) * curve;
  const cy = (ay + by) / 2 + (dx / len) * curve;

  return `M${ax.toFixed(1)},${ay.toFixed(1)}Q${cx.toFixed(1)},${cy.toFixed(1)} ${bx.toFixed(1)},${by.toFixed(1)}`;
}

/** Trim a link endpoint back to the boundary of the node it leaves. */
function edgePoint(from, to, r) {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const d = Math.hypot(dx, dy) || 1;
  return [from.x + (dx / d) * r, from.y + (dy / d) * r];
}

/** Same, but a BOX is a rectangle: a circular trim leaves a visible gap on it. */
function nodeEdge(from, to) {
  if (from.entity.kind !== KIND.BOX) return edgePoint(from, to, RADIUS[from.entity.kind]);

  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const hw = BOX_SIZE.w / 2 + 5;
  const hh = BOX_SIZE.h / 2 + 5;
  const t = 1 / Math.max(Math.abs(dx) / hw, Math.abs(dy) / hh, 1e-6);

  return [from.x + dx * t, from.y + dy * t];
}

const accentOf = (id) => {
  const e = ENTITIES[id];
  if (e.kind === KIND.NODE) return COLOR.primary;
  if (e.kind === KIND.HUB) return COLOR.secondary;
  if (e.kind === KIND.LEAF) return ACCENT_COLOR[e.accent] ?? COLOR.neutral;
  return COLOR.neutral;
};

/* ---------------------------------------------------------------- builders */

function buildNode(id, e) {
  const g = el("g");
  const c = COLOR.primary;

  g.appendChild(el("circle", { r: 33, fill: "none", stroke: c, "stroke-width": 1, opacity: 0.2 }));
  g.appendChild(el("circle", { r: 26, fill: COLOR.bgLift, stroke: c, "stroke-width": 1.5 }));
  g.appendChild(el("circle", { r: 3.5, fill: c }));

  const label = textLines([e.label], { cls: "n-label", y: 54, anchor: "middle" });
  label.setAttribute("fill", COLOR.ink);
  g.appendChild(label);

  if (e.sub) g.appendChild(textLines([e.sub], { cls: "n-sub", y: 68, anchor: "middle" }));

  return g;
}

function buildHub(id, e) {
  const g = el("g");
  const c = COLOR.secondary;

  // The primary hub is marked by light rather than by a word: a slow beacon
  // ring and a lit core. Nothing to collide with, and it reads instantly
  // across a room, which a 7px caps label does not.
  if (e.primary) {
    if (SNAP) {
      g.appendChild(el("circle", { r: 44, fill: "none", stroke: c, "stroke-width": 1, opacity: 0.26 }));
    } else {
      g.appendChild(el("circle", { class: "primary-beacon", stroke: c }));
    }
  }

  g.appendChild(
    el("path", { d: hexPath(29), fill: "none", stroke: c, "stroke-width": 1, opacity: e.primary ? 0.5 : 0.22 }),
  );

  const body = el("path", { d: hexPath(23), fill: COLOR.bgLift, stroke: c, "stroke-width": e.primary ? 1.9 : 1.4 });
  if (e.primary) body.setAttribute("filter", "url(#glow)");
  g.appendChild(body);

  const core = el("circle", { r: e.primary ? 4.5 : 3, fill: c });
  if (e.primary) core.setAttribute("filter", "url(#glow)");
  g.appendChild(core);

  const label = textLines([e.label], { cls: "n-label", y: 50, anchor: "middle" });
  label.setAttribute("fill", e.primary ? COLOR.ink : COLOR.inkDim);
  g.appendChild(label);

  return g;
}

function buildBox(id, e) {
  const g = el("g");
  const { w, h } = BOX_SIZE;

  g.appendChild(
    el("rect", {
      x: -w / 2,
      y: -h / 2,
      width: w,
      height: h,
      rx: 3,
      fill: COLOR.bgLift,
      stroke: COLOR.inkDim,
      "stroke-width": 1.1,
      opacity: 0.9,
    }),
  );

  const label = textLines([e.label], { cls: "n-box", y: 4, anchor: "middle" });
  label.setAttribute("fill", COLOR.ink);
  g.appendChild(label);

  // The detail line, hidden by `compact` once the box is placed against
  // something else and the extra line would collide.
  if (e.sub) {
    const sub = textLines([e.sub], { cls: "n-chip n-box-sub", y: h / 2 + 16, anchor: "middle" });
    sub.setAttribute("fill", COLOR.inkFaint);
    g.appendChild(sub);
  }

  return g;
}

function buildLeaf(id, e) {
  const g = el("g");
  const c = ACCENT_COLOR[e.accent] ?? COLOR.neutral;

  g.appendChild(el("circle", { r: 19, fill: "none", stroke: c, "stroke-width": 1, opacity: 0.28 }));
  g.appendChild(el("circle", { r: 13, fill: COLOR.bgLift, stroke: c, "stroke-width": 1.2 }));

  const label = textLines([e.label], { cls: "n-label", y: 38, anchor: "middle" });
  label.setAttribute("fill", COLOR.inkDim);
  g.appendChild(label);

  if (e.accent) {
    const badge = textLines([e.accent], { cls: "n-badge", y: 51, anchor: "middle" });
    badge.setAttribute("fill", c);
    g.appendChild(badge);
  }

  return g;
}

function buildStore(id, e) {
  const g = el("g");
  const c = COLOR.neutral;

  g.appendChild(
    el("rect", { x: -46, y: -29, width: 92, height: 58, rx: 3, fill: COLOR.bgLift, stroke: c, "stroke-width": 1.2 }),
  );
  for (const y of [-10, 0, 10]) {
    g.appendChild(el("line", { x1: -26, y1: y, x2: 26, y2: y, stroke: c, "stroke-width": 1, opacity: 0.35 }));
  }

  const label = textLines([e.label], { cls: "n-label", y: 50, anchor: "middle" });
  label.setAttribute("fill", COLOR.ink);
  g.appendChild(label);

  if (e.sub) g.appendChild(textLines([e.sub], { cls: "n-sub", y: 64, anchor: "middle" }));

  return g;
}

const BUILDERS = {
  [KIND.NODE]: buildNode,
  [KIND.HUB]: buildHub,
  [KIND.LEAF]: buildLeaf,
  [KIND.STORE]: buildStore,
  [KIND.BOX]: buildBox,
};

/** Ring + micro-label layered over a node to show a per-scene state. */
function buildState(name, kind) {
  const spec = STATES[name];
  if (!spec) throw new Error(`unknown node state: ${name}`);

  const g = el("g");
  const r = RADIUS[kind] + 9;
  const color = v(spec.color);

  const ring = el("circle", { r, fill: "none", stroke: color, "stroke-width": 1.4, opacity: 0.85 });
  if (spec.dash) ring.setAttribute("stroke-dasharray", spec.dash);
  g.appendChild(ring);

  const text = textLines([spec.label], { cls: "n-badge", y: -r - 10, anchor: "middle" });
  text.setAttribute("fill", color);
  g.appendChild(text);

  return g;
}

/** Severity of a backlog, when a scene wants to grade one. */
const METER_TONE = { warn: COLOR.warn, crit: COLOR.crit };

/** Count meter under a node: filled ticks are outstanding, hollow are done. */
function buildMeter({ total, done, tone, unit }, dx) {
  const g = el("g");
  const pitch = 7;
  const x0 = dx + (-(total - 1) * pitch) / 2;
  const c = METER_TONE[tone] ?? COLOR.primary;

  for (let i = 0; i < total; i++) {
    const complete = i < done;
    g.appendChild(
      el("rect", {
        x: x0 + i * pitch - 1.5,
        y: 74,
        width: 3,
        height: 11,
        rx: 1,
        fill: complete ? "none" : c,
        stroke: c,
        "stroke-width": 1,
        opacity: complete ? 0.3 : 0.95,
      }),
    );
  }

  const left = total - done;
  const caption = textLines([left ? `${left} ${unit ?? "pending"}` : "clear"], {
    cls: "n-badge",
    x: dx,
    y: 100,
    anchor: "middle",
  });
  caption.setAttribute("fill", left ? c : COLOR.inkFaint);
  g.appendChild(caption);

  return g;
}

/* ------------------------------------------------------------------ engine */

export class Engine {
  constructor(svg) {
    this.ghostLayer = svg.querySelector("#layer-ghosts");
    this.linkLayer = svg.querySelector("#layer-links");
    this.noteLayer = svg.querySelector("#layer-notes");
    this.nodeLayer = svg.querySelector("#layer-nodes");

    this.nodes = new Map();
    this.links = new Map();
    this.notes = new Map();
    this.flows = [];

    this.swarmLayer = svg.querySelector("#layer-swarm");
    this.statLayer = svg.querySelector("#layer-stats");

    this.ghostAlpha = 0;
    this.ghostTarget = 0;
    this.swarmAlpha = 0;
    this.swarmTarget = 0;
    this.statsKey = "";

    this.buildGhosts();
    this.buildSwarm();

    this.phase = 0;
    this.last = performance.now();

    requestAnimationFrame(this.tick);
  }

  /**
   * The background field. Built once and faded as a whole rather than diffed
   * per scene: they are scenery, not participants, and giving them individual
   * lifecycles would cost more than it shows.
   */
  buildGhosts() {
    const { r, link, positions } = GHOST_SET;
    const full = r >= RADIUS[KIND.NODE];

    const thread = (x1, y1, x2, y2) =>
      el("line", {
        x1,
        y1,
        x2,
        y2,
        stroke: COLOR.primary,
        "stroke-width": 1,
        "stroke-dasharray": "1.5 7",
        opacity: 0.85,
      });

    for (let i = 0; i < positions.length; i++) {
      for (let j = i + 1; j < positions.length; j++) {
        const [ax, ay] = positions[i];
        const [bx, by] = positions[j];
        if (Math.hypot(ax - bx, ay - by) > link) continue;

        this.ghostLayer.appendChild(thread(ax, ay, bx, by));
      }
    }

    // One reach into the foreground per ghost, retargeted each frame because
    // the nodes move between layouts.
    this.ghostReach = positions.map(([x, y]) => {
      const line = thread(x, y, x, y);
      line.setAttribute("opacity", 0);
      this.ghostLayer.appendChild(line);
      return { x, y, line };
    });

    for (const [x, y] of positions) {
      if (full) {
        // Identical geometry to a real NODE, minus the labels.
        this.ghostLayer.appendChild(
          el("circle", { cx: x, cy: y, r: 33, fill: "none", stroke: COLOR.primary, "stroke-width": 1, opacity: 0.55 }),
        );
        this.ghostLayer.appendChild(
          el("circle", { cx: x, cy: y, r: 26, fill: COLOR.bgLift, stroke: COLOR.primary, "stroke-width": 1.5 }),
        );
        this.ghostLayer.appendChild(el("circle", { cx: x, cy: y, r: 3.5, fill: COLOR.primary }));
        continue;
      }

      this.ghostLayer.appendChild(el("circle", { cx: x, cy: y, r, fill: COLOR.bgLift }));
      this.ghostLayer.appendChild(
        el("circle", { cx: x, cy: y, r, fill: "none", stroke: COLOR.primary, "stroke-width": 1.1 }),
      );
    }
  }

  /**
   * The closing field. Far denser than the ghosts and with no reach lines: by
   * the time it appears there is no foreground left to reach.
   */
  buildSwarm() {
    const edges = [];

    for (let i = 0; i < SWARM.length; i++) {
      for (let j = i + 1; j < SWARM.length; j++) {
        const [x1, y1] = SWARM[i];
        const [x2, y2] = SWARM[j];
        if (Math.hypot(x1 - x2, y1 - y2) > SWARM_LINK) continue;

        edges.push({ x1, y1, x2, y2 });
        this.swarmLayer.appendChild(
          el("line", {
            x1,
            y1,
            x2,
            y2,
            stroke: COLOR.primary,
            "stroke-width": 1,
            "stroke-dasharray": "1.5 7",
            opacity: 0.6,
          }),
        );
      }
    }

    SWARM.forEach(([x, y], i) => {
      // A scattering of hexagons, because a system this size has coordinators
      // too, and the shape says so without needing a label.
      const hub = i % 13 === 6;
      const c = hub ? COLOR.secondary : COLOR.primary;

      this.swarmLayer.appendChild(el("circle", { cx: x, cy: y, r: 8, fill: COLOR.bgLift }));

      const ring = hub
        ? el("path", { d: hexPath(9), transform: `translate(${x},${y})`, fill: "none" })
        : el("circle", { cx: x, cy: y, r: 8, fill: "none" });

      ring.setAttribute("stroke", c);
      ring.setAttribute("stroke-width", 1.1);

      // Out of phase, so the field breathes rather than pulsing in unison.
      if (!SNAP) {
        ring.setAttribute("class", "swarm-node");
        ring.style.animationDelay = `${(-i * 0.41).toFixed(2)}s`;
      }

      this.swarmLayer.appendChild(ring);
    });

    // Traffic. Every third thread carries one dot, at varied speeds: the point
    // is that the field is busy, not that any one route is legible.
    this.swarmTraffic = [];
    if (SNAP) return;

    for (let i = 0; i < edges.length; i += 3) {
      const dot = el("circle", { r: 2.4, fill: COLOR.primary });
      this.swarmLayer.appendChild(dot);
      this.swarmTraffic.push({
        edge: edges[i],
        dot,
        t: (i * 0.137) % 1,
        speed: 0.1 + (i % 5) * 0.035,
      });
    }
  }

  /** Large display figures, for a closing scene. */
  syncStats(stats) {
    const key = stats.map((s) => `${s.value}/${s.label}`).join("|");
    if (key === this.statsKey) return;
    this.statsKey = key;

    this.statLayer.replaceChildren();
    if (!stats.length) return;

    // Centred on the canvas, not on the space left over beside the narration
    // card: by this scene the card is short and the diagram is gone.
    const span = 600;
    const x0 = 640 - span / 2;
    const step = stats.length > 1 ? span / (stats.length - 1) : 0;

    stats.forEach((stat, i) => {
      // Two groups, not one. A CSS `transform` overrides an SVG transform
      // attribute, and the `rise` keyframes end at `transform: none`: put both
      // on the same element and the animation drops the stat onto the origin.
      const anchor = el("g", { transform: `translate(${x0 + i * step},300)` });
      const g = el("g");
      if (!SNAP) g.style.animation = `rise 620ms ${120 + i * 110}ms cubic-bezier(.16,1,.3,1) both`;
      anchor.appendChild(g);

      const value = textLines([stat.value], { cls: "stat-value", anchor: "middle" });
      value.setAttribute("fill", COLOR.ink);
      g.appendChild(value);

      g.appendChild(
        el("line", { x1: -26, y1: 20, x2: 26, y2: 20, stroke: COLOR.primary, "stroke-width": 1, opacity: 0.5 }),
      );

      const label = textLines([stat.label], { cls: "stat-label", y: 42, anchor: "middle" });
      label.setAttribute("fill", COLOR.inkDim);
      g.appendChild(label);

      this.statLayer.appendChild(anchor);
    });
  }

  /** Point each ghost's reach at the nearest live NODE, or hide it. */
  aimGhostReach() {
    const live = [...this.nodes.values()].filter((n) => n.entity.kind === KIND.NODE && n.alpha > 0.4);

    for (const g of this.ghostReach) {
      let best = null;
      let bestD = GHOST_REACH;

      for (const a of live) {
        const d = Math.hypot(a.x - g.x, a.y - g.y);
        if (d < bestD) {
          bestD = d;
          best = a;
        }
      }

      if (!best) {
        g.line.setAttribute("opacity", 0);
        continue;
      }

      const [x1, y1] = edgePoint(g, best, GHOST_SET.r);
      const [x2, y2] = edgePoint(best, g, RADIUS[KIND.NODE]);

      g.line.setAttribute("x1", x1.toFixed(1));
      g.line.setAttribute("y1", y1.toFixed(1));
      g.line.setAttribute("x2", x2.toFixed(1));
      g.line.setAttribute("y2", y2.toFixed(1));
      g.line.setAttribute("opacity", 0.85);
      g.line.setAttribute("stroke-dashoffset", (-this.phase * 14).toFixed(2));
    }
  }

  /* -------------------------------------------------------------- scenes */

  show(scene) {
    const pos = resolveLayout(scene.layout);
    const wanted = new Set(scene.nodes);

    for (const id of scene.nodes) {
      if (!pos[id]) throw new Error(`scene "${scene.id}" shows ${id}, absent from layout "${scene.layout}"`);
      this.upsertNode(id, pos[id], scene);
    }

    const focus = scene.focus?.length ? new Set(scene.focus) : null;

    for (const [id, n] of this.nodes) {
      if (!wanted.has(id)) {
        n.talpha = 0;
        n.tscale = 0.62;
        continue;
      }

      n.talpha = focus && !focus.has(id) ? UNFOCUSED : 1;
    }

    const wantedLinks = new Set();
    for (const [from, to, kind] of scene.links ?? []) {
      wantedLinks.add(`${from}|${to}|${kind}`);
      this.upsertLink(from, to, kind);
    }

    for (const [key, l] of this.links) {
      if (!wantedLinks.has(key)) l.talpha = 0;
    }

    this.syncNotes(scene.notes ?? []);
    this.syncFlows(scene.flow ?? []);
    this.syncStats(scene.stats ?? []);

    this.ghostTarget = scene.ghosts ? 0.17 : 0;
    this.swarmTarget = scene.swarm ? 0.3 : 0;
  }

  upsertNode(id, [x, y], scene) {
    const entity = ENTITIES[id];
    let n = this.nodes.get(id);

    if (!n) {
      const g = el("g");
      g.appendChild(BUILDERS[entity.kind](id, entity));
      this.nodeLayer.appendChild(g);

      n = { id, entity, g, x, y, alpha: 0, scale: 0.35, extrasKey: "" };
      this.nodes.set(id, n);
      this.ping(x, y, accentOf(id));
    }

    n.tx = x;
    n.ty = y;
    n.talpha = 1;
    n.tscale = 1;

    this.syncExtras(n, scene);
  }

  /**
   * Per-scene decoration attached to a node: chips, halo, state ring, meter.
   * Rebuilt wholesale when any of it changes, which is cheap at this scale and
   * avoids partial-update bugs.
   */
  syncExtras(n, scene) {
    const chips = scene.chips?.[n.id] ?? [];
    const halo = scene.halo?.[n.id];
    const state = scene.states?.[n.id];
    const meter = scene.meters?.[n.id];

    // A BOX drops its detail line when the scene is compact, where the box
    // sits close enough to other things that the extra line would collide.
    n.g.classList.toggle("is-compact", Boolean(scene.compact));

    const key = [
      halo ?? "",
      state ?? "",
      meter ? `${meter.total}/${meter.done}/${meter.tone ?? ""}/${meter.unit ?? ""}` : "",
      chips.join("|"),
    ].join("::");

    if (key === n.extrasKey) return;
    n.extrasKey = key;

    n.extras?.remove();
    n.extras = el("g");
    if (!SNAP) n.extras.style.animation = "rise 460ms 120ms cubic-bezier(.16,1,.3,1) both";

    if (halo) {
      n.extras.appendChild(
        el("circle", {
          r: 17,
          fill: "none",
          stroke: COLOR.inkDim,
          "stroke-width": 1,
          "stroke-dasharray": "1 4",
          opacity: 0.7,
        }),
      );
      const badge = textLines([halo], { cls: "n-badge", y: -40, anchor: "middle" });
      badge.setAttribute("fill", COLOR.inkDim);
      n.extras.appendChild(badge);
    }

    if (chips.length) {
      const c = accentOf(n.id);
      const y = RADIUS[n.entity.kind] + 48;

      const bar = el("line", { x1: -1, y1: y - 16, x2: 1, y2: y - 16, stroke: c, "stroke-width": 1, opacity: 0.5 });
      n.extras.appendChild(bar);

      const t = textLines(chips, { cls: "n-chip", y, dy: 14, anchor: "middle" });
      t.setAttribute("fill", c);
      t.setAttribute("opacity", 0.85);
      n.extras.appendChild(t);
    }

    if (state) n.extras.appendChild(buildState(state, n.entity.kind));
    if (meter) n.extras.appendChild(buildMeter(meter, METER_OFFSET[n.id] ?? 0));

    n.g.appendChild(n.extras);
  }

  upsertLink(from, to, kind) {
    const key = `${from}|${to}|${kind}`;
    let l = this.links.get(key);

    if (!l) {
      const style = LINK_STYLE[kind];
      if (!style) throw new Error(`unknown link kind: ${kind}`);

      const color = style.color ?? accentOf(to);

      const path = el("path", {
        fill: "none",
        stroke: color,
        "stroke-width": style.width,
        "stroke-linecap": "round",
      });
      this.linkLayer.appendChild(path);

      l = { key, from, to, kind, style, path, alpha: 0, draw: style.draw ? 0 : 1 };
      this.links.set(key, l);
    }

    l.talpha = 1;
    l.tdraw = 1;
  }

  syncNotes(notes) {
    const wanted = new Set();

    for (const note of notes) {
      const key = note.lines.join("|");
      wanted.add(key);

      if (this.notes.has(key)) {
        Object.assign(this.notes.get(key), { tx: note.x, ty: note.y, talpha: 1 });
        continue;
      }

      const g = el("g");
      const anchor = note.align === "start" ? "start" : note.align === "end" ? "end" : "middle";

      const rule = el("line", {
        x1: anchor === "start" ? 0 : -14,
        y1: -14,
        x2: anchor === "start" ? 22 : 14,
        y2: -14,
        stroke: COLOR.inkFaint,
        "stroke-width": 1,
        opacity: 0.55,
      });
      g.appendChild(rule);
      g.appendChild(textLines(note.lines, { cls: "note-text", dy: 14, anchor }));

      this.noteLayer.appendChild(g);
      this.notes.set(key, { g, x: note.x, y: note.y + 6, tx: note.x, ty: note.y, alpha: 0, talpha: 1 });
    }

    for (const [key, n] of this.notes) {
      if (!wanted.has(key)) n.talpha = 0;
    }
  }

  /**
   * Particles travelling along a link. `[from, to, kind]`, optionally followed
   * by `{ count, speed, reverse, offset, pile }`.
   */
  syncFlows(flow) {
    for (const f of this.flows) f.dot.remove();
    this.flows = [];

    for (const [from, to, kind, opts = {}] of flow) {
      const link = this.links.get(`${from}|${to}|${kind}`);
      if (!link) continue;

      const count = opts.count ?? 2;
      const speed = opts.speed ?? 0.4;
      const color = LINK_STYLE[kind].color ?? accentOf(to);

      for (let i = 0; i < count; i++) {
        const dot = el("circle", { r: 3, fill: color });
        dot.setAttribute("filter", "url(#glow)");
        this.linkLayer.appendChild(dot);
        this.flows.push({
          link,
          dot,
          speed,
          reverse: Boolean(opts.reverse),
          offset: opts.offset ?? 0,
          pile: Boolean(opts.pile),
          t: i / count,
        });
      }
    }
  }

  ping(x, y, color) {
    if (SNAP) return;

    const c = el("circle", { cx: x, cy: y, class: "ping", stroke: color });
    this.nodeLayer.appendChild(c);
    c.addEventListener("animationend", () => c.remove());
  }

  /* ---------------------------------------------------------------- loop */

  tick = (now) => {
    const dt = Math.min((now - this.last) / 1000, 0.05);
    this.last = now;
    this.phase += dt;

    const k = SNAP ? 1 : 1 - Math.exp(-dt * EASE);
    const kDraw = SNAP ? 1 : 1 - Math.exp(-dt * EASE_DRAW);

    this.ghostAlpha += (this.ghostTarget - this.ghostAlpha) * kDraw;
    this.ghostLayer.setAttribute("opacity", this.ghostAlpha.toFixed(3));
    if (this.ghostAlpha > 0.01) this.aimGhostReach();

    this.swarmAlpha += (this.swarmTarget - this.swarmAlpha) * kDraw;
    this.swarmLayer.setAttribute("opacity", this.swarmAlpha.toFixed(3));

    if (this.swarmAlpha > 0.01) {
      for (const f of this.swarmTraffic) {
        f.t = (f.t + dt * f.speed) % 1;
        const { x1, y1, x2, y2 } = f.edge;
        f.dot.setAttribute("cx", (x1 + (x2 - x1) * f.t).toFixed(1));
        f.dot.setAttribute("cy", (y1 + (y2 - y1) * f.t).toFixed(1));
      }
    }

    for (const [id, n] of this.nodes) {
      n.x += (n.tx - n.x) * k;
      n.y += (n.ty - n.y) * k;
      n.alpha += (n.talpha - n.alpha) * k;
      n.scale += (n.tscale - n.scale) * k;

      if (n.talpha === 0 && n.alpha < 0.02) {
        n.g.remove();
        this.nodes.delete(id);
        continue;
      }

      n.g.setAttribute("transform", `translate(${n.x.toFixed(2)},${n.y.toFixed(2)}) scale(${n.scale.toFixed(3)})`);
      n.g.setAttribute("opacity", n.alpha.toFixed(3));
    }

    for (const [key, l] of this.links) {
      const a = this.nodes.get(l.from);
      const b = this.nodes.get(l.to);

      l.alpha += ((a && b ? l.talpha : 0) - l.alpha) * k;
      if (l.style.draw) l.draw += (l.tdraw - l.draw) * kDraw;

      if (l.talpha === 0 && l.alpha < 0.02) {
        l.path.remove();
        this.links.delete(key);
        continue;
      }
      if (!a || !b) continue;

      const [ax, ay] = nodeEdge(a, b);
      const [bx, by] = nodeEdge(b, a);
      l.path.setAttribute("d", linkPath(ax, ay, bx, by, l.style.curve));

      // Dim with whichever endpoint is dimmer, so `focus` carries to links.
      const vis = Math.min(a.alpha, b.alpha);
      l.path.setAttribute("opacity", (l.alpha * l.style.opacity * vis).toFixed(3));

      if (l.style.draw) {
        const len = l.path.getTotalLength();
        l.path.setAttribute("stroke-dasharray", len);
        l.path.setAttribute("stroke-dashoffset", (len * (1 - l.draw)).toFixed(1));
      } else if (l.style.dash) {
        l.path.setAttribute("stroke-dasharray", l.style.dash);
        l.path.setAttribute("stroke-dashoffset", (-this.phase * l.style.march).toFixed(2));
      }
    }

    for (const [key, n] of this.notes) {
      n.x += (n.tx - n.x) * k;
      n.y += (n.ty - n.y) * k;
      n.alpha += (n.talpha - n.alpha) * k;

      if (n.talpha === 0 && n.alpha < 0.02) {
        n.g.remove();
        this.notes.delete(key);
        continue;
      }

      n.g.setAttribute("transform", `translate(${n.x.toFixed(2)},${n.y.toFixed(2)})`);
      n.g.setAttribute("opacity", n.alpha.toFixed(3));
    }

    for (const f of this.flows) {
      f.t = (f.t + dt * f.speed) % 1;

      const len = f.link.path.getTotalLength();
      if (!len) continue;

      // A reversed flow runs back up the same path: a response, or an
      // acknowledgement. Offsetting it sideways keeps the two directions
      // legible as two streams instead of one jumble on a single line.
      // Piling bunches evenly-spaced particles toward the far end, so a stalled
      // hop reads as things arriving and not leaving.
      let phase = f.reverse ? 1 - f.t : f.t;
      if (f.pile) phase = 1 - (1 - phase) ** 3;

      const at = len * phase;
      const p = f.link.path.getPointAtLength(at);

      let { x, y } = p;
      if (f.offset) {
        const q = f.link.path.getPointAtLength(Math.min(len, at + 1));
        const dx = q.x - p.x;
        const dy = q.y - p.y;
        const d = Math.hypot(dx, dy) || 1;
        x += (-dy / d) * f.offset;
        y += (dx / d) * f.offset;
      }

      f.dot.setAttribute("cx", x.toFixed(1));
      f.dot.setAttribute("cy", y.toFixed(1));
      // Piled particles must stay lit where they bunch; the usual sine fade
      // would hide them exactly where the point is being made.
      const fade = f.pile ? Math.min(1, f.t * 5) : Math.sin(f.t * Math.PI);
      f.dot.setAttribute("opacity", (fade * f.link.alpha).toFixed(3));
    }

    requestAnimationFrame(this.tick);
  };
}
