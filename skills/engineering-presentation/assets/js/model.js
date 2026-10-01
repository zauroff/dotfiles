/**
 * Entity catalogue, layout states, accents, node states, background fields.
 *
 * This is one of the two things a deck author edits. The other is js/scenes/.
 * Everything in js/engine.js, js/main.js and check.js is plumbing.
 *
 * Positions are hand-placed rather than force-simulated: a deck has to look
 * identical every time it is presented. Satellites are placed with `orbit`,
 * relative to the node they belong to, so moving an anchor carries them along.
 */

export const KIND = {
  /** Circle. The main participants: the things the story is about. */
  NODE: "node",
  /** Hexagon. A coordinator or decision point. `primary: true` lights it. */
  HUB: "hub",
  /** Small ring. An attached or external thing, tinted by its `accent`. */
  LEAF: "leaf",
  /** Lined slab. Storage, or anything a reader should read as "the data". */
  STORE: "store",
  /** Labelled rectangle. A stage, a step, a definition: work, not a machine. */
  BOX: "box",
};

/** Hit radius used to trim link endpoints back to the node boundary. */
export const RADIUS = {
  [KIND.NODE]: 33,
  [KIND.HUB]: 29,
  [KIND.LEAF]: 19,
  [KIND.STORE]: 36,
  [KIND.BOX]: 26,
};

/** BOX footprint, in user units. */
export const BOX_SIZE = { w: 156, h: 34 };

/**
 * Accent names a LEAF may carry, each mapped to a CSS custom property in
 * styles.css. Rename the keys to whatever the deck distinguishes between.
 * Three accents is the ceiling: a fourth stops reading as a category.
 */
export const ACCENTS = {
  edge: "--accent-1",
  memory: "--accent-2",
  external: "--accent-3",
};

/**
 * Per-scene node states: a coloured ring plus a micro-label, layered over
 * whatever the node already is. `color` is a CSS custom property name.
 * Add states here; the engine reads this map.
 */
export const STATES = {
  pending: { color: "--secondary", label: "pending", dash: "3 4" },
  active: { color: "--primary", label: "active" },
  ok: { color: "--accent-1", label: "ok" },
  warn: { color: "--warn", label: "degraded", dash: "3 4" },
  bad: { color: "--accent-3", label: "failed" },
  down: { color: "--accent-3", label: "unreachable", dash: "2 5" },
};

/* ------------------------------------------------------------ the example deck
   Everything below this line is the worked example. Replace it. */

export const ENTITIES = {
  lb: { kind: KIND.HUB, label: "balancer", primary: true },
  client: { kind: KIND.LEAF, label: "browser", accent: "edge" },

  "app-a": { kind: KIND.NODE, label: "app-1" },
  "app-b": { kind: KIND.NODE, label: "app-2" },
  "app-c": { kind: KIND.NODE, label: "app-3" },

  cache: { kind: KIND.LEAF, label: "cache", accent: "memory" },
  db: { kind: KIND.STORE, label: "database" },

  "stage-parse": { kind: KIND.BOX, label: "Parse", sub: "decode · validate" },
  "stage-auth": { kind: KIND.BOX, label: "Authorize", sub: "token · scopes" },
  "stage-render": { kind: KIND.BOX, label: "Render", sub: "compose · encode" },
};

/**
 * Horizontal nudge for a node's meter, in user units. Use it when a meter
 * would land on a link leaving that node.
 */
export const METER_OFFSET = { "app-b": 40, "app-c": 55 };

/** Which server each stage is bound to once the request is in flight. */
export const STAGE_HOST = {
  "stage-parse": "app-a",
  "stage-auth": "app-b",
  "stage-render": "app-c",
};

const orbit = (of, r, a) => ({ of, r, a });

/**
 * Named layout states. A scene picks one; every node visible in that scene
 * must have an entry. Entries are either [x, y] or an orbit descriptor.
 *
 * The viewBox is 1280x780. Keep positions inside x [60, 1160] and y [60, 720],
 * and keep anything left of x=415 above y=340: the narration card lives there.
 * `node check.js` enforces all of this.
 */
