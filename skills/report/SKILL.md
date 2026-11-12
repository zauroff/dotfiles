---
name: report
description: Write a whitepaper-style HTML report for either a bug investigation (incident, outage, regression, root cause analysis, postmortem) or a design proposal. One self-contained .html file that opens with a TL;DR, explains technical terms in a hover glossary, backs every claim with numbered references (logs, Grafana, code, deploys, tickets, docs), and includes interactive figures (timeline, sequence diagram, line chart, bar chart, heatmap, matrix, explorable diagrams). Three designs, all with dark and light themes: plain (the default: system font, hairline rules, no accent color), raw (browser-default HTML: Times, blue links, bordered tables) and Boltz (Barlow and Martian Mono, dot-matrix title, orange accent). Use whenever the user asks for a report, write-up, investigation doc, incident report, RCA, postmortem, bug report, findings doc, whitepaper, or a proposal report.
---

# Report

A report is one HTML file that a reader can skim in a minute or read in fifteen. The TL;DR alone tells them what happened or what changes. Everything after it is evidence, and every piece of evidence links to a source the reader can open and check. A reader new to the system can follow it: technical terms carry a hover definition, and figures show the mechanisms the text describes.

There are two kinds:

- **Investigation**: a bug, incident or regression. What happened, why, and what to do about it.
- **Proposal**: a design change. Problem, design, alternatives.

## Workflow

`<skill>` below is the directory containing this SKILL.md. `references/`, `assets/` and `scripts/` paths are relative to it.

1. **Pick the kind** from the request. Ask only if it could be either. Pick the design too: plain, unless the user asks for raw or Boltz.
2. **Pick the output path.** Use the user's path if given, else `~/reports/<slug>/index.html` with a short kebab-case slug. Say which path you used in the final message.
3. **Gather evidence before writing.** Use the tools available: logs, metrics dashboards, tickets, code and PRs, internal docs, service configuration, deploy history, the local repo. Record each source as you use it: type, title, URL, the exact query or file and line, and the time range in UTC. These become the references.
4. **Plan figures and terms.** List each mechanism, flow, comparison or change over time the reader must understand, and pick a figure for it (see Figures). List the terms a newcomer would need explained (see Glossary), and the places where a short explanation must come before the evidence.
5. **Copy the template**: `cp <skill>/assets/template.html <path>`. Delete the section set you are not using, between `<!-- investigation:start -->` and `<!-- investigation:end -->` or the proposal markers, and the markers themselves. For plain and raw, also delete the `<div class="dots" …>` line: the dot-matrix title only exists in Boltz.
6. **Read `references/components.md`**, then skim `references/example-investigation.html` and `references/example-figures.html` before writing markup.
7. **Write the sections** following the rules below. Write the TL;DR last, then the masthead.
8. **Add the figures** (see Figures).
9. **Write the glossary** and link each term's first use in each section.
10. **Fill the footer**: `Generated with <your model name>`, for example `Generated with Claude Opus 5.5`.
11. **Finalize**: `python3 <skill>/scripts/finalize.py <path>`, adding `--design raw` or `--design boltz` for those designs. It writes the design's stylesheet into the page (and, for Boltz, embeds the fonts), then checks placeholders, citations, reference numbering, figure numbering, figure data, glossary links and em dashes. Fix every error and every warning that applies, then run it again. It is safe to rerun after any edit, and a rerun without `--design` keeps the page's design.
12. **Look at it**: `open <path>`. Switch Dark and Light, click through each figure, hover a few citations and glossary terms.
13. **Reply** with the path and the TL;DR lede.

## Investigation sections

1. **TL;DR.** A lede of two or three sentences: what broke, for how long, and why. Then rows: What (impact with numbers), Cause, Mitigation, Fix. Use "Suspected cause" when it is not confirmed.
2. **Context.** What happened and when, in time order, with absolute UTC times. Fig 1 is the incident timeline. Cite every event. End with a Scope subsection: what was affected and what was not.
3. **Findings.** A callout with the root cause, or the leading hypothesis and how sure you are. Then a sequence or explorer figure of the failing path, then one `h3` per piece of evidence ("Evidence 1: logs", "Evidence 2: code", "Evidence 3: metrics"), each with the excerpt or figure and its citation. Then a Ruled out table: each hypothesis considered, the verdict, and the evidence. Add a Detection gap subsection when the alert fired late or not at all.
4. **Remediation and next steps.** Mitigation as a task list of what was done, with times. Fix as numbered steps, each followed by its reason, with the diff when there is one. Next steps as a table: action, owner, ticket, status.
5. **Glossary.**
6. **References.**

