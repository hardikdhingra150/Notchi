"use client";

import Lenis from "lenis";
import { usePathname } from "next/navigation";
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

/** Freeze page scrolling while a dialog is open. */
export function setScrollLocked(locked: boolean) {
  if (lenis) { if (locked) lenis.stop(); else lenis.start(); }
  document.documentElement.style.overflow = locked ? "hidden" : "";
}

export default function SmoothScroll() {
  const pathname = usePathname();

  // new page: start at the top (or at #hash), and let Lenis re-measure the new height
  useEffect(() => {
    const hash = location.hash;
    requestAnimationFrame(() => {
      lenis?.resize();
      if (hash && document.querySelector(hash)) scrollTo(hash, 1.2);
      else if (lenis) lenis.scrollTo(0, { immediate: true });
      else window.scrollTo(0, 0);
    });
  }, [pathname]);

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
