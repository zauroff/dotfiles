#!/usr/bin/env python3
"""Apply a report design to a report HTML file and check it.

Usage: python3 finalize.py [--design plain|raw|boltz] <report.html>

Replaces <!--@DESIGN@--> (or a previous <style id="design"> block) with the
stylesheet from assets/designs. Without --design it keeps the page's current
design, and a fresh page gets plain. The boltz design also embeds the woff2
files from assets/fonts as data URIs in place of <!--@FONTS@-->, so the page
loads nothing from outside the file. Then checks citations, placeholders,
figures and prose. Exits 1 if there are errors. Safe to run again after
every edit.
"""
import base64
import json
import re
import sys
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "assets"
FONTS = ASSETS / "fonts"
DESIGNS = ASSETS / "designs"
DESIGN_NAMES = ("plain", "raw", "boltz")
DEFAULT_DESIGN = "plain"
FACES = [
    ("Barlow", "normal", "400", "barlow-400-latin"),
    ("Barlow", "italic", "400", "barlow-400-italic-latin"),
    ("Barlow", "normal", "500", "barlow-500-latin"),
    ("Barlow", "normal", "600", "barlow-600-latin"),
    ("Barlow Semi Condensed", "normal", "500", "barlow-semi-condensed-500-latin"),
    ("Barlow Semi Condensed", "normal", "600", "barlow-semi-condensed-600-latin"),
    ("Martian Mono", "normal", "400 500", "martian-mono-400-500-latin"),
]
FONT_BLOCK = re.compile(r'<!--@FONTS@-->|<style id="fonts">.*?</style>', re.S)
DESIGN_BLOCK = re.compile(r'<!--@DESIGN@-->|<style id="design" data-design="([a-z]+)">.*?</style>', re.S)
FIGURE_TYPES = ("timeline", "chart", "explore", "sequence", "matrix", "bars", "heatmap")
NEEDS_TEXT_VERSION = ("chart", "explore", "bars", "heatmap")
SEQUENCE_KINDS = ("call", "reply", "focus", "fail", "added")
MATRIX_VALUES = ("yes", "no", "part", "fail")
COLORS = ("blue", "green", "orange", "red", "ink", "grey")


def prose_with_json(html):
    html = re.sub(r"<style\b.*?</style>", "", html, flags=re.S)
    return re.sub(r"<script>.*?</script>", "", html, flags=re.S)


def is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def check_spec(kind, spec):
    errors = []
    if kind == "chart":
        n = len(spec["labels"])
        for view in spec["views"]:
            for series in view["series"]:
                if len(series["values"]) != n:
                    errors.append(f'chart series "{series["label"]}" has {len(series["values"])} values for {n} labels')
    elif kind == "bars":
        if not spec["views"]:
            errors.append("bars spec has no views")
        for view in spec["views"]:
            if not view["bars"]:
                errors.append(f'bars view "{view.get("name", "")}" has no bars')
            for bar in view["bars"]:
                if not is_number(bar["value"]):
                    errors.append(f'bar "{bar["label"]}" value must be a number, got {bar["value"]!r}')
                if bar.get("color", "grey") not in COLORS:
                    errors.append(f'bar "{bar["label"]}" color must be one of {", ".join(COLORS)}')
    elif kind == "heatmap":
        n = len(spec["columns"])
        for row in spec["rows"]:
            if len(row["values"]) != n:
                errors.append(f'heatmap row "{row["label"]}" has {len(row["values"])} values for {n} columns')
            if any(v is not None and not is_number(v) for v in row["values"]):
                errors.append(f'heatmap row "{row["label"]}" values must be numbers or null')
        for mark in spec.get("marks", []):
            if not 0 <= mark["at"] < n:
                errors.append(f'heatmap mark "{mark["label"]}" is outside the {n} columns')
        if spec.get("color", "orange") not in COLORS:
            errors.append(f'heatmap color must be one of {", ".join(COLORS)}')
    return errors


def font_style():
    faces = []
    for family, style, weight, name in FACES:
        encoded = base64.b64encode((FONTS / f"{name}.woff2").read_bytes()).decode()
        faces.append(
            f'@font-face {{ font-family: "{family}"; font-style: {style}; font-weight: {weight}; '
            f'font-display: swap; src: url(data:font/woff2;base64,{encoded}) format("woff2"); }}'
        )
    return '<style id="fonts">\n' + "\n".join(faces) + "\n</style>"