Masthead knobs: Severity, Impact window, Peak (the metric that shows the impact), Status (Investigating, Mitigated, Resolved).

## Proposal sections

1. **TL;DR.** A lede: what changes and why. Rows: Problem, Proposal, Impact, Decision (what the reader is asked to decide).
2. **Problem.** What is wrong or missing today. Name the code involved and give a concrete case of the consequence.
3. **Goals and non-goals.** What the proposal must achieve, and what it deliberately leaves unchanged.
4. **Proposal.** The design, with the reason right after each requirement. Include an explorer or sequence figure with today and proposed variants.
5. Optional, in this order, only when they apply: **Usage examples**, **API**, **Compatibility and migration** (what old components do with the change), **Rollout** (a timeline with `milestone` events fits here), **Risks**.
6. **Alternatives considered.** Other designs and why the proposal does not use them. A matrix of options against requirements fits here.
7. **Open questions.** Decisions still to make, or "None".
8. **Glossary.**
9. **References.**

Masthead knobs: Components, Effort, Risk, Status (Draft, In review).

This skill writes a local file. Never open issues or PRs from this skill.

## Evidence and references

- Every factual claim gets a citation, `<a class="cite" href="#ref-N">RN</a>`, right after the claim. Claims without a source are cut, or stated as inference with the reasoning: "worker-3 likely resumed rather than re-registered, because no `worker registered` line appears until 14:34".
- Number references R1, R2, … in the order they are first cited. The references section is always last.
- Each reference has a type tag, a title that says what the source is, a link, and a `src` line with the exact query, panel, commit hash or `path:line`, and the time range in UTC.
- Prefer stable links: commit-hash permalinks over branch links, Grafana links with absolute `from`/`to`, saved queries.
- Use URLs that a tool returned or the user gave. Never build a URL by guessing its format. When there is no URL, leave the title unlinked and put the exact query or command in the `src` line so a reader can reproduce it.
- Quote evidence instead of paraphrasing it: the log lines, the code lines, the metric values. Trim with `… N lines …` instead of pasting walls.
- Times are absolute and in UTC everywhere: text, timeline, chart labels, references.

## Figures

Use a figure for each mechanism, flow, comparison or change over time that would take more than a paragraph to explain in prose. Every report has at least two; most have three to six. Pick the type by what the reader must see. Markup for each is in `references/components.md`.

| Type | Attribute | Shows |
|---|---|---|
| Timeline | `data-timeline` | Events in time order. Required as Fig 1 in an investigation's Context. |
| Sequence | `data-sequence` | Messages between components in order, with optional before and after variants. Request flows, handshakes, retries. |
| Chart | `data-chart` | A metric over time, with hover readout, views, threshold and event marks. |
| Bars | `data-bars` | Categories compared by size: per host, per service, per severity. |
| Heatmap | `data-heatmap` | A metric across many entities and time buckets, to show which and when. |
| Matrix | `data-matrix` | Which row has which property: permissions, coverage, options against requirements. |
| Explorer | `data-explore` | A hand-drawn SVG whose parts open evidence panels: architecture, data layout, state machine. |

An investigation's Findings has a sequence or explorer of the failing path. A proposal's Proposal has a sequence or explorer with today and proposed variants. Prefer a data-driven type over a hand-drawn explorer when one fits.

Each figure has a number, a caption that ends with how to interact, and a text version (`sr-only`, or the data list or table the figure is built from). Figures use only the page's color classes and variables, so both themes hold.

## Glossary

- Every report has a glossary of the terms a newcomer would need explained: protocols, internal systems and products, and the functions or configs central to the finding. Usually 5 to 15 terms. Leave out what any engineer knows (HTTP, TCP, JSON).
- Link the first use of each term in each section with `<a class="term" href="#term-slug">`. Hovering shows the definition and example in a tooltip.
- A definition says what the term means in general, then what it does here, in at most 40 words. Add an example when it helps: a concrete instance, or a code block of three to six lines with its `path:line` when the term names code.
- Claims about the system in a definition follow the evidence rules. Cite them in the glossary entry.

