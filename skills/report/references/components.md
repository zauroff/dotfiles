# Components

Markup for every part of a report. The template's script does the wiring: it numbers the `h2` chips, builds the rail, adds copy buttons to code blocks, shows citation and glossary tooltips, and renders the seven interactive figure types. Never edit the `<style>` or `<script>` blocks per report. Styling a report needs beyond these classes goes in a second `<style>` block in `<head>`.

`references/example-investigation.html` is a complete investigation report built from these components. Read it before writing the first figure. `references/example-figures.html` shows the sequence, matrix, bars and heatmap figures and the glossary terms with working markup.

## Masthead

```html
<header class="masthead">
  <div class="eyebrow"><b>■</b> Investigation · scheduler · incident 2026-10-14</div>
  <div class="dots" data-dots="WORKER-3|SKIPPED" aria-hidden="true"></div>
  <h1>Dispatcher skips worker-3 after session resume</h1>
  <p class="meta"><span>Platform on-call</span><span>2026-10-20</span><a href="#ref-8">INC-4127</a></p>
  <div class="knobs">
    <div class="knob" style="--c: var(--red)"><div class="label">Severity</div><div class="value">Sev-3</div></div>
    …four knobs in total
  </div>
</header>
```

- `data-dots` is the dot-matrix title, Boltz design only (delete the line for plain): one or two lines split by `|`, at most 9 characters per line. Supported: `A-Z 0-9 space - . : / ' ! ?`. Anything else renders as `?`. Pick the two or three words a reader would use to name the report, not the full title.
- The `h1` is the full title, sentence case, naming the component affected.
- `.meta` holds authors, the report date as `YYYY-MM-DD`, and the ticket or issue link. Add the time window for investigations.
- Exactly four knobs. Values are short (12 characters or fewer) because they render uppercase at 22px. `--c` colors the knob's dot: use `--red`, `--blue`, `--orange`, `--green` in that order unless a value has a natural color (green for Resolved, red for Sev-1).

## Sections

```html
<section id="findings" class="sec" data-rail="Findings">
<h2>Findings</h2>
<p>…</p>
<h3>Evidence 1: logs</h3>
<p>…</p>
</section>
```

- Sections are direct children of `<main>`. The script prepends the `01`, `02` chip to each `h2` and adds a rail entry. Do not write the number yourself.
- `data-rail` sets a shorter rail label when the `h2` is long ("Remediation" for "Remediation and next steps").
- `h3` renders as `— SMALL CAPS`. Write it in sentence case without the dash.

## TL;DR

```html
<section id="tldr" class="sec" data-rail="TL;DR">
<h2>TL;DR</h2>
<p class="lede">Two or three sentences.</p>
<dl class="tldr">
  <dt>What</dt><dd>One sentence.</dd>
  <dt>Cause</dt><dd>One sentence.</dd>
</dl>
</section>
```

## Text

- `<p class="lede">`: larger first paragraph. Only in the TL;DR.
- `<code>`: identifiers, paths, metric names, log fields. Renders blue.
- `<strong>`: highlighted. At most one per section, for the single fact a skimmer must not miss.
- `<ul>`: orange `▪` bullets.
- `<ol class="n">`: orange numbered chips, for ordered steps.
- `<ul class="tasks">` with `<li class="done">` (☑, struck grey) or `<li class="open">` (☐ orange), for actions taken or pending.

## Callout

```html
<div class="callout">
  <div class="head"><span class="chip o">Root cause</span>Resumed sessions skip capability publication</div>
  <p>…</p>
</div>
```

Labels: "Root cause" when confirmed, "Leading hypothesis" when not, "Decision" or "Recommendation" in a proposal, "Note" otherwise. At most one callout per section.

## Code block

```html
<div class="code"><div class="code-tab"><span>scheduler/session.go:88</span><b>go</b></div><pre><code><span class="k">func</span> (c *Scheduler) <span class="f">handleConnect</span>(…) {
<span class="hl">        <span class="k">return</span> sess.<span class="f">Ack</span>(), <span class="k">nil</span></span>
}</code></pre></div>
```

- The tab's `<span>` is the source: `path:line` for code, the query or repo for logs. `<b>` is the language. The script adds the Copy button.
- Highlight spans: `k` keyword, `f` function, `s` string, `c` comment. Logs: `warn`, `err`, `info`, `debug` on the level. Diffs: `add`, `del` on whole lines. `hl` marks the line the reader should look at; use it once per block.
- Escape `<`, `>` and `&` inside `<pre>`. Cut long excerpts with a `<span class="c">… N lines …</span>` line instead of pasting them.