def design_style(design):
    css = (DESIGNS / f"{design}.css").read_text()
    return f'<style id="design" data-design="{design}">\n{css}</style>'


def parse_args(argv):
    args = argv[1:]
    design = None
    if "--design" in args:
        i = args.index("--design")
        if i + 1 >= len(args) or args[i + 1] not in DESIGN_NAMES:
            sys.exit(__doc__)
        design = args[i + 1]
        del args[i:i + 2]
    if len(args) != 1:
        sys.exit(__doc__)
    return Path(args[0]), design


def check(html):
    errors, warnings = [], []
    prose = re.sub(r"<(style|script)\b.*?</\1>", "", html, flags=re.S)

    for placeholder in sorted(set(re.findall(r"\{\{[^}]+\}\}", prose))):
        errors.append(f"placeholder left: {placeholder}")

    if "<!-- investigation:start -->" in html and "<!-- proposal:start -->" in html:
        errors.append("both section sets present: delete the investigation or proposal set")
    if "<!-- optional -->" in html:
        warnings.append("<!-- optional --> markers left: remove them, and any optional section that does not apply")

    ref_ids = [int(n) for n in re.findall(r'<li id="ref-(\d+)"', html)]
    if ref_ids != list(range(1, len(ref_ids) + 1)):
        errors.append(f"references must be numbered R1..Rn in order, found {ref_ids}")
    cited = [int(n) for n in re.findall(r'href="#ref-(\d+)"', prose)]
    cited += [int(n) for m in re.findall(r'data-refs="([^"]*)"', prose) for n in re.findall(r"\d+", m)]
    for n in sorted(set(cited) - set(ref_ids)):
        errors.append(f"R{n} is cited but has no reference entry")
    for n in sorted(set(ref_ids) - set(cited)):
        warnings.append(f"R{n} is never cited")
    main = prose[prose.find("<main"):]
    first_cited = [int(n) for m in re.findall(r'href="#ref-\d+"|data-refs="[^"]*"', main) for n in re.findall(r"\d+", m)]
    order = list(dict.fromkeys(first_cited))
    if order and order != sorted(order):
        warnings.append(f"references are not numbered in order of first citation: {order}")

    figs = [int(n) for n in re.findall(r'class="fig-num">FIG (\d+)<', prose)]
    if figs != list(range(1, len(figs) + 1)):
        errors.append(f"figures must be numbered FIG 1..N in order, found {figs}")
    for n in figs:
        if f'id="figure-{n}"' not in html:
            errors.append(f'FIG {n} has no id="figure-{n}"')
    figures = re.findall(r"<figure\b[^>]*>.*?</figure>", prose_with_json(html), re.S)
    kinds = [k for f in figures for k in re.findall(r"^<figure[^>]*\bdata-(" + "|".join(FIGURE_TYPES) + r")\b", f)]
    if len(kinds) < 2:
        warnings.append(f"{len(kinds)} interactive figure(s): a report needs at least two")
    for fig in figures:
        num = re.search(r'class="fig-num">FIG (\d+)<', fig)
        name = f"FIG {num.group(1)}" if num else "a figure"
        kind = re.match(r"<figure[^>]*\bdata-(" + "|".join(FIGURE_TYPES) + r")\b", fig)
        kind = kind.group(1) if kind else None
        if kind in NEEDS_TEXT_VERSION and 'class="sr-only"' not in fig:
            warnings.append(f'{name} ({kind}) has no <p class="sr-only"> text version')
        spec = re.search(r'<script type="application/json">(.*?)</script>', fig, re.S)
        if kind in ("chart", "bars", "heatmap"):
            if not spec:
                errors.append(f"{name} ({kind}) has no JSON spec")
                continue
            try:
                errors += [f"{name}: {e}" for e in check_spec(kind, json.loads(spec.group(1)))]
            except (ValueError, KeyError, TypeError) as e:
                errors.append(f"{name} ({kind}) spec is invalid: {e!r}")
        elif kind == "sequence":
            lanes = [s.strip() for s in (re.search(r'data-lanes="([^"]*)"', fig) or [None, ""])[1].split("|") if s.strip()]
            if not lanes:
                errors.append(f'{name} (sequence) has no data-lanes="A|B|…"')
            msgs = re.findall(r"<li\b([^>]*)>", fig)
            if not msgs:
                errors.append(f'{name} (sequence) has no <ol class="sq-data"> messages')
            for i, attrs in enumerate(msgs, 1):
                for end in ("from", "to"):
                    lane = re.search(rf'data-{end}="([^"]*)"', attrs)
                    if lane and lane.group(1) not in lanes:
                        errors.append(f'{name} message {i}: data-{end}="{lane.group(1)}" is not in data-lanes')
                if not re.search(r'data-from="', attrs):
                    errors.append(f"{name} message {i} has no data-from")
                if not re.search(r'data-refs="\s*\d', attrs):
                    warnings.append(f"{name} message {i} has no data-refs")
                k = re.search(r'data-kind="([^"]*)"', attrs)
                if k and k.group(1) not in SEQUENCE_KINDS:
                    errors.append(f'{name} message {i}: data-kind="{k.group(1)}" is not one of {", ".join(SEQUENCE_KINDS)}')
        elif kind == "matrix":
            values = re.findall(r'<td\b[^>]*\bdata-v="([^"]*)"', fig)
            if not values:
                errors.append(f'{name} (matrix) has no <td data-v="…"> cells')
            for v in sorted(set(values) - set(MATRIX_VALUES)):
                errors.append(f'{name} (matrix): data-v="{v}" is not one of {", ".join(MATRIX_VALUES)}')

    term_links = re.findall(r'<a class="term" href="#(term-[a-z0-9-]+)"', prose)
    term_ids = re.findall(r'<div id="(term-[a-z0-9-]+)"', prose)
    for t in sorted(set(term_links) - set(term_ids)):
        errors.append(f'<a class="term" href="#{t}"> has no glossary entry <div id="{t}">')
    for t in sorted(set(term_ids) - set(term_links)):
        warnings.append(f"glossary entry {t} is never linked from the text")
    if re.search(r'class="term"(?! href="#term-[a-z0-9-]+")', prose):
        errors.append('every <a class="term"> must be written as <a class="term" href="#term-slug">')
    if term_ids:
        names = [re.sub(r"<[^>]+>", "", d).strip().lower() for d in re.findall(r'<div id="term-[^"]+">\s*<dt>(.*?)</dt>', prose, re.S)]
        if names != sorted(names):
            warnings.append("glossary entries are not in alphabetical order")
        sec_ids = re.findall(r'<section id="([^"]+)"', prose)
        if "glossary" in sec_ids and "references" in sec_ids and sec_ids.index("glossary") != sec_ids.index("references") - 1:
            warnings.append("the glossary section belongs right before references")
    elif '<section id="glossary"' in prose:
        warnings.append("glossary section has no entries: add terms or delete the section")
    else:
        warnings.append("no glossary: add one for the terms a newcomer would need explained")

    text = re.sub(r"<[^>]+>", " ", prose)
    dashes = text.count("—")
    if dashes:
        warnings.append(f"{dashes} em dash(es) in the prose: use a period, comma or colon")
    if re.search(r'href="#"', prose):
        warnings.append('href="#" links left: link the real source or remove the link')

    return errors, warnings


def main():
    path, requested = parse_args(sys.argv)
    html = path.read_text()
    if not FONT_BLOCK.search(html):
        sys.exit(f"{path}: no <!--@FONTS@--> marker or fonts block; copy the page from assets/template.html")
    current = DESIGN_BLOCK.search(html)
    if current:
        design = requested or current.group(1) or DEFAULT_DESIGN
        html = DESIGN_BLOCK.sub(lambda _: design_style(design), html, count=1)
    elif requested:
        sys.exit(f"{path}: this page predates designs and keeps its inline styles; copy a fresh assets/template.html to use --design")
    else:
        design = "boltz"
    html = FONT_BLOCK.sub(lambda _: font_style() if design == "boltz" else "<!--@FONTS@-->", html, count=1)
    path.write_text(html)

    errors, warnings = check(html)
    if design != "boltz" and "data-dots=" in html:
        warnings.append("the dot-matrix title only shows in the boltz design: delete the data-dots line")
    for e in errors:
        print(f"error: {e}")
    for w in warnings:
        print(f"warning: {w}")
    print(f"{path}: {design} design, {len(errors)} error(s), {len(warnings)} warning(s)")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
