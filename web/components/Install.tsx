"use client";

import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { BREW, RELEASES_URL } from "@/lib/site";
import { Check, Copy } from "./icons";
import { Reveal, SectionHead } from "./ui";

function CopyCmd() {
  const [done, setDone] = useState(false);
  const copy = async () => {
    try { await navigator.clipboard.writeText(BREW); } catch {}
    setDone(true);
    setTimeout(() => setDone(false), 1800);
  };
  return (
    <button className="brew" onClick={copy} aria-label="Copy the Homebrew install command">
      <span className="ps">$</span>
      <code>{BREW}</code>
      <span className="brew-btn">
        <AnimatePresence mode="popLayout" initial={false}>
          <motion.span key={String(done)} initial={{ y: 18, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: -18, opacity: 0 }} style={{ display: "inline-flex", gap: 6, alignItems: "center" }}>
            {done ? <><Check width={16} height={16} /> Copied</> : <><Copy width={16} height={16} /> Copy</>}
          </motion.span>
        </AnimatePresence>
      </span>
    </button>
  );
}

const loop = { repeat: Infinity, repeatDelay: 0.6 } as const;

function StepArt({ n }: { n: number }) {
  if (n === 0)
    return (
      <div className="art-dl">
        <motion.div className="dl-arrow" animate={{ y: [-26, 8, 8, -26], opacity: [0, 1, 1, 0] }} transition={{ duration: 2.2, times: [0, 0.45, 0.8, 1], ...loop }}>↓</motion.div>
        <div className="dl-tray"><motion.i animate={{ scaleX: [0, 1, 1, 0] }} transition={{ duration: 2.2, times: [0, 0.6, 0.85, 1], ...loop }} /></div>
        <span className="dl-name">Notchi.app</span>
      </div>
    );
  if (n === 1)
    return (
      <div className="art-gk">
        <div className="gk-win">
          <div className="gk-bar"><i /><i /><i /></div>
          <p><b>Privacy &amp; Security</b><span>“Notchi” was blocked to protect your Mac.</span></p>
          <motion.span className="gk-btn" animate={{ scale: [1, 1, 0.92, 1, 1], backgroundColor: ["var(--paper)", "var(--paper)", "var(--accent)", "var(--accent)", "var(--paper)"] }} transition={{ duration: 3, times: [0, 0.5, 0.58, 0.7, 1], ...loop }}>Open Anyway</motion.span>
        </div>
        <motion.svg className="gk-cursor" viewBox="0 0 24 24" width="26" height="26" animate={{ x: [60, 18, 18, 60], y: [40, 8, 8, 40] }} transition={{ duration: 3, times: [0, 0.45, 0.75, 1], ease: "easeInOut", ...loop }}>
          <path d="M4 2l15 9-7 1.5L8.5 20z" fill="var(--paper)" stroke="var(--line)" strokeWidth="2" strokeLinejoin="round" />
        </motion.svg>
      </div>
    );
  return (
    <div className="art-th">
      <motion.div className="th-notch" animate={{ width: [110, 170, 110], backgroundColor: ["#0c0b09", "#0c0b09", "#0c0b09"] }} transition={{ duration: 2.4, ...loop }}>
        <motion.i animate={{ backgroundColor: ["#ff6a3d", "#8f7cff", "#4f9a3a", "#e2507f", "#ff3fd8", "#ff6a3d"] }} transition={{ duration: 6, repeat: Infinity, ease: "linear" }} />
      </motion.div>
      <div className="th-dots">
        {["#ff6a3d", "#8f7cff", "#4f9a3a", "#e2507f", "#ff3fd8"].map((c, i) => (
          <motion.i key={c} style={{ background: c }} animate={{ y: [0, -8, 0] }} transition={{ duration: 0.6, delay: i * 0.12, repeat: Infinity, repeatDelay: 1.6 }} />
        ))}
      </div>
    </div>
  );
}

const STEPS = [
  { t: "Download", d: "Grab Notchi.app from GitHub Releases, or install it with Homebrew." },
  { t: "Open Anyway", d: "Notchi is signed with a free certificate, so macOS asks once. System Settings → Privacy & Security → Open Anyway." },
  { t: "Pick a theme", d: "The notch wakes up and walks you through each module. Every permission is asked only when a feature needs it." },
];

export default function Install() {
  return (
    <section className="section" id="install" data-notch="Install">
      <div className="wrap">
        <SectionHead center eyebrow="Get Notchi" title={"Three steps\nto a new Mac"} sub="macOS 14 Sonoma or later, on Apple silicon and Intel, with or without a notch. Macs without one get a virtual island." />
        <Reveal className="inst-status" delay={0.2}>
          <span className="live-dot" /> v0.1 is feature-complete. The first public build lands soon, so star the repo to hear when it ships.
        </Reveal>
        <div className="steps">
          {STEPS.map((s, i) => (
            <Reveal key={s.t} delay={i * 0.12} y={60} className="step">
              <span className="step-n display">{i + 1}</span>
              <div className="step-art"><StepArt n={i} /></div>
              <h3>{s.t}</h3>
              <p>{s.d}</p>
            </Reveal>
          ))}
        </div>
        <Reveal className="inst" delay={0.1}>
          <CopyCmd />
          <a className="pill" href={RELEASES_URL} target="_blank" rel="noreferrer">GitHub Releases</a>
        </Reveal>
      </div>
    </section>
  );
}
