import { motionValue } from "motion/react";

/** 0 → 1 progress of the hero camera move, shared with the chrome. */
export const heroProgress = motionValue(0);
/** 1 once the hero has mostly scrolled off screen. */
export const heroPast = motionValue(0);