## Table and tags

```html
<table>
<thead><tr><th>Hypothesis</th><th>Verdict</th><th>Evidence</th></tr></thead>
<tbody><tr><td class="key">worker-3 host unhealthy</td><td><span class="tag">Ruled out</span></td><td>…</td></tr></tbody>
</table>
```

`td.key` is the row's subject in ink. Tags: `.tag` grey (neutral, ruled out, open), `.tag.o` filled orange (confirmed, the one thing that matters), `.tag.b` blue (in progress), `.tag.g` green (done, healthy), `.tag.r` red (missing, failing), `.tag.w` ink.

## Citations and references

Cite right after the claim, before the period:

```html
…and resumed its session <a class="cite" href="#ref-4">R4</a>.
```

The references section is always last:

```html
<section id="references" class="sec">
<h2>References</h2>
<ol class="refs">
  <li id="ref-1"><span class="id">R1</span><span class="tag b">Deploy</span><span><a class="title" href="URL">Scheduler v4.18.0 rollout, prod-east</a><span class="src">deploy pipeline run 88213 · started 13:58:10 UTC</span></span></li>
</ol>
</section>
```

| Type | Tag class | `src` line holds |
|---|---|---|
| Log | `tag w` | repo or index, the exact query, time range UTC |
| Grafana | `tag g` | dashboard / panel names, bucket size, time range UTC |
| Deploy | `tag b` | pipeline run or release, start time |
| Code, PR, Commit | `tag r` | commit hash, `path:line` |
| Ticket, Issue | `tag o` | ticket number, what in it is relevant |
| Doc | `tag` | doc site and page path |
| Chat | `tag` | channel, author, timestamp |

The citation tooltip shows the tag and title, so the title must say what the source is ("Logs: worker-3 and scheduler logs"), not just repeat a URL.

## Glossary terms

Link a term in the text to its glossary entry. Hovering or focusing the link shows the definition, and the example when there is one, in a tooltip. Without JavaScript the link jumps to the entry.

```html
…the resume path in <a class="term" href="#term-handleconnect">handleConnect</a> returns early…
```

The glossary section sits right before References:

```html
<section id="glossary" class="sec">
<h2>Glossary</h2>
<dl class="glossary">
  <div id="term-capability">
    <dt>Capability</dt>
    <dd>A step type a worker says it can run. The dispatcher only sends a step to workers that list a matching capability.</dd>
    <dd class="eg">worker-3 lists 14 capabilities when healthy.</dd>
  </div>
  <div id="term-handleconnect">
    <dt>handleConnect</dt>
    <dd>The scheduler function that runs when a worker connects. It resumes the worker's session or creates a new one.</dd>
    <dd class="eg"><div class="code"><div class="code-tab"><span>scheduler/session.go:88</span><b>go</b></div><pre><code>…three to six lines…</code></pre></div></dd>
  </div>
</dl>
</section>
```

- The id is `term-` plus a lowercase kebab slug. The link is always written `<a class="term" href="#term-slug">`.
- The first `dd` is the definition: one or two sentences, at most 40 words. Say what the term means in general first, then what it does in this system.
- The `dd class="eg"` is optional. Use one sentence with a concrete instance, or, when the term names code, a code block of three to six lines with the `path:line` in its tab. The tooltip shows the code and the path.
- Link the first use of a term in each section, not every use. Do not link inside headings, the TL;DR rows or figure SVG text.
- Entries are in alphabetical order. Every entry is linked at least once.
- Citations in a definition are hidden in the tooltip and shown in the glossary.

## Choosing a figure

| What the reader must see | Figure |
|---|---|
| Events in time order | Timeline |
| Messages between components, in order | Sequence |
| A metric changing over time | Chart |
| Categories compared by size | Bars |
| A metric across many entities and times, to spot which and when | Heatmap |
| Which item has which property or permission | Matrix |
| A structure: architecture, data layout, state machine, flow | Explorer |

Prefer the data-driven types (timeline, sequence, chart, bars, heatmap, matrix) over a hand-drawn explorer when one fits. They are faster to write and always match the theme.

## Figures

