/**
 * Playback and controls. Plumbing: a deck should never need to edit this file.
 */

import { Engine, SNAP } from "./engine.js";
import { ACTS, DECK, SCENES } from "./scenes/index.js";

const AUTOPLAY_MS = 9000;

const engine = new Engine(document.getElementById("stage"));

const narration = document.getElementById("narration");
const elIndex = document.getElementById("scene-index");
const elTitle = document.getElementById("scene-title");
const elText = document.getElementById("scene-text");
const elNow = document.getElementById("count-now");
const elAll = document.getElementById("count-all");
const rail = document.getElementById("rail");
const cover = document.getElementById("cover");
const coverLead = document.getElementById("cover-lead");
const elAct = document.getElementById("act-label");

const btnPrev = document.getElementById("btn-prev");
const btnNext = document.getElementById("btn-next");
const btnPlay = document.getElementById("btn-play");
const playGlyph = document.getElementById("play-glyph");

let current = -1;
let timer = null;

/* ---------------------------------------------------------------- identity */

// `?static` and reduce-motion also have to stop the CSS entrance animations,
// or a capture catches the cover and the narration part-way through a fade.
if (SNAP) document.body.classList.add("is-static");

document.title = DECK.title;
document.getElementById("deck-mark").textContent = DECK.mark;
document.getElementById("cover-mark").textContent = DECK.mark;

/* ------------------------------------------------------------------- rail */

let index = 0;
for (const act of ACTS) {
  if (act.numeral) {
    const head = document.createElement("li");
    head.className = "rail__act";
    head.textContent = act.numeral;
    rail.appendChild(head);
  }

  for (const scene of act.scenes) {
    const i = index++;
    const li = document.createElement("li");
    li.innerHTML = `<span class="rail__name">${scene.rail}</span><span class="rail__tick"></span>`;
    li.addEventListener("click", () => {
      stop();
      go(i);
    });
    rail.appendChild(li);
  }
}

/** Only the scene rows are selectable; act headings are labels. */
const railRows = [...rail.querySelectorAll("li:not(.rail__act)")];

elAll.textContent = SCENES.length;

/* ---------------------------------------------------------------- playback */

function go(i) {
  const next = Math.max(0, Math.min(SCENES.length - 1, i));
  if (next === current) return;

  current = next;
  const scene = SCENES[current];

  engine.show(scene);

  // A cover scene carries its own typography and hides the narration entirely.
  document.body.classList.toggle("is-cover", Boolean(scene.cover));
  cover.hidden = !scene.cover;
  if (scene.cover) coverLead.innerHTML = scene.cover;

  elIndex.textContent = String(current + 1).padStart(2, "0");
  elTitle.textContent = scene.title ?? "";
  elText.innerHTML = scene.text ?? "";
  elNow.textContent = current + 1;

  if (!SNAP && !scene.cover) {
    narration.classList.remove("is-entering");
    void narration.offsetWidth; // restart the staggered reveal
    narration.classList.add("is-entering");
  }

  railRows.forEach((li, n) => li.classList.toggle("is-active", n === current));
  elAct.textContent = scene.act;

  btnPrev.disabled = current === 0;
  btnNext.disabled = current === SCENES.length - 1;

  location.hash = scene.id;
}

function advance() {
  if (current >= SCENES.length - 1) return stop();
  go(current + 1);
}

function play() {
  if (current >= SCENES.length - 1) go(0);
  timer = setInterval(advance, AUTOPLAY_MS);
  playGlyph.innerHTML = "&#10073;&#10073;";
  btnPlay.classList.add("is-playing");
}

function stop() {
  clearInterval(timer);
  timer = null;
  playGlyph.innerHTML = "&#9654;";
  btnPlay.classList.remove("is-playing");
}

/* ---------------------------------------------------------------- controls */

btnPrev.addEventListener("click", () => {
  stop();
  go(current - 1);
});

btnNext.addEventListener("click", () => {
  stop();
  go(current + 1);
});

btnPlay.addEventListener("click", () => (timer ? stop() : play()));

window.addEventListener("keydown", (e) => {
  const keys = {
    ArrowRight: () => go(current + 1),
    ArrowLeft: () => go(current - 1),
    " ": () => go(current + 1),
    Home: () => go(0),
    End: () => go(SCENES.length - 1),
  };

  if (e.key === "p") return timer ? stop() : play();
  if (!keys[e.key]) return;

  e.preventDefault();
  stop();
  keys[e.key]();
});

/* ------------------------------------------------------------------- start */

const fromHash = SCENES.findIndex((s) => s.id === location.hash.slice(1));
go(fromHash >= 0 ? fromHash : 0);
