"use client";

import { AnimatePresence, motion } from "motion/react";
import { useMemo, useState } from "react";
import { COLLECTIONS, WALLPAPERS } from "@/lib/wallpapers";
import { zip } from "@/lib/zip";
import { Check, Copy, Down } from "./icons";
import { SectionHead } from "./ui";

/* Builds a theme file in exactly the format Notchi loads (Themes/*.json,
   schema 1, validated by Theme.validate() in NotchiCore). */

const ACCENTS = ["#FF6A3D", "#8F7CFF", "#4F9A3A", "#E2507F", "#FF3FD8", "#3FA9F5", "#F2A65A", "#14B8A6"];
const IDLE = ["breathing", "sparks", "rain", "pet", "none"] as const;
const DOCKS = ["floating-glass", "minimal", "centered-pill", "vertical"] as const;
const SOUNDS = ["soft-pencil", "low-hum", "wood-tap", "chimes", "soft-synth"] as const;
const CURSORS = ["ring", "comet", "leaf", "petal", "spark"] as const;

const slug = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "my-theme";
const mix = (hex: string, to: string, t: number) => {
  const a = parseInt(hex.slice(1), 16), b = parseInt(to.slice(1), 16);
  const ch = (s: number) => Math.round(((a >> s) & 255) * (1 - t) + ((b >> s) & 255) * t);
  return `#${[16, 8, 0].map((s) => ch(s).toString(16).padStart(2, "0")).join("")}`;
};

function Select<T extends string>({ label, value, options, onChange }: { label: string; value: T; options: readonly T[]; onChange: (v: T) => void }) {
  return (
    <label className="tb-field">
      <span>{label}</span>
      <select value={value} onChange={(e) => onChange(e.target.value as T)}>
        {options.map((o) => <option key={o} value={o}>{o}</option>)}
      </select>
    </label>
  );
}

function Slider({ label, value, onChange }: { label: string; value: number; onChange: (v: number) => void }) {
  return (
    <label className="tb-field">
      <span>{label} <b>{value.toFixed(2)}</b></span>
      <input type="range" min={0} max={1} step={0.05} value={value} onChange={(e) => onChange(Number(e.target.value))} />
    </label>
  );
}