Every figure has the same shell:

```html
<figure class="fig" id="figure-2" data-explore>
  <div class="fig-head"><span class="fig-num">FIG 2</span><h4>Reconnect sequence</h4></div>
  <div class="fig-body">…</div>
  <figcaption>What the figure shows, then how to interact with it.</figcaption>
  <p class="sr-only">Text version: the same information as plain sentences.</p>
</figure>
```

- Number figures `FIG 1`, `FIG 2` in page order, with `id="figure-N"`. Refer to them as "Fig 2" and link `#figure-2`.
- The `h4` names the subject in a few words.
- The caption ends with the interaction ("Select a step, or use the arrow keys.").
- The `sr-only` text version is required. Timelines get one for free from their data list.

### Timeline: `data-timeline`

A sequencer of evenly spaced events. Each step shows its time and the delta since the previous one. Selecting a step shows its detail and citations. Prev, next and Play controls are added by the script.

```html
<figure class="fig" id="figure-1" data-timeline>
  <div class="fig-head"><span class="fig-num">FIG 1</span><h4>Incident timeline</h4></div>
  <div class="fig-body"></div>
  <figcaption>Events on 2026-10-14, UTC, evenly spaced. The delta under each step is the time since the previous event. Select a step, or use the arrow keys.</figcaption>
  <ol class="tl-data sr-only">
    <li data-time="14:02:05" data-kind="cause" data-refs="2,6"><b>worker-3 resumes its session on scheduler-1.</b> <span>The resume path returns early. The scheduler never sends <code>RequestCapabilities</code>.</span></li>
  </ol>
</figure>
```

- `data-time`: `HH:MM:SS`, `HH:MM`, `YYYY-MM-DD HH:MM`, or `YYYY-MM-DD`. Use one format per timeline. Include the date when events span days.
- `data-kind`: `change` (blue: deploys, config), `system` (grey: what the system did), `cause` (orange: the triggering moment, at most one), `alert` (red), `action` (green: what people did), `milestone` (ink: proposal rollouts).
- `data-refs`: comma-separated reference numbers. Every event needs at least one.
- `data-label` on an `li` overrides the short label under the step.
- `data-start` on the figure picks the initially selected step (1-based). Default: the `cause` event, else the first.
- `<b>` is the event title, one sentence. `<span>` is one or two sentences of detail and may contain `<code>`.
- 4 to 14 events. Merge or drop the rest.

### Chart: `data-chart`

A line chart with hover readout, arrow-key cursor, legend toggles, and optional view switch. The data lives in a JSON block inside the figure.

```html
<figure class="fig" id="figure-3" data-chart>
  <div class="fig-head"><span class="fig-num">FIG 3</span><h4>export-render throughput</h4></div>
  <div class="fig-body"></div>
  <figcaption>One-minute buckets from the export-render dashboard <a class="cite" href="#ref-6">R6</a>. Hover or use the arrow keys to read values.</figcaption>
  <p class="sr-only">Text version: …</p>
  <script type="application/json">
{"labels": ["13:55", "13:56", "…"], "tickEvery": 10, "tickOffset": 5,
 "views": [
  {"name": "Assignments / min", "max": 30, "series": [
    {"label": "worker-1", "color": "blue", "values": [14, 13, "…"]},
    {"label": "worker-3", "color": "orange", "emphasis": true, "values": [14, 14, "…"]}]},
  {"name": "Queue depth", "threshold": {"value": 120, "label": "Alert 120"}, "series": [
    {"label": "queue depth", "color": "ink", "emphasis": true, "values": [5, 5, "…"]}]}],
 "marks": [{"at": 7, "label": "14:02 resume"}],
 "band": {"from": 7.5, "to": 39.5},
 "cursor": 27}
  </script>
</figure>
```

| Field | Meaning |
|---|---|
| `labels` | x-axis label per data point. Every series has exactly this many values. |
| `tickEvery`, `tickOffset` | label every Nth point, starting at index `tickOffset`. |
| `views` | one or more views. More than one adds a view switch to the header. |
| `views[].max`, `ticks`, `unit` | y-axis top, explicit tick values, unit appended in the readout. All optional. |
| `views[].threshold` | dashed red line with a label, for an alert or SLO. |
| `series[].color` | `blue`, `green`, `orange`, `red`, `ink`, `grey`. Orange is the series the finding is about. |
| `series[].emphasis` | thicker line. Use on the focal series only. |
| `series[].values` | numbers, or `null` for a gap. |
| `marks` | dashed vertical lines at an index, labeled. Use the same moments as the timeline. |
| `band` | shaded index range, for the impact window. |
| `cursor` | initial cursor index. Put it on the most telling point. |

