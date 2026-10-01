/**
 * The narrative, assembled.
 *
 * Acts are separate modules so each stays readable. This flattens them into the
 * single ordered list the engine steps through, stamping each scene with its
 * act so the masthead and the rail can group them.
 */

import { ACT1 } from "./act1.js";

/** The wordmark in the masthead and on the cover, plus the browser tab title. */
export const DECK = {
  mark: "Request",
  title: "Request: the life of one HTTP call",
};

export const ACTS = [
  // `numeral` is the heading drawn above the act's scenes in the rail. Leave it
  // empty to run an act's scenes straight on with no heading.
  { numeral: "I", label: "The path of one request", scenes: ACT1 },
  // Add acts by adding files beside act1.js:
  // { numeral: "II", label: "Under load", scenes: ACT2 },
];

export const SCENES = ACTS.flatMap((act) => act.scenes.map((scene) => ({ ...scene, act: act.label })));