export default function ThemeBuilder() {
  const [name, setName] = useState("Ocean Drive");
  const [appearance, setAppearance] = useState<"light" | "dark">("dark");
  const [accent, setAccent] = useState("#3FA9F5");
  const [blur, setBlur] = useState(0.75);
  const [tint, setTint] = useState(0.25);
  const [wallpaper, setWallpaper] = useState("earth-cloud-deck");
  const [packing, setPacking] = useState<null | number>(null);
  const [failed, setFailed] = useState(false);
  const [idle, setIdle] = useState<(typeof IDLE)[number]>("breathing");
  const [dock, setDock] = useState<(typeof DOCKS)[number]>("floating-glass");
  const [sounds, setSounds] = useState<(typeof SOUNDS)[number]>("soft-synth");
  const [cursor, setCursor] = useState<(typeof CURSORS)[number]>("comet");
  const [copied, setCopied] = useState(false);

  const id = slug(name);
  const theme = useMemo(() => ({
    schema: 1,
    id,
    name: name.trim() || "My Theme",
    author: "you",
    version: "1.0.0",
    appearance,
    accent: accent.toUpperCase(),
    glass: { blur, tint },
    wallpaper: { type: "video", src: `wallpapers/${wallpaper}.mp4`, fps: 30 },
    icons: { pack: "default", tintFolders: true },
    notch: { glow: "accent", idle, visualizer: true },
    sidebar: { widgets: ["nowPlaying", "calendar", "stats"] },
    dock: { style: dock, magnify: 1.4 },
    menuBar: { tint: "accent", opacity: 0.4 },
    sounds: { pack: sounds },
    cursor: { trail: cursor },
  }), [id, name, appearance, accent, blur, tint, wallpaper, idle, dock, sounds, cursor]);
  const json = JSON.stringify(theme, null, 2);

  const bg = appearance === "dark" ? mix(accent, "#0b0b10", 0.86) : mix(accent, "#f6f1e6", 0.86);
  const ink = appearance === "dark" ? "#f1ece2" : "#16130e";

  const save = (blob: Blob, file: string) => {
    const url = URL.createObjectURL(blob);
    Object.assign(document.createElement("a"), { href: url, download: file }).click();
    setTimeout(() => URL.revokeObjectURL(url), 2000);
  };
  /** The theme and its video in one .notchitheme, the same package `notchi theme export` makes. */
  const download = async () => {
    if (packing !== null) return;
    setFailed(false);
    setPacking(0);
    try {
      const res = await fetch(`/wallpapers/${wallpaper}.mp4`);
      if (!res.ok || !res.body) throw new Error(String(res.status));
      const total = Number(res.headers.get("content-length")) || 0;
      const reader = res.body.getReader();
      const chunks: Uint8Array[] = [];
      let got = 0;
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        chunks.push(value);
        got += value.length;
        if (total) setPacking(got / total);
      }
      const video = new Uint8Array(got);
      let at = 0;
      for (const c of chunks) { video.set(c, at); at += c.length; }
      const manifest = new TextEncoder().encode(json + "\n");
      save(zip([{ path: "theme.json", data: manifest }, { path: `wallpapers/${wallpaper}.mp4`, data: video }]), `${id}.notchitheme`);
    } catch {
      setFailed(true);
    } finally {
      setPacking(null);
    }
  };
  const copy = () => {
    navigator.clipboard?.writeText(json).catch(() => {});
    setCopied(true);
    setTimeout(() => setCopied(false), 1400);
  };

  return (
    <section className="section" id="builder" data-notch="Theme builder">
      <div className="wrap">
        <SectionHead eyebrow="Theme builder" title={"Make your\nown theme"} sub="Pick a name, a colour and a mood. You get a real theme file in the exact format Notchi loads." />

        <div className="tb">
          <div className="tb-controls">
            <label className="tb-field wide">
              <span>Name <em>id: {id}</em></span>
              <input value={name} maxLength={32} onChange={(e) => setName(e.target.value)} />
            </label>
            <div className="tb-field wide">
              <span>Accent</span>
              <div className="tb-swatches">
                {ACCENTS.map((c) => (
                  <button key={c} className={`tb-sw${c === accent ? " on" : ""}`} style={{ background: c }} onClick={() => setAccent(c)} aria-label={`Accent ${c}`} />
                ))}
                <label className="tb-pick" aria-label="Pick any colour">
                  <input type="color" value={accent} onChange={(e) => setAccent(e.target.value.toUpperCase())} />
                  <span>+</span>
                </label>
              </div>
            </div>
            <div className="tb-field">
              <span>Appearance</span>
              <div className="seg tb-seg">
                {(["light", "dark"] as const).map((a) => (
                  <button key={a} className={appearance === a ? "on" : ""} onClick={() => setAppearance(a)}>
                    {appearance === a && <motion.i layoutId="tb-app" className="seg-pill" transition={{ type: "spring", stiffness: 420, damping: 32 }} />}
                    <span>{a}</span>
                  </button>
                ))}
              </div>
            </div>
            <label className="tb-field">
              <span>Wallpaper</span>
              <select value={wallpaper} onChange={(e) => setWallpaper(e.target.value)}>
                {COLLECTIONS.map((c) => (
                  <optgroup key={c.id} label={c.name}>
                    {WALLPAPERS.filter((w) => w.collection === c.id).map((w) => <option key={w.id} value={w.id}>{w.name}</option>)}
                  </optgroup>
                ))}
              </select>
            </label>
            <Select label="Notch idle" value={idle} options={IDLE} onChange={setIdle} />
            <Select label="Dock" value={dock} options={DOCKS} onChange={setDock} />
            <Select label="Sounds" value={sounds} options={SOUNDS} onChange={setSounds} />
            <Select label="Cursor" value={cursor} options={CURSORS} onChange={setCursor} />
            <Slider label="Glass blur" value={blur} onChange={setBlur} />
            <Slider label="Glass tint" value={tint} onChange={setTint} />
          </div>

          <div className="tb-out">
            <motion.div className="tb-preview" animate={{ backgroundColor: bg, color: ink }} transition={{ duration: 0.5 }}>
              <div className="tb-island" style={{ boxShadow: `0 8px 30px ${accent}88` }}>
                <i style={{ background: accent }} />
                <b>{theme.name} applied</b>
              </div>
              <motion.div className="tb-sun" animate={{ backgroundColor: accent }} />
              <div className="tb-win" style={{ backdropFilter: `blur(${blur * 14}px)`, WebkitBackdropFilter: `blur(${blur * 14}px)`, background: `${appearance === "dark" ? "#000000" : "#ffffff"}${Math.round((0.25 + tint * 0.5) * 255).toString(16).padStart(2, "0")}` }}>
                <span style={{ background: accent }} /><span /><span />
              </div>
              <div className="tb-dock" data-style={dock}>
                {[accent, mix(accent, ink, 0.35), mix(accent, bg, 0.4), ink].map((c, i) => <i key={i} style={{ background: c }} />)}
              </div>
            </motion.div>

            <div className="tb-json">
              <div className="tb-json-bar">
                <span>{id}.json</span>
                <button onClick={copy} aria-label="Copy theme JSON">
                  <AnimatePresence mode="popLayout" initial={false}>
                    <motion.span key={String(copied)} initial={{ scale: 0.4, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.4, opacity: 0 }} style={{ display: "grid" }}>
                      {copied ? <Check width={15} height={15} /> : <Copy width={15} height={15} />}
                    </motion.span>
                  </AnimatePresence>
                </button>
              </div>
              <pre>{json}</pre>
            </div>
            <button className="pill hot tb-dl" onClick={download} disabled={packing !== null} aria-live="polite">
              <Down /> {packing === null ? `Download ${id}.notchitheme` : `Packing… ${Math.round(packing * 100)}%`}
            </button>
            {failed && <p className="tb-err" role="alert">Couldn&apos;t fetch the wallpaper. Check your connection and try again.</p>}
            <ol className="tb-steps">
              <li>Double-click <code>{id}.notchitheme</code> in Downloads. Notchi installs it and switches to it.</li>
              <li>Or from the terminal: <code>notchi theme install ~/Downloads/{id}.notchitheme</code></li>
              <li>The wallpaper video is inside, so there&apos;s nothing else to download.</li>
            </ol>
          </div>
        </div>
      </div>
    </section>
  );
}