Use real exported values. If a dashboard can only be read by eye, say so in the caption and round accordingly. Never invent data points to fill a gap.

### Explorer: `data-explore`

A hand-drawn SVG (or HTML) diagram whose parts are selectable. Selecting a part shows its detail panel. Optional variants switch the diagram between states, such as before and after a fix, or today and proposed.

```html
<figure class="fig" id="figure-2" data-explore data-variant="before" data-default="m4">
  <div class="fig-head">
    <span class="fig-num">FIG 2</span><h4>Reconnect sequence</h4>
    <div class="keys" role="group" aria-label="Variant">
      <button data-set-variant="before">v4.18.0</button>
      <button data-set-variant="after">With fix</button>
    </div>
  </div>
  <div class="fig-body">
    <svg viewBox="0 0 880 470" role="img" aria-labelledby="f2-t"><title id="f2-t">…</title>
      <g class="pick" data-pick="m4" tabindex="0" role="button" aria-label="04 RequestCapabilities">
        <rect class="hit" x="8" y="225" width="864" height="42" rx="2"/>
        <text class="num" x="14" y="259">04</text>
        <g class="c-red" data-only="before">…dashed arrow, struck label, ✕…</g>
        <g class="c-green" data-only="after">…solid arrow and label…</g>
      </g>
    </svg>
    <div class="detail" aria-live="polite">
      <div data-detail="m4">
        <div class="when">04<small data-only="before">never sent</small><small data-only="after">after fix</small><span class="tag r" data-only="before">Missing</span><span class="tag g" data-only="after">Sent</span></div>
        <div><p data-only="before">… <a class="cite" href="#ref-2">R2</a></p><p data-only="after">…</p></div>
      </div>
    </div>
  </div>
  <figcaption>Select a message to see its evidence, or use the arrow keys. Switch to "With fix" to see the sequence after the change.</figcaption>
  <p class="sr-only">Text version: …</p>
</figure>
```

- `data-pick="id"` marks a selectable part. Several elements may share an id. Picks are keyboard focusable (`tabindex="0"`, `role="button"`, an `aria-label`) and the arrow keys move between them in DOM order.
- `data-detail="id"` is the panel shown for that pick. Layout: a `.when` column (big number or time, a `small` label, a status tag) and a text column with citations. Every pick has a detail panel.
- `data-default` is the pick selected on load. Choose the one that carries the finding.
- `data-variant` on the figure is the initial variant. Buttons with `data-set-variant` switch it. Any element with `data-only="before"` (space-separated list allowed) shows only in those variants, in the SVG and in the detail panels alike.
- Leave out the variant buttons when there is only one state.

### Sequence: `data-sequence`

Messages between components, drawn from a list. The script draws the lanes, lifelines, arrows and step numbers. Selecting a message shows its detail and citations. Prev, next and Play controls are added by the script. Use it for request flows, handshakes, enrollment, retries.

```html
<figure class="fig" id="figure-2" data-sequence data-lanes="worker-3|scheduler|registry" data-lane-notes="host|scheduler-1|in memory" data-variant="before">
  <div class="fig-head">
    <span class="fig-num">FIG 2</span><h4>Reconnect sequence</h4>
    <div class="keys" role="group" aria-label="Variant"><button data-set-variant="before">v4.18.0</button><button data-set-variant="after">With fix</button></div>
  </div>
  <div class="fig-body"></div>
  <figcaption>Messages when worker-3 reconnects. Select a message, use the arrow keys, or press Play. Switch to "With fix" to see the change.</figcaption>
  <ol class="sq-data sr-only">
    <li data-from="registry" data-kind="call" data-label="ClearCapabilities(worker-3)" data-refs="2"><b>The registry clears worker-3's capabilities.</b> <span>On disconnect, as it always has.</span></li>
    <li data-from="worker-3" data-to="scheduler" data-kind="call" data-label="Connect(session=7f3a)" data-refs="2"><b>worker-3 reconnects with its session.</b> <span>18 seconds after the disconnect.</span></li>
    <li data-from="scheduler" data-to="worker-3" data-kind="fail" data-only="before" data-label="RequestCapabilities" data-refs="1"><b>RequestCapabilities is never sent.</b> <span>Only the new-session branch calls <code>requestCapabilities</code>.</span></li>
    <li data-from="scheduler" data-to="worker-3" data-kind="added" data-only="after" data-label="RequestCapabilities" data-refs="1"><b>The resume path asks for capabilities.</b> <span>The fix calls it before returning.</span></li>
  </ol>
</figure>
```