## Voice

- Write plain, complete sentences, the way you would explain the issue to a teammate new to the system. Connect facts with "because", "so" and "which means" instead of listing them.
- Say why a fact matters the first time it appears. The reader should not have to work out the consequence.
- Explain how a mechanism normally works, in one or two sentences, before the evidence of how it failed.
- Keep it short. Paragraphs of two to four sentences, one idea each. Do not repeat a point in another section. Cut any sentence the report reads the same without.
- Lead with the answer. No preamble, no sentences about the report itself, no recap at the end.
- Use the names the code, logs and dashboards use. Don't coin terms. If something has no name, describe it. Explain jargon through the glossary instead of inline asides.
- Numbers carry units and precision that match the source: "197 steps", "5m 30s", "18 per minute".
- No figurative or critic-speak phrasing ("smoking gun", "the crux", "load-bearing"), no emphatic fragments, no "not X but Y", no em dashes. No praise, no blame, no names of people in the narrative; name teams and roles.
- State what is observed and what is inferred, and keep them apart.
- TL;DR under 120 words. The whole report 1,500 to 4,000 words.

## Design

Every report uses one of three designs. They share the page structure, the figures and the scripts; only the stylesheet differs, kept in `assets/designs/<name>.css` and written into the page by `finalize.py`.

**Plain** (default). Quiet, raw-HTML minimalism, so the evidence is the loudest thing on the page:

- System font (`system-ui`) for everything, a monospace stack for code. No web fonts.
- Warm off-white page `#f9f9f7` with cards `#fcfcfb`, or `#0d0d0d` and `#1a1a19` in dark. Three ink levels: primary, secondary and muted grey.
- Cards (figures, callouts, code, the masthead numbers) have a 1px 10%-ink border and 12px corners. Rules and gridlines are solid 1px hairlines. The only shadow is on tooltips.
- No accent color in the chrome: links are ink with a grey underline, the selected control is a faint ink wash. Blue `#2a78d6`, orange `#eb6834`, aqua-green `#1baf7a` and red `#d03b3b` appear only on data marks and as small dots on tags.
- Sentence-case headings, section numbers in muted figures, numbered lists in outlined circles.

**Raw**. A page that looks like HTML with almost no stylesheet:

- Browser defaults: Times for text, the default monospace for code, blue and purple underlined links, standard buttons, bullets and numbered lists, a white page (or near-black in dark).
- One 48em column. The section list is a plain "Contents" list under the masthead instead of a sticky rail.
- Tables and figures get 1px borders, citations are superscript `[R4]`, tags are `[Confirmed]`, highlights are marker yellow. No cards, rounded corners or shadows.
- Data marks keep the plain design's colorblind-checked palette.

**Boltz**. A branded publication look:

- Boltz palette: near-black `#0d0d0d` or warm grey `#e9e9e4` page, ink, greys, one orange accent, and blue, green and red as category colors.
- Fonts: Barlow for body, Barlow Semi Condensed for headings, Martian Mono for code, labels and data. Embedded in the file by `finalize.py`.
- A 5x7 dot-matrix title over the full `h1`, a strip of four headline numbers, a rail of numbered sections, `h2` with a numbered ink chip, `h3` in grey small caps, orange chips for numbered lists, tables with rules only, framed code blocks with a source tab, dotted underlines on glossary terms.

All three follow the system theme, with an Auto / Dark / Light switch in the app bar. Do not restyle a report beyond picking a design. If the user wants a different look, offer to add a third design under `assets/designs/`, written against the same class names and CSS variables (`--bg`, `--surface`, `--ink`, `--grey`, `--orange`, `--blue`, …), because the figure scripts read them. A change to page structure or figures needs every stylesheet checked.

## Output

One `.html` file with no external requests: styles and scripts are inline, Boltz fonts are embedded, there are no images. It opens from disk and from any static host. The page needs JavaScript for the rail, section numbers, tooltips and figures; the text, tables, code, glossary and references read without it.
