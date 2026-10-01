# Visual language

The deck is one drawing that changes. Every mark on it means something, and it
means the same thing in every scene. Read this before inventing an encoding.

## The grammar

| Channel    | Encoding                                                                    |
| ---------- | --------------------------------------------------------------------------- |
| Shape      | circle = NODE · hexagon = HUB · small ring = LEAF · lined slab = STORE · rectangle = BOX |
| Colour     | cyan = the main participants · amber = coordinators and control traffic · accent = a LEAF's category |
| Line style | solid = a real connection · dashed and marching = chatter or control traffic |
| Glow       | the lit hexagon is the primary hub                                          |
| Particles  | one dot = one unit of work, in the colour of whatever it is travelling to    |
| Meter      | filled tick = outstanding · hollow tick = done                              |
| Dimming    | anything outside a scene's `focus` set drops to 22% opacity                 |

Two rules hold the whole thing together:

1. **A reader learns each encoding once.** If cyan means "main participant" in
   scene 2 it cannot mean "healthy" in scene 5. Use a state ring for health.
2. **Shape is for kind, colour is for role.** Never encode the same fact twice.

## Node kinds

Set in `js/model.js` under `KIND`, one per entity.

| Kind    | Drawn as                                       | Radius | Use for                                       |
| ------- | ---------------------------------------------- | ------ | --------------------------------------------- |
| `NODE`  | double circle with a lit core, cyan            | 33     | the main participants: the things the story is about |
| `HUB`   | double hexagon, amber; `primary: true` adds a beacon ring, a glow filter and a bigger core | 29 | a coordinator, a router, a decision point |
| `LEAF`  | small double ring in its accent colour, with the accent name as a badge | 19 | an attached or external thing hanging off a NODE |
| `STORE` | slab with three rules across it, neutral grey  | 36     | storage, or anything a reader should read as "the data" |
| `BOX`   | 156x34 rectangle with a label and an optional detail line | 26 | work, not a machine: a stage, a step, a definition |

Entity fields: `label` (required), `accent` (LEAF only, a key of `ACCENTS`),
`primary` (HUB only), `sub` (NODE, STORE and BOX: a second smaller line).

`compact: true` on a scene hides every BOX detail line. Use it once boxes sit
close to other things and the extra line would collide.

## Link kinds

Set per link as the third element: `[from, to, kind]`. Defined in `LINK_STYLE`
in `js/engine.js`, listed again in `LINK_KINDS` in `check.js`.

| Kind        | Spec                                            | Means                                                    |
| ----------- | ----------------------------------------------- | -------------------------------------------------------- |
| `solid`     | straight, draws itself in, takes the target's colour | a plain real connection between two things            |
| `mesh`      | cyan, bowed +30, fine dashes marching forward   | peer chatter: membership, health, replication. Not payload |
| `bond`      | amber, bowed +26, draws itself in               | a standing relationship between coordinators             |
| `signal`    | amber, bowed +20, dashes marching backward      | control traffic going out from a coordinator             |
| `feed`      | neutral, straight, dashes marching forward      | a poll or a subscription against a store                 |
| `edge`      | dim grey, straight, draws itself in             | the abstract graph itself, independent of where it runs  |
| `candidate` | faint, bowed +14, marching                      | could run there: one of several options, none chosen     |
| `propose`   | amber, bowed **-26**, marching backward         | a proposal travelling a tree. Bows opposite `mesh` so two lines between the same pair never merge |
| `pending`   | faint, straight, static dashes                  | proposed but not agreed                                  |
| `bound`     | cyan, straight, static dashes, low opacity      | agreed: this work runs here                              |
| `pipe`      | cyan, thick, bowed +34, draws itself in         | the live path payload actually travels                   |
| `broken`    | red, thick, bowed +34, static dashes            | the same path, severed. Draw it over the pipe's route so the break is in place |

`color: null` in a spec means the link takes the accent of the node it points
**at**. That is what makes `solid` read as "a connection to that kind of thing".

## Overlays

Per-scene decoration on a node. All optional, all keyed by node id.

- **`chips`** `{ id: ["line", "line"] }`. Small monospace lines under a node in
  the node's own accent colour, with a tick mark above them. For a version, a
  count, a configuration. Two lines is the practical ceiling.
- **`halo`** `{ id: "badge text" }`. A dashed inner ring plus a caps badge
  above the node. For a property the node has that has no other place to live.
- **`states`** `{ id: "statename" }`. A coloured ring around the node plus a
  caps micro-label above it. The set lives in `STATES` in `js/model.js`:
  `pending`, `active`, `ok`, `warn`, `bad`, `down`. Add your own there.