- `data-lanes`: two to six lane names split by `|`, in left to right order. Names render uppercase; keep them under 16 characters. `data-lane-notes` is an optional second line per lane, in the same order.
- `data-from` and `data-to` name lanes exactly. Leave out `data-to`, or set it equal to `data-from`, for a step inside one component.
- `data-kind`: `call` (ink, solid), `reply` (grey, dashed), `focus` (orange, the message the finding is about, at most one per variant), `fail` (red, dashed, ✕ at the receiver: never sent, rejected, or failed), `added` (green, what the proposal or fix adds).
- `data-label` is the short text on the arrow, at most about 28 characters. `<b>` is the detail title, one sentence. `<span>` is one or two sentences of detail.
- `data-refs`: every message needs at least one.
- Variants work as in the explorer: buttons with `data-set-variant`, `data-variant` on the figure for the initial one, and `data-only` on a message to show it only in those variants. The script renumbers the messages for each variant.
- `data-start` picks the initially selected message (1-based). Default: the first `focus` or `fail`, else the first.
- 3 to 14 messages. The list doubles as the text version.

### Matrix: `data-matrix`

A plain table whose cells are marks. Hovering or selecting a cell highlights its row and column and shows the cell's note and citations. Use it for permissions, coverage, findings by component, or what each option supports.

```html
<figure class="fig" id="figure-3" data-matrix data-legend="yes:Allowed|no:Denied|part:Conditional|fail:Exposed today">
  <div class="fig-head"><span class="fig-num">FIG 3</span><h4>Connect paths</h4></div>
  <div class="fig-body">
  <table>
    <thead><tr><th>Path</th><th>Session</th><th>Asked for capabilities</th><th>Eligible</th></tr></thead>
    <tbody>
      <tr><th>New session</th><td data-v="yes" data-refs="1">A new session is created.</td><td data-v="yes" data-refs="1">…</td><td data-v="yes" data-refs="3">…</td></tr>
      <tr><th>Resume, v4.18.0</th><td data-v="yes" data-refs="1">…</td><td data-v="fail" data-default data-refs="1">The resume branch returns first.</td><td data-v="fail" data-refs="3">…</td></tr>
    </tbody>
  </table>
  </div>
  <figcaption>Each connect path against the steps that make a worker eligible. Hover or select a cell for its evidence, or use the arrow keys.</figcaption>
</figure>
```

- Each body row starts with a `th` naming the row. The `thead` names the columns.
- `data-v`: `yes` (green dot), `no` (empty ring), `part` (orange half dot), `fail` (red ✕). The cell's text is its note, one sentence, shown on selection.
- `data-legend` renames the values for this figure, as `value:Label` pairs split by `|`. Only values used in the table appear in the legend.
- `data-default` on one cell selects it on load. Choose the cell that carries the finding.
- A `td` without `data-v` renders as plain text, for a column of notes or numbers.
- At most about 8 columns and 12 rows. The table is its own text version.

### Bars: `data-bars`

Horizontal bars with a selected bar, its value and note, and an optional view switch and threshold.

```html
<figure class="fig" id="figure-4" data-bars>
  <div class="fig-head"><span class="fig-num">FIG 4</span><h4>Impact by worker</h4></div>
  <div class="fig-body"></div>
  <figcaption>Totals for 14:02 to 14:34 UTC from the export-render dashboard <a class="cite" href="#ref-6">R6</a>. Hover a bar or use the arrow keys.</figcaption>
  <p class="sr-only">Text version: …</p>
  <script type="application/json">
{"views": [
  {"name": "Steps assigned", "unit": " steps", "bars": [
    {"label": "worker-1", "value": 480, "note": "At its 15 per minute cap.", "refs": [6]},
    {"label": "worker-3", "value": 3, "color": "orange", "note": "None after the resume.", "refs": [6]}]},
  {"name": "P99 wait", "unit": "s", "threshold": {"value": 120, "label": "SLO 2m"}, "bars": ["…"]}],
 "cursor": 1}
  </script>
</figure>
```

