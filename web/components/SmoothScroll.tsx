"use client";

import Lenis from "lenis";
import { useEffect } from "react";

let lenis: Lenis | null = null;

/** Scroll to a selector, element or y offset. Uses Lenis when it is running. */
export function scrollTo(target: string | number | HTMLElement, duration = 1.6) {
  if (lenis) {
    lenis.scrollTo(target, { duration, easing: (t) => (t < 0.5 ? 4 * t ** 3 : 1 - (-2 * t + 2) ** 3 / 2) });
    return;
  }
  const el = typeof target === "string" ? document.querySelector<HTMLElement>(target) : target;
  const top = typeof el === "number" ? el : el ? el.getBoundingClientRect().top + scrollY : 0;
  window.scrollTo({ top, behavior: "smooth" });
}

export default function SmoothScroll() {
  useEffect(() => {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    lenis = new Lenis({ autoRaf: true, lerp: 0.085, wheelMultiplier: 0.9 });
    return () => {
      lenis?.destroy();
      lenis = null;
    };
  }, []);
  return null;
}
