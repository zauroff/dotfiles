# Authoring

How the deck actually works, and how to place things without fighting it.

## The engine, in one paragraph

Each scene declares its complete visible state. The engine diffs the current
scene against the next one and eases every value toward the new target:
entering nodes fade and scale in, leaving nodes fade out, surviving nodes glide
to their new position. There are no tween objects and no animation lifecycle.
One `requestAnimationFrame` loop owns a small mutable model, and a scene change
only retargets it.

Two consequences follow, and both matter when presenting:

- **Scenes are order-independent.** Jumping from scene 1 to scene 6 animates
  correctly, because scene 6 is a description and not a sequence of commands.
- **Interrupting a transition is safe.** Pressing right twice quickly retargets
  mid-flight instead of queueing or tearing.

## Layouts

A layout is a named set of positions in `LAYOUTS` in `js/model.js`. A scene
picks one by name. Every node the scene shows must have an entry in it, or the
engine throws and `check.js` fails.

```js
export const LAYOUTS = {
  empty: {},                        // a cover or a closing field
  fleet: {
    lb: [520, 300],                 // absolute, in viewBox units
    client: orbit("lb", 335, 197.4), // r and degrees from another node
    "app-a": [900, 150],
  },
};
```

`orbit(of, r, a)` places a node relative to another, by radius and angle in
degrees. 0 is to the right, 90 is down. The anchor must have an absolute
position; orbits do not chain. Use it for anything that belongs to a node, so
moving the anchor carries its satellites along and you only retune one number.

Positions are hand-typed on purpose. A force simulation gives a different
picture on every load, drifts labels under each other, and cannot be relied on
in front of a room.

### Where you may put things

The viewBox is `1280 x 780`. Fixed HTML chrome sits on top of it:

| Region                          | Occupied by        |
| ------------------------------- | ------------------ |
| `x < 415` and `y >` the card top | narration card     |
| `x > 1090` and `y > 668`        | transport controls |
| `x > 1160`                      | scene rail         |
| a 60px border on all four sides | frame margin       |

The narration card is bottom-anchored and grows **upward** with its copy, so
its top edge differs per scene. As a working rule: keep anything left of
`x = 415` above `y = 340`, and keep everything inside `x [60, 1160]`,
`y [60, 720]`. `check.js` computes the real card top per scene and tells you
when you are wrong.

Node labels hang below the centre, so a node is checked at `y + 60`, not at
`y`. A node at `y = 300` is tested as if it reached `y = 360`.

## Scene files

`js/scenes/index.js` assembles acts into the single ordered list the engine
steps through, and stamps each scene with its act so the masthead and rail can
group them.

```js
export const DECK = { mark: "Request", title: "Request: the life of one HTTP call" };

export const ACTS = [
  { numeral: "I", label: "The path of one request", scenes: ACT1 },
  { numeral: "II", label: "Under load", scenes: ACT2 },
];
```

`DECK.mark` is the wordmark: it appears in the masthead and, much larger, on
any cover scene. `DECK.title` is the browser tab. `numeral` is the heading
drawn above that act's scenes in the rail; leave it empty to run the scenes on
with no heading.

Put repeated node lists and link bundles in `js/scenes/common.js`. Scenes
declare complete state, which makes later scenes repetitive otherwise: the
system is the same in all of them. A scene should list what it is **about**,
spread over a bundle that carries the rest.

## URL flags

| Flag            | Effect                                                                 |
| --------------- | ---------------------------------------------------------------------- |
| `#<scene-id>`   | open directly on that scene. Useful for jumping mid-talk                |
| `?static`       | skip all animation, render each scene's final state immediately         |
| `?ghosts=small` | draw background participants as small dots instead of full-size shapes  |

`?static` is required for screenshots. Headless Chrome runs too few animation
frames to ever settle, so a normal capture catches the diagram mid-transition
at the wrong size. The same path is taken automatically when the OS is set to
reduce motion. It also switches off the CSS entrance animations on the cover
and the narration, which otherwise get caught mid-fade.

Combine them: `?static#saturation`, `?static&ghosts=small#fleet`.

