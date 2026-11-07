"use client";

import { motion } from "motion/react";
import { useEffect, useRef } from "react";
import { SectionHead } from "./ui";

/** Cursor-reactive particles, drawn only while visible and only if motion is OK. */
function Particles() {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const c = ref.current;
    const ctx = c?.getContext("2d");
    if (!c || !ctx || matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    let w = 0, h = 0, raf = 0, visible = false;
    const mouse = { x: -999, y: -999 };
    const dots = Array.from({ length: 70 }, (_, i) => ({ x: (i * 97) % 300, y: (i * 53) % 180, vx: ((i % 7) - 3) * 0.08, vy: ((i % 5) - 2) * 0.08 }));
    const size = () => {
      const r = c.getBoundingClientRect();
      w = r.width; h = r.height;
      c.width = w * devicePixelRatio; c.height = h * devicePixelRatio;
      ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
    };
    const accent = () => getComputedStyle(c).getPropertyValue("--accent").trim() || "#ff6a3d";
    const tick = () => {
      ctx.clearRect(0, 0, w, h);
      ctx.fillStyle = accent();
      for (const d of dots) {
        const dx = d.x - mouse.x, dy = d.y - mouse.y, dist = Math.hypot(dx, dy);
        if (dist < 60) { d.vx += dx / dist * 0.25; d.vy += dy / dist * 0.25; }
        d.vx *= 0.96; d.vy *= 0.96;
        d.x = (d.x + d.vx + 0.15 + w) % w; d.y = (d.y + d.vy + 0.1 + h) % h;
        ctx.beginPath(); ctx.arc(d.x, d.y, 2.2, 0, Math.PI * 2); ctx.fill();
      }
      if (visible) raf = requestAnimationFrame(tick);
    };
    const io = new IntersectionObserver(([e]) => {
      visible = e.isIntersecting;
      cancelAnimationFrame(raf);
      if (visible) raf = requestAnimationFrame(tick);
    });
    const move = (e: PointerEvent) => { const r = c.getBoundingClientRect(); mouse.x = e.clientX - r.left; mouse.y = e.clientY - r.top; };
    const leave = () => { mouse.x = mouse.y = -999; };
    size();
    io.observe(c);
    addEventListener("resize", size);
    c.addEventListener("pointermove", move);
    c.addEventListener("pointerleave", leave);
    return () => { io.disconnect(); cancelAnimationFrame(raf); removeEventListener("resize", size); c.removeEventListener("pointermove", move); c.removeEventListener("pointerleave", leave); };
  }, []);
  return <canvas ref={ref} className="wp-canvas" aria-hidden />;
}

const KINDS = [
  {
    k: "video", name: "Video", status: "Works now",
    line: "Any MP4 or MOV loops silently behind your windows, on every display.",
    cmd: "notchi wallpaper set ~/Movies/waves.mp4",
    art: <div className="wp-video" aria-hidden><i /><i /><i /></div>,
  },
  {
    k: "shader", name: "Shaders", status: "v1.0",
    line: "Rain, aurora, fluid and starfields drawn on the GPU in your theme colours.",
    cmd: "notchi wallpaper set aurora",
    art: <div className="wp-shader" aria-hidden />,
  },
  {
    k: "particles", name: "Particles", status: "v1.0",
    line: "Little lights that drift and scatter when your cursor comes close. Try it.",
    cmd: "notchi wallpaper set fireflies",
    art: <Particles />,
  },
];

const FACTS = [
  ["Pauses when covered", "If windows hide the desktop, the video stops. No hidden battery drain."],
  ["Low Power aware", "Low Power Mode or a low battery drops it to zero frames."],
  ["Every display", "Each screen gets its own window, set once."],
  ["Sound off", "Always muted, and it never keeps your Mac awake."],
];

export default function Wallpapers() {
  return (
    <section className="section" id="wallpaper-kinds" data-notch="Live wallpapers">
      <div className="wrap">
        <SectionHead
          eyebrow="Live wallpapers"
          title={"A desktop\nthat moves"}
          sub="Three kinds of wallpaper, all following your theme. Video works today. Shaders and particles come with v1.0."
        />
        <div className="wp-grid">
          {KINDS.map((k, i) => (
            <motion.article
              key={k.k}
              className="wp"
              initial={{ opacity: 0, y: 70, rotate: i === 1 ? 0 : i ? 3 : -3 }}
              whileInView={{ opacity: 1, y: 0, rotate: 0 }}
              viewport={{ once: true, amount: 0.3 }}
              transition={{ type: "spring", stiffness: 110, damping: 17, delay: i * 0.08 }}
            >
              <div className="wp-screen">
                {k.art}
                <span className="wp-notch" aria-hidden />
                <span className="wp-win" aria-hidden />
              </div>
              <div className="nc-top">
                <h3>{k.name}</h3>
                <span className={`tag${k.status === "Works now" ? " ok" : ""}`}>{k.status}</span>
              </div>
              <p>{k.line}</p>
              <code>$ {k.cmd}</code>
            </motion.article>
          ))}
        </div>
        <div className="wp-facts">
          {FACTS.map(([t, d], i) => (
            <motion.div key={t} initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.07 }}>
              <b>{t}</b>
              <span>{d}</span>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
