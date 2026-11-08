"use client";

import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { WALLPAPERS, WALLPAPER_THEME_COLORS, type Wallpaper } from "@/lib/wallpapers";
import { Check, Copy, Down } from "./icons";
import { setScrollLocked } from "./SmoothScroll";
import { SectionHead } from "./ui";

const FILTERS = ["All", "Shader", "Particles", "Paper", "Midnight", "Matcha", "Sakura", "Neon Rain"] as const;
type Filter = (typeof FILTERS)[number];

/** A tile that only plays while it's on screen (or hovered), so 14 videos cost almost nothing. */
function Tile({ w, i, onOpen }: { w: Wallpaper; i: number; onOpen: () => void }) {
  const vid = useRef<HTMLVideoElement>(null);
  useEffect(() => {
    const v = vid.current;
    if (!v) return;
    const io = new IntersectionObserver(([e]) => {
      if (e.isIntersecting) v.play().catch(() => {}); else v.pause();
    }, { threshold: 0.35 });
    io.observe(v);
    return () => io.disconnect();
  }, []);

  return (
    <motion.button
      layout
      className="wg-tile"
      onClick={onOpen}
      initial={{ opacity: 0, y: 40, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, scale: 0.94 }}
      transition={{ type: "spring", stiffness: 150, damping: 20, delay: (i % 6) * 0.04 }}
      whileHover={{ y: -6 }}
      aria-label={`Preview ${w.name}`}
    >
      <span className="wg-media">
        <video ref={vid} src={`/wallpapers/${w.id}-preview.mp4`} poster={`/wallpapers/${w.id}.jpg`} muted loop playsInline preload="none" />
        <span className="wg-notch" aria-hidden />
        <span className="wg-play" aria-hidden>Preview</span>
      </span>
      <span className="wg-meta">
        <b>{w.name}</b>
        <span className="wg-tags">
          <em>{w.kind}</em>
          <i style={{ background: WALLPAPER_THEME_COLORS[w.theme] }} title={`${w.theme} theme`} />
        </span>
      </span>
      <span className="wg-line">{w.line}</span>
    </motion.button>
  );
}

function Preview({ w, onClose, onStep }: { w: Wallpaper; onClose: () => void; onStep: (d: number) => void }) {
  const [copied, setCopied] = useState(false);
  const cmd = `notchi wallpaper set ~/Downloads/notchi-${w.id}.mp4`;

  useEffect(() => {
    setScrollLocked(true);
    const key = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
      else if (e.key === "ArrowRight") onStep(1);
      else if (e.key === "ArrowLeft") onStep(-1);
    };
    addEventListener("keydown", key);
    return () => { removeEventListener("keydown", key); setScrollLocked(false); };
  }, [onClose, onStep]);

  return (
    <motion.div className="wg-modal" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onMouseDown={onClose}>
      <motion.div
        className="wg-sheet"
        role="dialog"
        aria-modal="true"
        aria-label={`${w.name} wallpaper preview`}
        initial={{ y: 40, scale: 0.96 }}
        animate={{ y: 0, scale: 1 }}
        exit={{ y: 30, scale: 0.97 }}
        transition={{ type: "spring", stiffness: 260, damping: 28 }}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="wg-mac">
          <AnimatePresence mode="popLayout">
            <motion.video
              key={w.id}
              src={`/wallpapers/${w.id}.mp4`}
              poster={`/wallpapers/${w.id}.jpg`}
              autoPlay muted loop playsInline
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              transition={{ duration: 0.4 }}
            />
          </AnimatePresence>
          <div className="wg-menubar"><span className="wg-apple" /><b>Finder</b><span>File</span><span>Edit</span><span>View</span><span className="wg-mb-r">9:41</span></div>
          <div className="wg-island"><i style={{ background: WALLPAPER_THEME_COLORS[w.theme] }} /><span className="m-eq">{[0, 1, 2, 3].map((k) => <i key={k} style={{ animationDelay: `${k * 0.14}s` }} />)}</span></div>
          <div className="wg-window"><span /><span /><span /></div>
          <div className="wg-dock">{["#ff6a3d", "#8f7cff", "#4f9a3a", "#e2507f", "#ffc64a"].map((c) => <i key={c} style={{ background: c }} />)}</div>
          <button className="wg-arrow l" onClick={() => onStep(-1)} aria-label="Previous wallpaper">‹</button>
          <button className="wg-arrow r" onClick={() => onStep(1)} aria-label="Next wallpaper">›</button>
        </div>
        <div className="wg-bar">
          <div>
            <b>{w.name}</b>
            <span>{w.line} · {w.kind} · goes with {w.theme === "Any" ? "any theme" : w.theme}</span>
          </div>
          <div className="wg-actions">
            <a className="pill hot sm" href={`/wallpapers/${w.id}.mp4`} download={`notchi-${w.id}.mp4`}><Down /> Download 1080p</a>
            <button className="wg-cmd" onClick={() => { navigator.clipboard?.writeText(cmd).catch(() => {}); setCopied(true); setTimeout(() => setCopied(false), 1400); }}>
              <code>$ {cmd}</code>
              {copied ? <Check width={15} height={15} /> : <Copy width={15} height={15} />}
            </button>
            <button className="wg-close" onClick={onClose} aria-label="Close preview">×</button>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
}

export default function WallpaperGallery() {
  const [f, setF] = useState<Filter>("All");
  const [open, setOpen] = useState<string | null>(null);
  const list = WALLPAPERS.filter((w) => f === "All" || w.kind === f || w.theme === f);
  const current = list.find((w) => w.id === open) ?? WALLPAPERS.find((w) => w.id === open) ?? null;

  const step = useCallback((d: number) => {
    setOpen((id) => {
      const i = list.findIndex((w) => w.id === id);
      return list[(i + d + list.length) % list.length]?.id ?? id;
    });
  }, [list]);
  const close = useCallback(() => setOpen(null), []);

  return (
    <section className="section" id="library" data-notch="Wallpaper library">
      <div className="wrap">
        <div className="mod-head">
          <SectionHead
            eyebrow={`Wallpaper library · ${WALLPAPERS.length} loops`}
            title={"Pick one,\nit's yours"}
            sub="Every wallpaper here is a seamless 6-second loop made for Notchi. Preview it on a Mac, download it in 1080p and set it with one command. Free, like everything else."
          />
        </div>
        <div className="wg-filters" role="tablist" aria-label="Filter wallpapers">
          {FILTERS.map((x) => (
            <button key={x} role="tab" aria-selected={f === x} className={`chip${f === x ? " on" : ""}`} onClick={() => setF(x)}>
              {x !== "All" && x !== "Shader" && x !== "Particles" && <i className="wg-dot" style={{ background: WALLPAPER_THEME_COLORS[x] }} />}
              {x}
            </button>
          ))}
        </div>
        <motion.div className="wg-grid" layout>
          <AnimatePresence mode="popLayout">
            {list.map((w, i) => <Tile key={w.id} w={w} i={i} onOpen={() => setOpen(w.id)} />)}
          </AnimatePresence>
        </motion.div>
        <p className="wg-note">Native shader and particle wallpapers (drawn live on the GPU, in your theme&apos;s colours) arrive in v1.0. Until then these loops work with Notchi&apos;s video wallpaper today.</p>
      </div>
      <AnimatePresence>{current && <Preview key="pv" w={current} onClose={close} onStep={step} />}</AnimatePresence>
    </section>
  );
}