| Field | Meaning |
|---|---|
| `views` | one or more views. More than one adds a view switch. |
| `views[].name`, `unit`, `max` | view label, unit appended to values, axis maximum. `unit` and `max` are optional. |
| `views[].threshold` | dashed red line with a label. |
| `bars[].label`, `value` | bar name and a number. |
| `bars[].color` | `grey` by default. `orange` for the bar the finding is about, red for failing, green for healthy. |
| `bars[].note`, `refs` | one sentence and reference numbers, shown when the bar is selected. |
| `cursor` | initially selected bar index. |

Sort bars by value unless the order means something. 2 to 15 bars per view.

### Heatmap: `data-heatmap`

A grid of cells, one row per entity and one column per time bucket, shaded by value. Hovering or moving the cursor shows the row, column and value. Use it to show which hosts, shards or services were affected and when.

```html
<figure class="fig" id="figure-5" data-heatmap>
  <div class="fig-head"><span class="fig-num">FIG 5</span><h4>Assignments per worker</h4></div>
  <div class="fig-body"></div>
  <figcaption>Assignments per minute from the export-render dashboard <a class="cite" href="#ref-6">R6</a>. Hover a cell or use the arrow keys.</figcaption>
  <p class="sr-only">Text version: …</p>
  <script type="application/json">
{"columns": ["13:56", "13:57", "…"], "tickEvery": 6, "tickOffset": 4, "unit": " / min", "color": "orange", "max": 15,
 "rows": [{"label": "worker-1", "values": [13, 14, "…"]}, {"label": "worker-3", "values": [14, 0, null, "…"]}],
 "marks": [{"at": 6, "label": "14:02 resume"}],
 "cursor": [1, 20]}
  </script>
</figure>
```

| Field | Meaning |
|---|---|
| `columns` | label per column. Every row has exactly this many values. |
| `tickEvery`, `tickOffset` | label every Nth column, starting at `tickOffset`. |
| `rows[].label`, `values` | entity name and numbers. `0` renders as an empty cell, `null` as a dashed gap for missing data. |
| `color` | shade color, `orange` by default. `red` for errors. |
| `max` | value for full color. Default: the largest value. |
| `marks` | dashed vertical lines at a column's left edge, labeled. Use the same moments as the timeline. |
| `cursor` | `[row, column]` selected on load. Put it on the most telling cell. |

2 to 20 rows and up to about 120 columns. Use real exported values, as for the chart.

## Drawing SVG

Hand-write every explorer SVG. The `example-investigation.html` sequence diagram is the reference for spacing and style.

- `viewBox="0 0 880 H"`. The SVG scales to the figure width, 880 units is about 1:1 on a desktop.
- Color only through classes, never hex values:
  - `c-ink`, `c-body`, `c-grey`, `c-dim`, `c-orange`, `c-blue`, `c-green`, `c-red` on a `<g>` set the color of its `line`, `path` and `polyline` strokes and its `polygon` and `circle` fills. Text inside with class `t` takes the same color.
  - `box` (frame, page background fill), `box-on` (orange frame), `life` (dotted lifeline).
  - Text: `t-head` (11.5px ink, lane and box titles, written in uppercase), `t` (11px, labels), `t-small` (9.5px grey, notes, written in uppercase), `x` (14px bold marker such as ✕).
  - When a class does not cover it, use `var(--name)` in the attribute: `stroke="var(--rule)"`.
- Orange is for the one element the finding is about. Red is for what is missing or failing, green for what the fix adds.
- Arrowheads are polygons drawn per arrow, filled by the group's color. Markers do not inherit the color.
- Labels sit 9 units above their line. Rows are at least 40 units apart. Keep text at 9.5 units or larger.
- Each pick gets a full-width `rect class="hit"` behind it so it is easy to click, and a `text class="num"` step number at the left when the parts are ordered.
- Suitable shapes: sequence diagrams (lanes and messages), flow or dependency graphs (boxes and arrows, the failing edge in red), state machines, architecture boxes with the failing component in `box-on`, before and after data layouts.
- After drawing, check both themes with the Dark and Light buttons. Nothing should disappear or lose contrast.
