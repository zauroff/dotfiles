# Inline SVG for primers

Every figure is hand-written SVG inside the HTML. No external files, no raster,
no diagram libraries. Hand-written SVG is chosen because the author controls
every coordinate, the file stays self-contained, and page color tokens flow in
through `var(--...)` so the figure follows light and dark mode with no extra
work.

The design brief for imagery: diagrams drawn in ink and ember on paper, sitting
on a paper-sunken mat with a line border. No shadows, no gradients.

## Skeleton

```html
<figure>
<div class="mat">
<svg viewBox="0 0 592 220" role="img" aria-label="Stack frame for main beside a heap block it points to">
  ...
</svg>
</div>
<figcaption>The stack frame holds three words. The bytes live on the heap.</figcaption>
</figure>
```

- `viewBox` width 592 always. That is the 640px measure minus the mat's
  24px padding on each side, so 1 unit is 1px on desktop. Height is whatever
  the drawing needs, usually 140 to 300.
- `role="img"` and `aria-label` on every SVG. The label is the same sentence
  as the caption or shorter.
- No `width` or `height` attributes on `<svg>`. The CSS sets them.

## Colors

Use only these fills and strokes. They are the page tokens.

| Purpose | Value |
|---|---|
| Box fill | `var(--paper-raised)` |
| Box border, structure lines | `var(--line)`, 1px |
| Arrows and connectors | `var(--ink-muted)`, 1.5px |
| The one emphasised box | fill `var(--ember-soft)`, stroke `var(--ember)` |
| The one emphasised arrow | `var(--ember)` |
| Primary labels | `var(--ink)` |
| Secondary labels, region names | `var(--ink-muted)` |
| Freed, dead, or invalid element | `var(--ink-muted)` stroke with `stroke-dasharray="4 3"` |
| Error or rejected mark | `var(--ember-text)` |
| Valid or current status | `var(--moss)`, text or a 6px dot beside a word, never a fill |

Never hard-code a hex color in a figure. A hard-coded color breaks in dark
mode. Ember is spent once per figure.

## Text

- Primary labels: `font-size="14"`, `fill="var(--ink)"`.
- Secondary labels: `font-size="12"`, `fill="var(--ink-muted)"`.
- Region names (STACK, HEAP, THREAD 1): `font-size="12"`, `class="mono"`,
  `letter-spacing="0.08em"`, uppercase, `fill="var(--ink-muted)"`. This is the
  eyebrow style.
- Identifiers, addresses, code: `class="mono"`.
- Center a label in a box with `text-anchor="middle"` at the box center x and
  `y` = box center + 5 for a 14px font.
- Keep every label under 24 characters.

## Arrows

Define one marker per SVG and reuse it. Put it first inside the SVG.

```html
<defs>
  <marker id="a1" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0,0 L10,5 L0,10 z" fill="var(--ink-muted)"/>
  </marker>
</defs>
<line x1="220" y1="70" x2="380" y2="70" stroke="var(--ink-muted)" stroke-width="1.5" marker-end="url(#a1)"/>
```

Marker ids must be unique across the whole page. Two figures with `id="a1"`
collide, and the second figure's arrows render with the first figure's marker
color. Suffix the id with the figure number: `a1`, `a2`, and so on. An ember
arrow needs its own marker with `fill="var(--ember)"`.

## Standard shapes

Box with label:

```html
<rect x="20" y="20" width="180" height="56" rx="12" fill="var(--paper-raised)" stroke="var(--line)" stroke-width="1"/>
<text x="110" y="53" text-anchor="middle" font-size="14" fill="var(--ink)">owner: s</text>
```

Region name above a group:

```html
<text x="20" y="12" font-size="12" class="mono" letter-spacing="0.08em" fill="var(--ink-muted)">STACK</text>
```

Stacked cells (fields, header words, array slots): one `rect` per cell, same x,
height 28, y stepping by 28, `rx="0"`, shared 1px `--line` border. Label each
cell with a `text` at y + 19. Round only the outer corners if at all.

Dead or freed element: same box, `stroke-dasharray="4 3"`,
`stroke="var(--ink-muted)"`, label in `var(--ink-muted)`.

Rejected element: `stroke="var(--ember-text)"` and a small mono label in
`var(--ember-text)` next to it, for example the compiler error code.

## Composition rules

- One idea per figure. If the caption needs two sentences, split the figure.
- Six or fewer boxes.
- Left to right for time or data flow. Top to bottom for containment or call
  depth.
- Align box edges on an 8-unit grid. Prefer 16 and 24 for gaps.
- Leave 16 units of margin inside the viewBox on every side. The mat adds 24px.
- Box corners `rx="12"` for standalone boxes, `rx="0"` for cells in a stack.
- Test by opening the file with `data-theme="dark"` on `<html>`. Every stroke
  and label must stay visible.

## Worked example: a String on the stack pointing at heap bytes

```html
<figure>
<div class="mat">
<svg viewBox="0 0 592 120" role="img" aria-label="Stack frame with ptr, len, cap words pointing at five heap bytes">
  <defs>
    <marker id="a3" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill="var(--ember)"/>
    </marker>
  </defs>
  <text x="16" y="14" font-size="12" class="mono" letter-spacing="0.08em" fill="var(--ink-muted)">STACK</text>
  <rect x="16" y="24" width="160" height="28" fill="var(--paper-raised)" stroke="var(--line)" stroke-width="1"/>
  <rect x="16" y="52" width="160" height="28" fill="var(--paper-raised)" stroke="var(--line)" stroke-width="1"/>
  <rect x="16" y="80" width="160" height="28" fill="var(--paper-raised)" stroke="var(--line)" stroke-width="1"/>
  <text x="28" y="43" font-size="14" class="mono" fill="var(--ink)">ptr</text>
  <text x="28" y="71" font-size="14" class="mono" fill="var(--ink)">len  5</text>
  <text x="28" y="99" font-size="14" class="mono" fill="var(--ink)">cap  5</text>

  <text x="336" y="14" font-size="12" class="mono" letter-spacing="0.08em" fill="var(--ink-muted)">HEAP</text>
  <rect x="336" y="24" width="40" height="28" fill="var(--ember-soft)" stroke="var(--ember)" stroke-width="1"/>
  <rect x="376" y="24" width="40" height="28" fill="var(--ember-soft)" stroke="var(--ember)" stroke-width="1"/>
  <rect x="416" y="24" width="40" height="28" fill="var(--ember-soft)" stroke="var(--ember)" stroke-width="1"/>
  <rect x="456" y="24" width="40" height="28" fill="var(--ember-soft)" stroke="var(--ember)" stroke-width="1"/>
  <rect x="496" y="24" width="40" height="28" fill="var(--ember-soft)" stroke="var(--ember)" stroke-width="1"/>
  <text x="356" y="43" text-anchor="middle" font-size="14" class="mono" fill="var(--ink)">h</text>
  <text x="396" y="43" text-anchor="middle" font-size="14" class="mono" fill="var(--ink)">e</text>
  <text x="436" y="43" text-anchor="middle" font-size="14" class="mono" fill="var(--ink)">l</text>
  <text x="476" y="43" text-anchor="middle" font-size="14" class="mono" fill="var(--ink)">l</text>
  <text x="516" y="43" text-anchor="middle" font-size="14" class="mono" fill="var(--ink)">o</text>

  <line x1="176" y1="38" x2="332" y2="38" stroke="var(--ember)" stroke-width="1.5" marker-end="url(#a3)"/>
</svg>
</div>
<figcaption>The three stack words are the String. The heap bytes are what it owns.</figcaption>
</figure>
```
