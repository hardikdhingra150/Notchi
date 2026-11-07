"use client";

import { useEffect, useRef } from "react";

const out = (k: number) => 1 - (1 - k) ** 3;

/** Ink ring cursor that eases to the pointer and pings on click. */
export default function Cursor() {
  const cur = useRef<HTMLDivElement>(null);
  const ping = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!matchMedia("(hover: hover) and (pointer: fine)").matches) return;
    const html = document.documentElement;
    html.classList.add("fine");
    let x = innerWidth / 2, y = innerHeight / 2, cx = x, cy = y, s = 1;
    let down = false, overLink = false, last = performance.now();
    let px = 0, py = 0, pT = -1e9, raf = 0, seen = false;

    const move = (e: PointerEvent) => {
      x = e.clientX; y = e.clientY;
      if (!seen) { cx = x; cy = y; seen = true; }
      overLink = !!(e.target as Element)?.closest?.("a,button,[role=button],[data-hover]");
    };
    const press = (e: PointerEvent) => { down = true; px = e.clientX; py = e.clientY; pT = performance.now(); };
    const up = () => { down = false; };
    addEventListener("pointermove", move, { passive: true });
    addEventListener("pointerdown", press);
    addEventListener("pointerup", up);

    const loop = (now: number) => {
      const dt = Math.min((now - last) / 1000, 0.05); last = now;
      const f = 1 - Math.exp(-dt * 22);
      cx += (x - cx) * f; cy += (y - cy) * f;
      const target = down ? 0.7 : overLink ? 1.45 : 1;
      s += (target - s) * (1 - Math.exp(-dt * 16));
      if (cur.current) {
        cur.current.style.transform = `translate(${cx}px,${cy}px) scale(${s})`;
        cur.current.style.opacity = seen ? "1" : "0";
      }
      const k = Math.min((now - pT) / 650, 1);
      if (ping.current) {
        ping.current.style.transform = `translate(${px}px,${py}px) scale(${1 + out(k) * 1.9})`;
        ping.current.style.opacity = String(k < 1 ? 1 - k : 0);
      }
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => {
      cancelAnimationFrame(raf);
      removeEventListener("pointermove", move);
      removeEventListener("pointerdown", press);
      removeEventListener("pointerup", up);
      html.classList.remove("fine");
    };
  }, []);

  return (
    <>
      <div id="ping" ref={ping} aria-hidden />
      <div id="cur" ref={cur} aria-hidden />
    </>
  );
}
