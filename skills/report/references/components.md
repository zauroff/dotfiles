# Components

Markup for every part of a report. The template's script does the wiring: it numbers the `h2` chips, builds the rail, adds copy buttons to code blocks, shows citation tooltips, and renders the three interactive figure types. Never edit the `<style>` or `<script>` blocks per report. Styling a report needs beyond these classes goes in a second `<style>` block in `<head>`.

`references/example-investigation.html` is a complete investigation report built from these components. Read it before writing the first figure.

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

- `data-dots` is the dot-matrix title: one or two lines split by `|`, at most 9 characters per line. Supported: `A-Z 0-9 space - . : / ' ! ?`. Anything else renders as `?`. Pick the two or three words a reader would use to name the report, not the full title.
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
