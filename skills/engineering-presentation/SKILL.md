---
name: engineering-presentation
description: >-
  Build an animated, scene-based SVG presentation that explains a technical
  topic as a self-contained browser deck. Use for presentations, slides,
  technical talks, walkthroughs, architecture overviews, animated diagrams,
  system diagrams that move, or requests to explain something visually. This
  produces static browser files, not a .pptx; say so before starting, and use a
  PowerPoint workflow instead when the user needs a real PowerPoint file.
---

# Engineering presentation

A deck is one directory of static files. No build step, no dependencies, no
package to install. The presenter opens `index.html` in a browser, goes full
screen, and steps through with the arrow keys. Every scene is a state of one
SVG diagram, and moving between scenes animates the difference.

It is for explaining a system to a room: how it is put together, what moves
through it, what happens when part of it fails. It is not a document, not a
reference, and not a slide deck of bullet points.

## Output

```
<deck>/
  index.html         shell: SVG root, narration card, transport, scene rail
  styles.css         the entire visual language, tokenised in :root
  package.json       "type": "module", so `node check.js` runs. No deps.
  serve.py           static server with caching switched off
  check.js           validates scenes against layouts
  js/
    model.js         YOU EDIT: entities, layouts, accents, states
    engine.js        plumbing: diff, ease, render loop
    main.js          plumbing: playback, controls, rail
    scenes/
      index.js       YOU EDIT: deck name, acts, ordering
      common.js      YOU EDIT: reusable node and link bundles
      act1.js        YOU EDIT: the scenes themselves
```

Controls: `->` / `space` next, `<-` back, `p` autoplay, `Home` / `End` ends,
click the rail to jump. The scene id is written to the URL hash, so any scene
is directly linkable for jumping mid-talk.

## Workflow

1. **Establish the topic and the audience.** What system, and what does the
   room already know. A deck aimed at people who have never heard of the thing
   is a different deck from one aimed at its maintainers. If the request does
   not say, ask once.

2. **Ask for the output path.** Always, and only once. Suggest a concrete
   default in the question so a yes is one word, for example
   `~/presentations/<topic-slug>/`.

3. **Write the narrative first, before touching any layout.** Produce a plain
   list: acts, and inside each act the scenes, one line each saying what that
   scene adds. Get this agreed before writing code. Layout work on a narrative
   that later changes is wasted twice.

4. **Copy the scaffold.** `cp -R <skill>/assets/ <path>/`, then
   `chmod +x <path>/serve.py`.

5. **Fill `js/model.js` first.** Entities, then accents, then one named layout
   per arrangement the story needs. Positions are hand-typed. Read
   `references/authoring.md` before placing the first one.

6. **Then write the scenes.** Bundles that repeat go in `js/scenes/common.js`.
   Set `DECK.mark` and `DECK.title` in `js/scenes/index.js`.

7. **Run `node check.js` after every edit.** It must exit 0. It catches what
   fails silently in a browser: a node with no position, a link to something
   not on stage, two nodes on top of each other, a node hidden behind the
   narration card.

8. **Look at it.** `./serve.py` then `http://localhost:8000`. For a headless
   check, screenshot `?static#<scene-id>` and read the image back.

## The scene object

Every scene declares its **complete** visible state. It is a description, not a
list of commands. Only `id`, `rail`, `layout` and `nodes` are required.

```js
{
  id: "saturation",          // URL hash, and the name check.js reports under
  rail: "Saturation",        // short label in the right-hand scene rail
  layout: "bound",           // a key of LAYOUTS in model.js
  title: "A backlog names the wrong layer",   // under 52 chars
  text: `Prose. <strong>Bold</strong>, <code>code</code> and
         <br /><br /> for a paragraph break are the only markup used.`,

  nodes: ["app-a", "app-b"],           // everything visible. Anything absent leaves.
  links: [["app-a", "app-b", "pipe"]], // [from, to, kind]

  // all optional
  cover: `Lead paragraph.`,     // makes this a title card: hides the narration
  compact: true,                // hide every BOX detail line this scene
  ghosts: true,                 // fade in the background field
  swarm: true,                  // fade in the dense closing field
  focus: ["app-a"],             // everything else drops to 22% opacity
  chips: { "app-a": ["line one", "line two"] },
  halo: { "app-a": "badge text" },
  states: { "app-b": "down" },  // a key of STATES in model.js
  meters: { "app-a": { total: 8, done: 1, tone: "crit", unit: "queued" } },
  flow: [["app-a", "app-b", "pipe", { count: 3, speed: 0.45 }]],
  notes: [{ x: 520, y: 84, align: "start", lines: ["two lines", "at most"] }],
  stats: [{ value: "billions", label: "requests a day" }],
}
```

Every `flow` entry needs a matching entry in `links`: particles travel along a
link, so the link has to exist. `check.js` enforces it.

## Narrative rules

- **One idea per scene.** If the narration needs the word "also", split it.
- **Each scene changes the one before it.** Add a participant, move one, light
  one up, break one. A scene that changes nothing is a paragraph, not a scene.
- **Scene titles under 52 characters.** Under 28 keeps it to one line and buys
  the diagram more room.
- **Narration: two short paragraphs.** The card is bottom-anchored and grows
  upward, so long copy eats the diagram. `check.js` fails the scene when the
  card would climb above y=330.
- **The diagram carries the structure; the narration carries the reason.** Do
  not write out in prose what the picture already shows.
- **End with something that pulls back.** The `swarm` plus `stats` scene exists
  for exactly this.

## What you edit

`js/model.js` and `js/scenes/*`. Nothing else.

`js/engine.js`, `js/main.js` and `check.js` are plumbing. Two exceptions,
both documented in `references/authoring.md`: adding a link kind means adding
it to `LINK_STYLE` in `engine.js` and to `LINK_KINDS` in `check.js`, and
retheming means editing the tokens in the `:root` block of `styles.css`.

If the user asks for a different look, offer to retheme through the tokens. Do
not restyle the components.

## Verification

Both steps, every time, before reporting the deck done.

1. `node check.js` exits 0. A non-zero exit is a layout that is broken in a way
   the browser will not tell you about.
2. Screenshot and **look at it**. Headless Chrome runs too few animation frames
   to settle, so `?static` is required or the capture catches the diagram
   mid-transition at the wrong size:

```bash
./serve.py 8777 &
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --virtual-time-budget=6000 \
  --window-size=1600,980 --screenshot=/tmp/scene.png \
  'http://localhost:8777/?static#<scene-id>'
```

Read the PNG back. Confirm the diagram is inside the frame, nothing sits under
the narration card, labels do not collide, and the colour encoding says what
the narration says.

## References

- `references/visual-language.md`: what every shape, colour, line and overlay
  means. Read it before inventing an encoding.
- `references/authoring.md`: layouts, `orbit`, how the diff engine works, the
  URL flags, reading `check.js` failures, adding a link kind or a node state.