- **`meters`** `{ id: { total, done, tone, unit } }`. A row of ticks under the
  node with a caption. Filled ticks are outstanding, hollow are done. `tone` is
  `warn` or `crit` and recolours the whole meter. The caption reads
  `"<n> <unit>"`, or `"clear"` when nothing is outstanding. Nudge one sideways
  with `METER_OFFSET` in `model.js` when it lands on a link.
- **`flow`** `[[from, to, kind, opts]]`. Particles along an existing link.
  `count`, `speed`, `reverse` (run back up the same path), `offset` (push
  sideways, so a request and its answer read as two streams on one line),
  `pile` (bunch particles at the far end, so a stalled hop reads as things
  arriving and not leaving).
- **`notes`** `[{ x, y, align, lines }]`. Hand-placed annotation with a small
  rule above it. `align` is `start`, `middle` or `end`. Two lines maximum.
- **`focus`** `[id, ...]`. Everything not named drops to 22% opacity, links
  included. Use it to push a whole subsystem into the background while the
  narration talks about the rest.
- **`stats`** `[{ value, label }]`. Large serif figures centred on the canvas,
  for a closing scene only.

## Backgrounds

- **`ghosts: true`** fades in a fixed field of faint unlabelled participants,
  each threaded to its neighbours and reaching toward the nearest live NODE.
  It says "there are more of these than the story shows". Positions live in
  `GHOST_SETS` in `model.js` and are shared by every scene that uses them,
  which is how one drifts under a foreground node unnoticed. `check.js` checks
  both treatments against every scene that turns them on.
- **`swarm: true`** fades in a much denser jittered grid with traffic running
  on it, and no reach lines. For the closing scene, where there is no
  foreground left to reach.

## Palette

Tokens in the `:root` block of `styles.css`. Retheme by editing these. Nothing
below `:root` hard-codes a palette colour.

| Token         | Value     | Used for                              |
| ------------- | --------- | ------------------------------------- |
| `--bg`        | `#07080c` | the field                             |
| `--bg-lift`   | `#0c0e14` | node fills, so links pass behind them |
| `--ink`       | `#e8ecf4` | primary text                          |
| `--ink-dim`   | `#8b93a7` | narration body, secondary labels      |
| `--ink-faint` | `#4d5468` | annotations, disabled chrome          |
| `--primary`   | `#45c9e8` | NODE, and the live path               |
| `--secondary` | `#f0a830` | HUB, and control traffic              |
| `--neutral`   | `#9aa4bb` | STORE, and anything uncategorised     |
| `--accent-1`  | `#5ee6a8` | a LEAF category                       |
| `--accent-2`  | `#b99cff` | a LEAF category                       |
| `--accent-3`  | `#ff8a7a` | a LEAF category, and `broken`         |
| `--warn`      | `#f2c14e` | meter severity                        |
| `--crit`      | `#ff7a6b` | meter severity                        |

Three accents is the ceiling. A fourth stops reading as a category and starts
reading as decoration.

Red and amber appear only on meters, states and `broken`. A meter reads as a
meter, so a severity scale is safe there. Anywhere else, red would compete
with the encoding.

## Typography

- **Instrument Serif** for scene titles, the scene number, act headings in the
  rail, the cover lead, and the closing figures. It is the only serif, and it
  is the only thing on screen that is allowed to be large.
- **IBM Plex Mono** for everything else: node labels, badges, chips, notes,
  narration body, chrome. Uppercase with wide tracking for labels and badges,
  sentence case at 12.5px for the narration.
- Both load from Google Fonts with a system serif and mono fallback. Drop the
  `<link>` tags in `index.html` and self-host the woff2 files to remove the
  dependency.

## What holds the aesthetic together

The look is an engineering instrument, not a slide theme. Five things carry it,
and dropping any one of them is what makes a deck start to look generic.

1. **Hand-placed positions, never a force simulation.** A talk has to look
   identical every time it is given. Physics gives a different picture on every
   load and drifts under labels.
2. **A dark field with a hairline grid and a vignette.** The grid is barely
   visible on purpose: it establishes that the surface is a drawing surface.
3. **Registration marks in the four corners.** Technical-drawing furniture. It
   frames the canvas without a border.
4. **Monospace readouts.** Every number, label and badge is monospace and
   tracked wide. This is what makes the diagram read as an instrument rather
   than an illustration.
5. **One idea lit at a time.** Use `focus` and dimming rather than adding more
   colour. A diagram where everything is bright says nothing.