## Reading check.js

`node check.js` from the deck directory. Exit 0 or fix it. Every failure names
the scene above it.

| Failure                                       | What to do                                                       |
| --------------------------------------------- | ---------------------------------------------------------------- |
| `X is not in ENTITIES`                        | typo in the scene's `nodes`, or the entity was never declared     |
| `X has no position in layout "Y"`             | add X to that layout, or the scene picked the wrong layout        |
| `link A->B: A is not on stage`                | a link endpoint is missing from `nodes`                           |
| `link A->B has unknown kind "k"`              | typo, or a new kind that is not in `LINK_KINDS` yet               |
| `flow A->B (k) has no matching link`          | particles need a link to travel along. Add it to `links`          |
| `A and B are 62px apart, need 90`             | move one. The number is centre to centre, allowing for both shapes |
| `X at 200,480 sits under the narration card`  | move X right of x=415, up above the card, or shorten the copy     |
| `X at 30,900 is outside the safe area`        | inside `x [60, 1220]`, `y [60, 720]`                              |
| `note "..." overlaps Y`                       | notes are hand-placed with nothing anchoring them. Move the note  |
| `title is 61 chars, over the 52 ...`          | shorten the title                                                 |
| `narration (740 chars) pushes the card up ...`| cut the copy, or the card starts eating the diagram               |
| `small ghost at 68,300 is 71px from app-a`    | a background position collides with a foreground node in this scene. Move the node, or edit `GHOST_SETS` |

The card-height model is fitted, not measured live: the constants in `CARD`
come from three measured scenes (396/466/529 characters producing 350/348/423
pixels of height) and predict the rest to within a few pixels. Do not tune them
to make one scene pass. Shorten the copy instead.

Ghosts are checked for **both** treatments, whichever is currently the default,
because each set shares one position list across every scene that shows it.

## Extending

### A new link kind

Two files, and they must agree.

```js
// js/engine.js, in LINK_STYLE
myKind: { color: COLOR.primary, width: 1.4, opacity: 0.6, curve: 20, dash: "4 5", march: 10 },

// check.js, in LINK_KINDS
"myKind",
```

- `color: null` takes the accent of the node the link points at.
- `curve` is a perpendicular bow in user units; the sign picks the side. Give
  two kinds between the same pair opposite signs so they never merge.
- `draw: true` animates the line drawing itself in, once. Mutually exclusive
  with `dash` in practice: draw-in uses the dash array for its own purposes.
- `march` moves the dashes. Negative runs them backward.

Before adding one, check whether an existing kind already carries the meaning.
Twelve is already more than a room can learn in one talk.

### A new node state

One file. `STATES` in `js/model.js`:

```js
draining: { color: "--warn", label: "draining", dash: "3 4" },
```

`color` is the **name** of a CSS custom property, resolved at load. `label` is
drawn in caps above the ring. `dash` is optional; a solid ring reads as more
definite than a dashed one.

### A new node kind

Rarely worth it. It means a builder function in `js/engine.js`, an entry in
`BUILDERS`, a radius in `RADIUS`, and a branch in `halfExtent` in `check.js` if
it is not round. Five shapes is already at the edge of what a room can hold.
Prefer an accent or a state.

### Retheming

Edit the tokens in the `:root` block of `styles.css`. Nothing below `:root`
hard-codes a palette colour: remaining literals are neutral greys, or are
derived from a token with `color-mix`. Two places outside that block track
`--primary` by hand and need the same edit: the `#vignette` gradient stop in
`index.html`, which is noted in a comment there.

## Common mistakes

- **Writing a scene per fact instead of a scene per change.** If the diagram
  looks the same as the previous scene, merge them.
- **Adding colour to show importance.** Use `focus` to dim everything else.
- **Letting the narration describe the picture.** The picture already did that.
  Use the words for the reason, the consequence, or the thing that is easy to
  get wrong.
- **Placing a note by eye and not rerunning `check.js`.** Notes have no anchor
  and drift into nodes more than anything else in the system.
- **Tuning the card constants to fit long copy.** Shorten the copy.
