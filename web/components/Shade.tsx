"use client";

import { useEffect, useRef } from "react";

/**
 * Soft window-blind light drifting over the whole page.
 * A tiny 64×36 canvas stretched to full screen, so its low resolution is the blur.
 */
export default function Shade() {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const c = ref.current;
    if (!c) return;
    const g = c.getContext("2d");
    if (!g) return;
    g.fillStyle = "#fff";
    g.fillRect(0, 0, 64, 36);
    g.fillStyle = "rgba(118,110,92,.9)";
    // slanted blind slats falling across the desk
    for (let i = -2; i < 9; i++) {
      const x = i * 9;
      g.beginPath();
      g.moveTo(x, 0);
      g.lineTo(x + 3.2, 0);
      g.lineTo(x + 17, 36);
      g.lineTo(x + 13.6, 36);
      g.closePath();
      g.fill();
    }
    // window frame shadow
    g.fillStyle = "rgba(118,110,92,.55)";
    g.fillRect(40, 0, 2, 36);

    const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced) return;
    let raf = 0;
    const t0 = performance.now();
    const loop = (now: number) => {
      const t = (now - t0) / 1000;
      c.style.transform = `translate(${Math.sin(t * 0.3) * 2}%,${Math.cos(t * 0.23) * 1.4}%) rotate(${Math.sin(t * 0.19) * 0.8}deg)`;
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, []);

  return <canvas id="shade" ref={ref} width={64} height={36} aria-hidden />;
}
