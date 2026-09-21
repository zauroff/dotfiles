---
name: primer
description: Write a concise, well-designed HTML primer document that introduces a topic to a reader with adjacent experience. One self-contained .html file in a fixed editorial design (soft cream paper, neutral ink, one orange accent, Newsreader serif headings, IBM Plex Sans body, dark mode) with hand-written inline SVG for every diagram. Use whenever the user asks for a primer, reading material, an intro doc, a briefing, a cheat sheet, an overview page, a one-pager, or "something I can read before we begin" on any technical or non-technical topic.
---

# Primer

A primer is one HTML file a reader opens in a browser and reads top to bottom in
under 30 minutes. It exists so the reader arrives at a later conversation, lesson,
or project already holding the core facts. It is reading material, not a
reference manual and not a tutorial.

## Workflow

1. **Establish the reader.** The request usually names prior experience ("knows some background knowledge around this specific topic"). If it does not, ask once. Every section is written from what the
   reader already holds toward what they do not.
2. **Ask for the output path.** Always. Suggest `~/learning/<topic-slug>/00-primer/primer.html`
   in the question so a yes is one word.
3. **Verify facts before writing.** Version numbers, dates, names, formulas, and
   any claim the reader could act on. When unsure, confirm with the `Agent` tool
   (`subagent_type: researcher`). A primer with a wrong fact teaches the wrong fact.
4. **Copy `assets/template.html`** to the output path and fill it. The design is
   fixed and fully hard-coded in that file; nothing is fetched from anywhere but
   Google Fonts. `references/design.md` documents every value for when a primer
   needs an element the template lacks.
5. **Outline sections**, 8 to 14 of them, each one idea. Order them so every
   section depends only on sections above it. The contents card lists them.
6. **Write the sections.** Rules below.
7. **Add visuals** where structure or geometry carries the idea. Read
   `references/svg.md` before writing the first `<svg>`.
8. **Check the file**: open it once with `open <path>` on macOS. Confirm the
   three fonts load, every anchor in the contents card resolves, and every SVG
   reads in both light and dark mode (toggle system appearance, or set
   `data-theme="dark"` on `<html>`).
9. Report the path and a one-line list of the sections.

## Section rules

Each section has the same shape:

1. Motivate in one or two sentences. What problem or gap makes this idea
   necessary. A reader who does not know why a fact exists will not keep it.
2. State the idea plainly. Universal statements ("every value has one owner")
   and real definitions beat lists of typical properties.
3. Connect to what the reader already holds. Name the equivalent construct in
   the reader's home domain and the one difference that matters.
4. One example. Code goes in `<pre><code>` with the four highlight classes
   (`k` keyword, `t` type, `s` literal, `c` comment). Mark a failing line with
   `<span class="err">` inside its comment.

Put the one sentence the reader must keep in the callout (`<div class="rule">`)
with an eyebrow label: "Keep", "Rule", or "Definition". At most one per section.
If a section has no such sentence, it is two ideas or none; split it or cut it.

Length: 80 to 250 words of prose per section. The whole page is 1500 to 3500
words. Density comes from cutting words, never from cutting steps.

Standard closing sections, when they apply:

- A mapping table from the reader's home domain to the new one (three
  columns: theirs, ours, the difference).
- "Three beginner errors" with an `<h3>` per error and the fix.

## Voice

Flat declarative sentences. Present tense. Sentence case in every heading. No
exclamation marks, no emoji, no rhetorical questions, no analogies for flavor,
no sentences about the document itself ("in this section we will"). No praise,
no reassurance, no "simply". Every sentence carries a fact. The reader is
intelligent and short on time.

## Visuals

A visual earns its place only when it shows structure, flow, containment, or
geometry that a sentence cannot. Stack frames beside heap blocks, a pointer
into a buffer, a state machine, a dependency graph, a timeline. A diagram that
restates the adjacent sentence is noise and a chance to be wrong.

Every visual is inline `<svg>` inside `<figure><div class="mat">` with a
`<figcaption>`. Colors come from the page tokens via `var(--...)` so dark mode
holds. Never embed raster images. Never link external SVG files.

## Design

The template encodes the design. Do not restyle it per primer. Every primer is
the same publication:

- Paper `#f8f6f1`, ink `#1c1b18`, one orange (`--ember`) spent once per
  figure, dark mode under `prefers-color-scheme` and `[data-theme="dark"]`.
- Newsreader at weight 400 for headings, italic for `h3`. IBM Plex Sans for
  body at 19/30. IBM Plex Mono for code and eyebrow labels. Google Fonts.
- One 640px column. Borders, not shadows. No hero images, no cards in grids,
  no icons, no gradients, no Title Case, no bold serif.
- Components: eyebrow, contents card, callout, code block with four highlight
  classes, table with line rules, figure on a sunken mat.

If the user asks for a different look, say the design is fixed and offer to
add a second template rather than restyling this one.

## Output

One file. No build step, no JavaScript unless a visual needs interaction the
user asked for, no external CSS. The file opens from disk with `open` and
from any static server with no configuration.
