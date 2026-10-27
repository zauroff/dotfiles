---
name: report
description: Write a whitepaper-style HTML report for either a bug investigation (incident, outage, regression, root cause analysis, postmortem) or a design proposal. One self-contained .html file that opens with a TL;DR, backs every claim with numbered references (logs, Grafana, code, deploys, tickets, docs), and includes interactive figures (timeline, chart, explorable diagrams). Dark and light themes in the Boltz palette with Barlow and Martian Mono. Use whenever the user asks for a report, write-up, investigation doc, incident report, RCA, postmortem, bug report, findings doc, whitepaper, or a proposal report.
---

# Report

A report is one HTML file that a reader can skim in a minute or read in fifteen. The TL;DR alone tells them what happened or what changes. Everything after it is evidence, and every piece of evidence links to a source the reader can open and check.

There are two kinds:

- **Investigation**: a bug, incident or regression. What happened, why, and what to do about it.
- **Proposal**: a design change. Problem, design, alternatives.

## Workflow

1. **Pick the kind** from the request. Ask only if it could be either.
2. **Pick the output path.** Use the user's path if given, else `~/reports/<slug>/index.html` with a short kebab-case slug. Say which path you used in the final message.
3. **Gather evidence before writing.** Use the tools available: logs, metrics dashboards, tickets, code and PRs, internal docs, service configuration, deploy history, the local repo. Record each source as you use it: type, title, URL, the exact query or file and line, and the time range in UTC. These become the references.
4. **Copy the template**: `cp ~/.claude/skills/report/assets/template.html <path>`. Delete the section set you are not using, between `<!-- investigation:start -->` and `<!-- investigation:end -->` or the proposal markers, and the markers themselves.
5. **Read `references/components.md`** and skim `references/example-investigation.html` before writing markup.
6. **Write the sections** following the rules below. Write the TL;DR last, then the masthead.
7. **Add the figures.** At least two interactive figures (see Figures).
8. **Fill the footer**: `Generated with <your model name>`, for example `Generated with Claude Opus 5.5`.
9. **Finalize**: `python3 ~/.claude/skills/report/scripts/finalize.py <path>`. It embeds the fonts and checks placeholders, citations, reference numbering, figure numbering, chart data and em dashes. Fix every error and every warning that applies, then run it again. It is safe to rerun after any edit.
10. **Look at it**: `open <path>`. Switch Dark and Light, click through each figure, hover a few citations.
11. **Reply** with the path and the TL;DR lede.

## Investigation sections

1. **TL;DR.** A lede of two or three sentences: what broke, for how long, and why. Then rows: What (impact with numbers), Cause, Mitigation, Fix. Use "Suspected cause" when it is not confirmed.
2. **Context.** What happened and when, in time order, with absolute UTC times. Fig 1 is the incident timeline. Cite every event. End with a Scope subsection: what was affected and what was not.
3. **Findings.** A callout with the root cause, or the leading hypothesis and how sure you are. Then an explorer figure of the failing path, then one `h3` per piece of evidence ("Evidence 1: logs", "Evidence 2: code", "Evidence 3: metrics"), each with the excerpt or chart and its citation. Then a Ruled out table: each hypothesis considered, the verdict, and the evidence. Add a Detection gap subsection when the alert fired late or not at all.
4. **Remediation and next steps.** Mitigation as a task list of what was done, with times. Fix as numbered steps, each followed by its reason, with the diff when there is one. Next steps as a table: action, owner, ticket, status.
5. **References.**

Masthead knobs: Severity, Impact window, Peak (the metric that shows the impact), Status (Investigating, Mitigated, Resolved).

## Proposal sections

1. **TL;DR.** A lede: what changes and why. Rows: Problem, Proposal, Impact, Decision (what the reader is asked to decide).
2. **Problem.** What is wrong or missing today. Name the code involved and give a concrete case of the consequence.
3. **Goals and non-goals.** What the proposal must achieve, and what it deliberately leaves unchanged.
4. **Proposal.** The design, with the reason right after each requirement. Include an explorer figure with today and proposed variants.
5. Optional, in this order, only when they apply: **Usage examples**, **API**, **Compatibility and migration** (what old components do with the change), **Rollout** (a timeline with `milestone` events fits here), **Risks**.
6. **Alternatives considered.** Other designs and why the proposal does not use them.
7. **Open questions.** Decisions still to make, or "None".
8. **References.**

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

Every report has at least two interactive figures, chosen from the three types in `references/components.md`:

- **Timeline** (`data-timeline`): an evenly spaced event sequencer. Required as Fig 1 in an investigation's Context.
- **Chart** (`data-chart`): lines with a hover readout, view switch, threshold and event marks. For metrics.
- **Explorer** (`data-explore`): a hand-drawn SVG whose parts open evidence panels, with optional before and after variants. Required in an investigation's Findings and a proposal's Proposal.

A figure earns its place by showing order, flow, or change over time that prose cannot. Each figure has a number, a caption that ends with how to interact, and an `sr-only` text version. Figures use only the page's color classes and variables, so both themes hold.

## Voice

- Short declarative sentences: the fact, then the consequence.
- Lead with the answer. No preamble, no sentences about the report itself, no recap at the end.
- Use the names the code, logs and dashboards use. Don't coin terms. If something has no name, describe it.
- Numbers carry units and precision that match the source: "197 steps", "5m 30s", "18 per minute".
- No figurative or critic-speak phrasing ("smoking gun", "the crux", "load-bearing"), no emphatic fragments, no "not X but Y", no em dashes. No praise, no blame, no names of people in the narrative; name teams and roles.
- State what is observed and what is inferred, and keep them apart.
- TL;DR under 120 words. The whole report 1,500 to 4,000 words.

## Design

The design is fixed. Every report is the same publication:

- Boltz palette: near-black `#0d0d0d` or warm grey `#e9e9e4` page, ink, greys, one orange accent, and blue, green and red as category colors. Dark and light themes follow the system setting, with an Auto / Dark / Light switch in the app bar.
- Fonts: Barlow for body, Barlow Semi Condensed for headings, Martian Mono for code, labels and data. Embedded in the file by `finalize.py`.
- A 5x7 dot-matrix title over the full `h1`, a strip of four headline numbers, a rail of numbered sections, `h2` with a numbered ink chip, `h3` in grey small caps, orange chips for numbered lists, tables with rules only, framed code blocks with a source tab.

Do not restyle a report. If the user wants a different look, say the design is fixed and offer to add a second template.

## Output

One `.html` file with no external requests: fonts are embedded, scripts and styles are inline, there are no images. It opens from disk and from any static host. The page needs JavaScript for the rail, section numbers and figures; the text, tables, code and references read without it.