export const LAYOUTS = {
  /** A cover or a closing field has no foreground nodes at all. */
  empty: {},

  fleet: {
    lb: [520, 300],
    client: orbit("lb", 335, 197.4),
    "app-a": [900, 150],
    "app-b": [940, 330],
    "app-c": [900, 510],
  },

  /** The chain on its own, with nothing to say where it runs. */
  chain: {
    "stage-parse": [330, 300],
    "stage-auth": [640, 300],
    "stage-render": [950, 300],
  },

  /**
   * The chain bound to the fleet. Each stage sits directly above the server
   * running it, so the binding needs no arrowheads to be readable.
   */
  bound: {
    lb: [110, 130],
    client: [110, 280],
    "stage-parse": [480, 200],
    "stage-auth": [790, 200],
    "stage-render": [1060, 120],
    "app-a": [480, 330],
    "app-b": [790, 330],
    "app-c": [1060, 250],
    cache: orbit("app-b", 220, 105),
    db: [1010, 540],
  },
};

/**
 * Background participants, drawn faint and unlabelled to convey that the real
 * system holds far more than the story shows. Shared across every scene that
 * sets `ghosts: true`, so they read as a stable backdrop while the foreground
 * rearranges.
 *
 * Two treatments, selected with `?ghosts=`:
 *
 *   small - dots at a fraction of node size, tucked into the gaps. Reads as
 *           depth; never competes with the foreground.
 *   full  - identical geometry to a real NODE. Unmistakably "the same kind of
 *           thing, just more of them", but at that size there is nowhere to put
 *           thirteen, so there are fewer and they run off the edges.
 *
 * `link` is the distance within which two ghosts get a thread between them.
 * `clip: true` means positions outside the safe area are intentional.
 */
export const GHOST_SETS = {
  small: {
    r: 9,
    link: 135,
    clip: false,
    positions: [
      [128, 132],
      [68, 168],
      [68, 300],
      [300, 86],
      [330, 210],
      [1016, 102],
      [1064, 88],
      [1142, 96],
      [974, 688],
      [1058, 636],
      [894, 702],
      [520, 692],
      [492, 640],
    ],
  },

  full: {
    r: 33,
    link: 260,
    clip: true,
    positions: [
      [52, 96],
      [26, 268],
      [30, 396],
      [268, 26],
      [520, 22],
      [1244, 150],
      [1256, 356],
      [1238, 548],
      [980, 700],
      [520, 706],
    ],
  },
};

/** Furthest a ghost will reach to draw a thread to a real NODE. */
export const GHOST_REACH = 480;

/**
 * The closing field: far more participants than the story used, filling the
 * frame. A jittered grid rather than random points, so coverage is even and,
 * because the jitter is derived from the index, identical on every run.
 */
export const SWARM = (() => {
  const cols = 10;
  const rows = 7;
  const points = [];

  const jitter = (n, salt) => {
    const v = Math.sin(n * salt) * 43758.5453;
    return (((v % 1) + 1) % 1) - 0.5;
  };

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const i = r * cols + c;
      const x = 40 + c * 133 + jitter(i + 1, 12.9898) * 74;
      const y = 70 + r * 108 + jitter(i + 1, 78.233) * 58;

      // Leave the masthead and the narration card alone: a faint circle behind
      // running text is the one thing in this scene anyone would read as a
      // mistake.
      const behindMasthead = x < 430 && y < 78;
      const behindNarration = x < 430 && y > 520;
      if (behindMasthead || behindNarration) continue;

      points.push([x, y]);
    }
  }

  return points;
})();

export const SWARM_LINK = 150;

/** Resolve a layout state to flat {id: [x, y]}, expanding orbit descriptors. */
export function resolveLayout(name) {
  const spec = LAYOUTS[name];
  if (!spec) throw new Error(`unknown layout: ${name}`);

  const out = {};

  for (const [id, v] of Object.entries(spec)) {
    if (Array.isArray(v)) out[id] = v;
  }

  for (const [id, v] of Object.entries(spec)) {
    if (Array.isArray(v)) continue;

    const anchor = out[v.of];
    if (!anchor) throw new Error(`${id} orbits ${v.of}, which has no absolute position`);

    const rad = (v.a * Math.PI) / 180;
    out[id] = [anchor[0] + Math.cos(rad) * v.r, anchor[1] + Math.sin(rad) * v.r];
  }

  return out;
}
