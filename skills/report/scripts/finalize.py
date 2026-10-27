#!/usr/bin/env python3
"""Embed the report fonts into a report HTML file and check it.

Usage: python3 finalize.py <report.html>

Replaces <!--@FONTS@--> (or a previous <style id="fonts"> block) with the
woff2 files from assets/fonts as data URIs, so the page loads nothing from
outside the file. Then checks citations, placeholders, figures and prose.
Exits 1 if there are errors. Safe to run again after every edit.
"""
import base64
import json
import re
import sys
from pathlib import Path

FONTS = Path(__file__).resolve().parent.parent / "assets" / "fonts"
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


def font_style():
    faces = []
    for family, style, weight, name in FACES:
        encoded = base64.b64encode((FONTS / f"{name}.woff2").read_bytes()).decode()
        faces.append(
            f'@font-face {{ font-family: "{family}"; font-style: {style}; font-weight: {weight}; '
            f'font-display: swap; src: url(data:font/woff2;base64,{encoded}) format("woff2"); }}'
        )
    return '<style id="fonts">\n' + "\n".join(faces) + "\n</style>"


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
    interactive = len(re.findall(r"<figure[^>]*\bdata-(timeline|chart|explore)\b", html))
    if interactive < 2:
        warnings.append(f"{interactive} interactive figure(s): a report needs at least two")

    for spec in re.findall(r'<figure[^>]*data-chart[^>]*>.*?<script type="application/json">(.*?)</script>', html, re.S):
        try:
            chart = json.loads(spec)
            n = len(chart["labels"])
            for view in chart["views"]:
                for series in view["series"]:
                    if len(series["values"]) != n:
                        errors.append(f'chart series "{series["label"]}" has {len(series["values"])} values for {n} labels')
        except (ValueError, KeyError) as e:
            errors.append(f"chart spec is invalid: {e}")

    text = re.sub(r"<[^>]+>", " ", prose)
    dashes = text.count("—")
    if dashes:
        warnings.append(f"{dashes} em dash(es) in the prose: use a period, comma or colon")
    if re.search(r'href="#"', prose):
        warnings.append('href="#" links left: link the real source or remove the link')

    return errors, warnings


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    path = Path(sys.argv[1])
    html = path.read_text()
    if not FONT_BLOCK.search(html):
        sys.exit(f"{path}: no <!--@FONTS@--> marker or fonts block; copy the page from assets/template.html")
    html = FONT_BLOCK.sub(lambda _: font_style(), html, count=1)
    path.write_text(html)

    errors, warnings = check(html)
    for e in errors:
        print(f"error: {e}")
    for w in warnings:
        print(f"warning: {w}")
    print(f"{path}: fonts embedded, {len(errors)} error(s), {len(warnings)} warning(s)")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
