# Primer design
Dan Zauroff Design System

Feel: a research publication that happens to be a web page. Soft cream, neutral
ink, one loud orange, a serif for headlines, a quiet grotesk for reading. Light on
decoration. The orange is the only thing that shouts.

## Color

| Token | Light | Dark | Use |
|---|---|---|---|
| `--paper` | `#f8f6f1` | `#191917` | Page background. Never `#fff` or `#000`. |
| `--paper-raised` | `#fdfcfa` | `#22211e` | Nav card, code blocks, boxes inside figures. |
| `--paper-sunken` | `#efece4` | `#121210` | Figure mats. |
| `--line` | `#e2ddd2` | `#3a3934` | Every border and rule. 1px. Never carries meaning. |
| `--ink` | `#1c1b18` | `#f2efe8` | Headings and body. The only color for text at length. |
| `--ink-muted` | `#66635c` | `#aaa69c` | Captions, metadata, eyebrows, secondary labels. |
| `--ember` | `#fc6603` | `#fc6603` | Fills and strokes only. Not text on paper (2.8:1). |
| `--ember-text` | `#b54600` | `#ff9a4d` | Ember as text: links, callout labels, keywords, error marks. |
| `--ember-soft` | `#ffe6d4` | `#3b1d08` | Tint behind ember-text: the callout, an emphasised box. |
| `--moss` | `#3d6b3a` | `#8fc48a` | Minor accent, text and dots only. String literals, a "valid" state. |
| `--focus-ring` | = ember-text | = ember-text | 2px ring, 2px offset on focus. |

Rules:

- Neutrals are warm grey, not tan. No brown anywhere.
- Ember is spent once per view at full strength. In a primer that means one
  emphasised element per figure and nothing else in orange.
- Text on an ember fill is `--paper`. That pair is under 4.5:1, so it is only for
  short labels at 16px or larger. Primers do not need it.

## Type

Three families from Google Fonts. The template's `<link>` loads all three.

| Role | Family | Fallbacks |
|---|---|---|
| Headings | Newsreader, weight 400 only | Iowan Old Style, Georgia, serif |
| Body | IBM Plex Sans | Helvetica Neue, Arial, sans-serif |
| Mono | IBM Plex Mono | ui-monospace, Menlo, monospace |

| Style | Size / line | Notes | Template element |
|---|---|---|---|
| display | 48 / 52, -0.015em | Page title | `h1` |
| heading | 32 / 38, -0.01em | Section title | `h2` |
| subheading | 22 / 30, italic | Subsection. Italic is the serif's only emphasis. | `h3` |
| body-lg | 19 / 30 | Prose | `body` |
| body | 16 / 26 | Nav, tables, callout text | `nav`, `table`, `.rule` |
| small | 14 / 20 | Captions, subtitle metadata | `figcaption`, `.small` |
| eyebrow | 12 / 16, 500, 0.08em, uppercase, mono | Label above the title, callout label, table headers | `.eyebrow`, `th` |
| code | 14 / 22, mono | Inline and block code | `code`, `pre` |

Rules:

- Never bold the serif. Never set a heading in the sans.
- Sentence case everywhere, headings included. Uppercase belongs only to the
  eyebrow style.
- Measure is 640px. Headings may not run wider in a primer; there is one column.
- No exclamation marks, no emoji.

## Layout and spacing

4px base. Tokens `--space-2` (8) to `--space-24` (96).

- One centred column, 640px, 16px side gutter on phones.
- Sections separated by `--space-16` (64) with a 1px `--line` rule above each `h2`.
- Subsections by `--space-8`. Nothing inside a component exceeds `--space-6`.
- Borders, not shadows. Primers use no shadow at all.

## Radius

| Token | Value | Use |
|---|---|---|
| `--radius-sm` | 6px | Inline code |
| `--radius-md` | 12px | Callouts, code blocks, boxes inside figures |
| `--radius-lg` | 16px | Nav card, figure mats |

## Components in a primer

- **Eyebrow** above the title: "Primer · Rust", mono, uppercase.
- **Contents card** (`nav`): paper-raised, line border, radius-lg, two columns
  of numbered anchors.
- **Callout** (`.rule`): ember-soft ground, an eyebrow label in ember-text
  ("Keep", "Rule", "Definition"), one or two sentences in body size. One per
  section at most. No icon.
- **Code block** (`pre`): paper-raised, line border, radius-md. Four highlight
  classes: `.k` keyword in ember-text, `.t` type in ink at weight 500,
  `.s` literal in moss, `.c` comment in ink-muted. `.err` marks a failing line
  in ember-text.
- **Table**: line rules only, eyebrow-style headers, no zebra, no fills.
- **Figure**: an inline SVG on a `.mat` (paper-sunken, line border, radius-lg,
  space-6 padding), caption in small ink-muted below. Drawn in ink and ember on
  paper. See `references/svg.md`.

## Links

Ember-text with a 1px underline in `--line`, offset 3px. On hover the underline
turns ember and 2px. The only motion on the page is that color change, 150ms.

## Not in this design

Hero images, cards in grids, icons, gradients, drop shadows, device frames,
stock illustration, 3D renders, pure white, pure black, brown, bold serif,
Title Case.
