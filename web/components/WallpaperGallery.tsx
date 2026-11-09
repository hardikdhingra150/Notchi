"use client";

import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { COLLECTIONS, WALLPAPERS, WALLPAPER_THEME_COLORS, type Collection, type Wallpaper } from "@/lib/wallpapers";
import { Check, Copy, Down } from "./icons";
import { Folder } from "./IconStudio";
import { scrollTo, setScrollLocked } from "./SmoothScroll";
import { SectionHead } from "./ui";

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
          <Desk />
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

/** Desktop icons on the mock Mac, so you can judge how readable a wallpaper keeps them. */
const DESK = [
  { name: "Projects", kind: "folder", tint: "#4aa3ff" },
  { name: "Screenshots", kind: "folder", tint: "#4aa3ff" },
  { name: "Design", kind: "folder", tint: "#8f7cff" },
  { name: "Notes.txt", kind: "file", tint: "" },
  { name: "Notchi.dmg", kind: "disk", tint: "" },
] as const;

function Desk() {
  return (
    <div className="wg-desk" aria-hidden>
      {DESK.map((d) => (
        <span key={d.name} className="wg-di">
          {d.kind === "folder" ? <Folder tint={d.tint} emoji="" /> : <i className={`wg-doc ${d.kind}`} />}
          <b>{d.name}</b>
        </span>
      ))}
    </div>
  );
}

/** A collection's banner: its best wallpaper playing full width behind a title in the collection's own style. */
function Banner({ c, count, onOpen }: { c: Collection; count: number; onOpen: () => void }) {
  const vid = useRef<HTMLVideoElement>(null);
  useEffect(() => {
    const v = vid.current;
    if (!v) return;
    const io = new IntersectionObserver(([e]) => { if (e.isIntersecting) v.play().catch(() => {}); else v.pause(); }, { threshold: 0.2 });
    io.observe(v);
    return () => io.disconnect();
  }, []);
  return (
    <motion.div
      className={`wc-banner ${c.id}`}
      initial={{ opacity: 0, y: 50, scale: 0.98 }}
      whileInView={{ opacity: 1, y: 0, scale: 1 }}
      viewport={{ once: true, amount: 0.3 }}
      transition={{ type: "spring", stiffness: 90, damping: 18 }}
    >
      <video ref={vid} src={`/wallpapers/${c.hero}.mp4`} poster={`/wallpapers/${c.hero}.jpg`} muted loop playsInline preload="none" aria-hidden />
      <div className="wc-shade" aria-hidden />
      {c.id === "spellbound" && <div className="wc-sparks" aria-hidden>{Array.from({ length: 18 }, (_, i) => <i key={i} style={{ left: `${(i * 37) % 100}%`, animationDelay: `${(i % 6) * 0.7}s` }} />)}</div>}
      <div className="wc-copy">
        <span className="wc-kicker">{c.emoji} Collection · {count} wallpapers{c.note ? ` · ${c.note}` : ""}</span>
        <h3 className="wc-title">{title(c.name)}</h3>
        <p className="wc-tag">{c.tagline}</p>
        <button className="wc-cta" onClick={onOpen}>Preview on a Mac →</button>
      </div>
    </motion.div>
  );
}

/** "Golden Hour" → Golden <em>Hour</em>: the last word gets the accent in collections that style it. */
const title = (name: string) => {
  const i = name.lastIndexOf(" ");
  return i < 0 ? name : <>{name.slice(0, i)} <em>{name.slice(i + 1)}</em></>;
};

export default function WallpaperGallery() {
  const [open, setOpen] = useState<string | null>(null);
  const current = WALLPAPERS.find((w) => w.id === open) ?? null;

  const step = useCallback((d: number) => {
    setOpen((id) => {
      const w = WALLPAPERS.find((x) => x.id === id);
      const list = WALLPAPERS.filter((x) => x.collection === w?.collection);
      const i = list.findIndex((x) => x.id === id);
      return list[(i + d + list.length) % list.length]?.id ?? id;
    });
  }, []);
  const close = useCallback(() => setOpen(null), []);

  return (
    <section className="section" id="library" data-notch="Wallpaper library">
      <div className="wrap">
        <div className="mod-head">
          <SectionHead
            eyebrow={`Wallpaper library · ${WALLPAPERS.length} loops · ${COLLECTIONS.length} collections`}
            title={"Pick one,\nit's yours"}
            sub="Cinematic scenes made for Notchi, from a savanna sunset to a black hole. Every one is a seamless loop: preview it on a Mac, download it in 1080p and set it with one command. Free, like everything else."
          />
        </div>
        <nav className="wg-filters" aria-label="Collections">
          {COLLECTIONS.map((c) => (
            <button key={c.id} className="chip" onClick={() => scrollTo(`#wc-${c.id}`, 1.4)}>
              {c.emoji} {c.name}
            </button>
          ))}
        </nav>

        {COLLECTIONS.map((c) => {
          const list = WALLPAPERS.filter((w) => w.collection === c.id);
          return (
            <div key={c.id} className="wc" id={`wc-${c.id}`} data-notch={`${c.emoji} ${c.name}`}>
              <Banner c={c} count={list.length} onOpen={() => setOpen(c.hero)} />
              <div className={`wg-grid${list.length <= 3 ? " few" : ""}`}>
                {list.map((w, i) => <Tile key={w.id} w={w} i={i} onOpen={() => setOpen(w.id)} />)}
              </div>
            </div>
          );
        })}
        <p className="wg-note">Native shader and particle wallpapers (drawn live on the GPU, in your theme&apos;s colours) arrive in v1.0. Until then these loops work with Notchi&apos;s video wallpaper today. All art is original to Notchi.</p>
      </div>
      <AnimatePresence>{current && <Preview key="pv" w={current} onClose={close} onStep={step} />}</AnimatePresence>
    </section>
  );
}
