#!/usr/bin/env python3
"""Turn a plain-text plan spec into an Excalidraw scene and open it in the browser.

usage: mkplan.py SPEC [--out DIR] [--no-open]

Spec format (one section per `section:` line, sections render left to right):

    title: Add caching to fetch layer

    section: Steps
    1. Add lru_cache to fetch() | api/fetch.py
    2. Add one test | tests/test_fetch.py
    3. Delete CacheManager | api/cache.py

    section: Architecture
    [client] Client
    [api] API server
    [db] Postgres
    client -> api : HTTP
    api -> db : on miss

    section: Notes
    - Skipped: TTL. Add when the profiler says so.

Numbered lines become a top-to-bottom chain of boxes. `[id] label` lines are
graph nodes, `a -> b : label` lines are edges, laid out in layers. `- text`
lines are free text under the section. `| detail` after any box label is a
second, smaller line inside the box.
"""

import hashlib
import json
import os
import random
import subprocess
import sys
import time

FONT = 1            # Virgil; the 0.17 viewer renders no other hand font
FONT_SIZE = 20
DETAIL_SIZE = 16
CHAR_W = 0.62       # rough glyph width, fraction of font size
PAD_X, PAD_Y = 24, 16
GAP_X, GAP_Y = 60, 70
SECTION_GAP = 160
STROKE = "#1e1e1e"
FILLS = ["#a5d8ff", "#b2f2bb", "#ffec99", "#ffc9c9", "#d0bfff", "#ffd8a8"]

random.seed(7)


def rid():
    return "".join(random.choice("abcdefghijklmnopqrstuvwxyz0123456789") for _ in range(12))


def nonce():
    return random.randint(1, 2**31 - 1)


def base(el_type, x, y, w, h, **extra):
    el = {
        "id": rid(), "type": el_type, "x": x, "y": y, "width": w, "height": h,
        "angle": 0, "strokeColor": STROKE, "backgroundColor": "transparent",
        "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
        "roughness": 1, "opacity": 100, "groupIds": [], "frameId": None,
        "roundness": None, "seed": nonce(), "version": 1, "versionNonce": nonce(),
        "isDeleted": False, "boundElements": [], "updated": int(time.time() * 1000),
        "link": None, "locked": False,
    }
    el.update(extra)
    return el


def text_el(text, x, y, size=FONT_SIZE, container=None, align="center", color=STROKE):
    lines = text.split("\n")
    w = max(len(l) for l in lines) * size * CHAR_W
    h = len(lines) * size * 1.25
    return base(
        "text", x, y, w, h, text=text, originalText=text, fontSize=size, fontFamily=FONT,
        textAlign=align, verticalAlign="middle" if container else "top",
        containerId=container, lineHeight=1.25, baseline=size, strokeColor=color,
    )


def box(label, detail, fill):
    lines = [label] + ([detail] if detail else [])
    w = max(len(l) for l in lines) * FONT_SIZE * CHAR_W + 2 * PAD_X
    h = len(lines) * FONT_SIZE * 1.25 + 2 * PAD_Y
    w, h = max(w, 140), max(h, 60)
    rect = base("rectangle", 0, 0, w, h, backgroundColor=fill, roundness={"type": 3})
    txt = text_el("\n".join(lines), 0, 0, container=rect["id"])
    rect["boundElements"].append({"id": txt["id"], "type": "text"})
    return rect, txt


def place(rect, txt, x, y):
    rect["x"], rect["y"] = x, y
    txt["x"] = x + (rect["width"] - txt["width"]) / 2
    txt["y"] = y + (rect["height"] - txt["height"]) / 2


def arrow(src, dst, label):
    sx, sy = src["x"] + src["width"] / 2, src["y"] + src["height"]
    dx, dy = dst["x"] + dst["width"] / 2, dst["y"]
    if dy < sy:  # target above or level: leave from the side instead
        sx, sy = src["x"] + src["width"], src["y"] + src["height"] / 2
        dx, dy = dst["x"], dst["y"] + dst["height"] / 2
    a = base(
        "arrow", sx, sy, dx - sx, dy - sy, points=[[0, 0], [dx - sx, dy - sy]],
        startBinding={"elementId": src["id"], "focus": 0, "gap": 4},
        endBinding={"elementId": dst["id"], "focus": 0, "gap": 4},
        startArrowhead=None, endArrowhead="arrow", elbowed=False, lastCommittedPoint=None,
        roundness={"type": 2},
    )
    src["boundElements"].append({"id": a["id"], "type": "arrow"})
    dst["boundElements"].append({"id": a["id"], "type": "arrow"})
    out = [a]
    if label:
        t = text_el(label, 0, 0, size=DETAIL_SIZE, container=a["id"])
        t["x"] = sx + (dx - sx) / 2 - t["width"] / 2
        t["y"] = sy + (dy - sy) / 2 - t["height"] / 2
        a["boundElements"].append({"id": t["id"], "type": "text"})
        out.append(t)
    return out


def parse(path):
    title, sections, cur = "Plan", [], None
    for raw in open(path, encoding="utf-8"):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.lower().startswith("title:"):
            title = line[6:].strip()
            continue
        if line.lower().startswith("section:"):
            cur = {"name": line[8:].strip(), "steps": [], "nodes": [], "edges": [], "notes": []}
            sections.append(cur)
            continue
        if cur is None:
            cur = {"name": "Plan", "steps": [], "nodes": [], "edges": [], "notes": []}
            sections.append(cur)
        if line.startswith("- "):
            cur["notes"].append(line[2:].strip())
        elif "->" in line and not line.startswith("["):
            lhs, _, rest = line.partition("->")
            to, _, label = rest.partition(":")
            cur["edges"].append((lhs.strip(), to.strip(), label.strip()))
        elif line.startswith("["):
            nid, _, label = line[1:].partition("]")
            label, _, detail = label.partition("|")
            cur["nodes"].append((nid.strip(), label.strip(), detail.strip()))
        else:
            head = line.split(".", 1)
            if head[0].strip().isdigit() and len(head) == 2:
                line = head[1]
            label, _, detail = line.partition("|")
            cur["steps"].append((label.strip(), detail.strip()))
    return title, sections


