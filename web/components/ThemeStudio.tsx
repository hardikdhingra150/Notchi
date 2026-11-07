"use client";

import { AnimatePresence, motion } from "motion/react";
import { applyTheme } from "@/lib/applyTheme";
import { THEMES } from "@/lib/themes";
import { useTheme } from "@/lib/useTheme";
import { Check } from "./icons";
import { Reveal, SectionHead } from "./ui";

function Preview() {
  return (
    <div className="tp">
      <svg viewBox="0 0 320 200" preserveAspectRatio="none" aria-hidden>
        <rect width="320" height="200" fill="var(--sky)" />
        <circle cx="232" cy="78" r="24" fill="var(--accent2)" stroke="var(--line)" strokeWidth="2.5" />
        <path d="M0 128C40 116 80 138 120 126S200 114 240 128 300 134 320 124V200H0Z" fill="var(--band)" stroke="var(--line)" strokeWidth="2.5" />
        <path d="M0 152C50 142 90 162 140 150S230 140 270 154 310 158 320 150V200H0Z" fill="var(--paper2)" stroke="var(--line)" strokeWidth="2.5" />
        <rect x="0" y="0" width="320" height="16" fill="var(--accent)" />
        <path d="M0 16H320" stroke="var(--line)" strokeWidth="2.5" />
        <path d="M128 0H192V14Q192 24 182 24H138Q128 24 128 14Z" fill="#0c0b09" />
        <rect x="278" y="34" width="26" height="20" rx="4" fill="var(--accent)" stroke="var(--line)" strokeWidth="2.5" />
        <rect x="278" y="64" width="26" height="20" rx="4" fill="var(--accent3)" stroke="var(--line)" strokeWidth="2.5" />
        <rect x="92" y="168" width="136" height="24" rx="10" fill="var(--paper)" fillOpacity=".7" stroke="var(--line)" strokeWidth="2.5" />
        {["var(--accent)", "var(--accent2)", "var(--accent3)", "#0c0b09", "var(--paper2)"].map((c, i) => (
          <rect key={i} x={100 + i * 25} y="172" width="17" height="16" rx="4" fill={c} stroke="var(--line)" strokeWidth="2" />
        ))}
      </svg>
    </div>
  );
}

const Val = ({ v, q = true }: { v: string | number | boolean; q?: boolean }) => (
  <AnimatePresence mode="popLayout" initial={false}>
    <motion.span
      key={String(v)}
      className={typeof v === "string" ? "j-s" : "j-n"}
      initial={{ y: -14, opacity: 0, filter: "blur(3px)" }}
      animate={{ y: 0, opacity: 1, filter: "blur(0px)" }}
      exit={{ y: 14, opacity: 0, filter: "blur(3px)" }}
      transition={{ type: "spring", stiffness: 400, damping: 30 }}
      style={{ display: "inline-block" }}
    >
      {typeof v === "string" && q ? `"${v}"` : String(v)}
    </motion.span>
  </AnimatePresence>
);

export default function ThemeStudio() {
  const active = useTheme();
  const t = THEMES.find((x) => x.id === active) ?? THEMES[0];

  return (
    <section className="section" id="themes" data-notch="Themes">
      <div className="wrap">
        <SectionHead center eyebrow="Theme engine" title={"One theme.\nEverything changes."} sub="Click a theme. This whole page switches, exactly like your desktop would: notch, wallpaper, dock, icons, menu bar, sounds and cursor, in one sweep." />

        <div className="tgrid">
          {THEMES.map((th, i) => (
            <Reveal key={th.id} delay={i * 0.08} y={50}>
              <motion.button
                data-theme={th.id}
                className={`tcard${th.id === active ? " on" : ""}`}
                onClick={(e) => applyTheme(th.id, e.clientX, e.clientY)}
                whileHover={{ y: -8, rotate: i % 2 ? 1.2 : -1.2 }}
                whileTap={{ scale: 0.97 }}
                transition={{ type: "spring", stiffness: 300, damping: 18 }}
                aria-pressed={th.id === active}
              >
                <Preview />
                <div className="tmeta">
                  <div>
                    <b>{th.name}</b>
                    <span>{th.vibe}</span>
                  </div>
                  <div className="sw">{th.swatches.map((c) => <i key={c} style={{ background: c }} />)}</div>
                </div>
                <AnimatePresence>
                  {th.id === active && (
                    <motion.span className="tbadge" initial={{ scale: 0, rotate: -40 }} animate={{ scale: 1, rotate: -8 }} exit={{ scale: 0 }} transition={{ type: "spring", stiffness: 500, damping: 18 }}>
                      <Check width={14} height={14} /> On
                    </motion.span>
                  )}
                </AnimatePresence>
              </motion.button>
            </Reveal>
          ))}
        </div>

        <div className="tjson-row">
          <Reveal className="tjson-copy">
            <h3 className="display">Themes are<br />just JSON</h3>
            <p>Every theme is one small file. Make your own, share it as a <code>.notchitheme</code>, or grab one from the community gallery. One click brings back stock macOS.</p>
          </Reveal>
          <Reveal delay={0.15} className="tjson">
            <div className="tjson-bar"><i /><i /><i /><span>{t.id}.json</span></div>
            <pre>
{`{
  "schema": 1,
  "id": `}<Val v={t.id} />{`,
  "name": `}<Val v={t.name} />{`,
  "appearance": `}<Val v={t.appearance} />{`,
  "accent": `}<Val v={t.accent} />{`,
  "wallpaper": { "type": "shader", "src": `}<Val v={t.wallpaper} />{` },
  "notch": { "glow": "accent", "idle": `}<Val v={t.idle} />{` },
  "dock": { "style": `}<Val v={t.dock} />{`, "magnify": 1.4 },
  "sounds": { "pack": `}<Val v={t.sounds} />{` },
  "cursor": { "trail": `}<Val v={t.cursor} />{` }
}`}
            </pre>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