def layers_of(nodes, edges):
    ids = [n[0] for n in nodes]
    succ = {i: [] for i in ids}
    for a, b, _ in edges:
        if a in succ and b in succ:
            succ[a].append(b)
    depth, state = {}, {}

    def visit(n, d):
        if state.get(n) == 1:
            return
        state[n] = 1
        depth[n] = max(depth.get(n, 0), d)
        for m in succ[n]:
            if state.get(m) != 1:
                visit(m, d + 1)
        state[n] = 2

    for n in ids:
        if n not in depth:
            visit(n, 0)
    layers = {}
    for n in ids:
        layers.setdefault(depth[n], []).append(n)
    return [layers[k] for k in sorted(layers)]


def render_section(sec, x0, y0, color_idx, elements):
    title = text_el(sec["name"].upper(), x0, y0, size=24, align="left")
    elements.append(title)
    y = y0 + 50
    fill = FILLS[color_idx % len(FILLS)]
    width = title["width"]

    if sec["steps"]:
        prev = None
        for i, (label, detail) in enumerate(sec["steps"], 1):
            r, t = box(f"{i}. {label}", detail, fill)
            place(r, t, x0, y)
            elements += [r, t]
            if prev is not None:
                elements += arrow(prev, r, "")
            prev = r
            width = max(width, r["width"])
            y += r["height"] + GAP_Y

    if sec["nodes"]:
        boxes, texts = {}, {}
        for nid, label, detail in sec["nodes"]:
            boxes[nid], texts[nid] = box(label, detail, FILLS[(color_idx + 2) % len(FILLS)])
        for layer in layers_of(sec["nodes"], sec["edges"]):
            x = x0
            row_h = 0
            for nid in layer:
                place(boxes[nid], texts[nid], x, y)
                x += boxes[nid]["width"] + GAP_X
                row_h = max(row_h, boxes[nid]["height"])
            width = max(width, x - GAP_X - x0)
            y += row_h + GAP_Y
        for nid in boxes:
            elements += [boxes[nid], texts[nid]]
        for a, b, label in sec["edges"]:
            if a in boxes and b in boxes:
                elements += arrow(boxes[a], boxes[b], label)

    for note in sec["notes"]:
        t = text_el(note, x0, y, size=DETAIL_SIZE, align="left", color="#495057")
        elements.append(t)
        width = max(width, t["width"])
        y += t["height"] + 10

    return width


def build(title, sections):
    elements = [text_el(title, 0, 0, size=36, align="left")]
    x = 0
    for i, sec in enumerate(sections):
        w = render_section(sec, x, 90, i, elements)
        x += w + SECTION_GAP
    return {
        "type": "excalidraw", "version": 2, "source": "mkplan.py",
        "elements": elements,
        "appState": {"viewBackgroundColor": "#ffffff", "gridSize": None},
        "files": {},
    }


HTML = """<!doctype html><html><head><meta charset="utf-8"><title>%(title)s</title>
<style>html,body,#app{margin:0;height:100%%;width:100%%}</style>
<script>window.EXCALIDRAW_ASSET_PATH="https://unpkg.com/@excalidraw/excalidraw@0.17.6/dist/";</script>
<script src="https://unpkg.com/react@18.3.1/umd/react.production.min.js"></script>
<script src="https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js"></script>
<script src="https://unpkg.com/@excalidraw/excalidraw@0.17.6/dist/excalidraw.production.min.js"></script>
</head><body><div id="app"></div>
<script>
const scene = %(scene)s;
const el = React.createElement(ExcalidrawLib.Excalidraw, {
  initialData: { elements: scene.elements, appState: scene.appState },
  excalidrawAPI: (api) => setTimeout(() => api.scrollToContent(api.getSceneElements(), { fitToViewport: true, viewportZoomFactor: 0.85 }), 300),
});
ReactDOM.createRoot(document.getElementById("app")).render(el);
</script></body></html>
"""


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)
    spec = args[0]
    out_dir = os.path.expanduser("~/.claude/plans/viz")
    do_open = "--no-open" not in args
    if "--out" in args:
        out_dir = args[args.index("--out") + 1]
    os.makedirs(out_dir, exist_ok=True)

    title, sections = parse(spec)
    scene = build(title, sections)

    stem = "".join(c if c.isalnum() else "-" for c in title.lower()).strip("-")[:60] or "plan"
    exc = os.path.join(out_dir, stem + ".excalidraw")
    html = os.path.join(out_dir, stem + ".html")
    with open(exc, "w", encoding="utf-8") as f:
        json.dump(scene, f, indent=1)
    with open(html, "w", encoding="utf-8") as f:
        f.write(HTML % {"title": title, "scene": json.dumps(scene)})

    marker_dir = os.path.expanduser("~/.claude/plan-viz")
    os.makedirs(marker_dir, exist_ok=True)
    key = hashlib.sha1(os.getcwd().encode()).hexdigest()[:16]
    with open(os.path.join(marker_dir, key), "w") as f:
        f.write(html + "\n")

    print(exc)
    print(html)
    if do_open and sys.platform == "darwin":
        if subprocess.call(["open", "-a", "Brave Browser", html]) != 0:
            subprocess.call(["open", html])


if __name__ == "__main__":
    main()
