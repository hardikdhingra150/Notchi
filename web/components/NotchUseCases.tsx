"use client";

import { AnimatePresence, motion, useInView } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { SectionHead } from "./ui";

/** One beat of a scenario: what the island shows. */
type Beat =
  | { k: "closed" }
  | { k: "compact"; art: string }
  | { k: "player"; title: string; sub: string; art: string; badge?: string; playing: boolean }
  | { k: "progress"; v: number; label: string }
  | { k: "notify"; msg: string }
  | { k: "level"; icon: "vol" | "sun"; v: number }
  | { k: "battery"; v: number; charging: boolean }
  | { k: "shelf"; files: string[] };

type Case = { who: string; title: string; line: string; beats: Beat[]; soon?: boolean };

const CASES: Case[] = [
  { who: "Developer", title: "Know when the build is done", line: "Run it, switch to something else, and the notch tells you how it went.",
    beats: [{ k: "progress", v: 0.25, label: "Building" }, { k: "progress", v: 0.7, label: "Building" }, { k: "notify", msg: "Build done ✅" }, { k: "closed" }] },
  { who: "Watching", title: "YouTube without the tab", line: "Pause or skip a video in Safari or Chrome from the notch, while you work.",
    beats: [{ k: "compact", art: "#3FA9F5" }, { k: "player", title: "How the notch works", sub: "Notchi · Safari", art: "#3FA9F5", badge: "#1e88ff", playing: true }, { k: "player", title: "How the notch works", sub: "Notchi · Safari", art: "#3FA9F5", badge: "#1e88ff", playing: false }] },
  { who: "Listening", title: "Music in the corner of your eye", line: "Spotify or Music hugs the notch with live bars. Hover for the full player.",
    beats: [{ k: "compact", art: "#4F9A3A" }, { k: "player", title: "Lo-fi to theme to", sub: "Notchi FM", art: "#4F9A3A", badge: "#1ed760", playing: true }, { k: "compact", art: "#4F9A3A" }] },
  { who: "AI agents", title: "Hear back from your agent", line: "End any agent run with notchi notify, so you can stop watching the terminal.",
    beats: [{ k: "progress", v: 0.4, label: "Agent working" }, { k: "notify", msg: "Agent finished 🤖" }, { k: "closed" }] },
  { who: "Late night", title: "Dim without the big HUD", line: "Brightness and volume slide out of the notch instead of covering your screen.",
    beats: [{ k: "level", icon: "sun", v: 0.6 }, { k: "level", icon: "sun", v: 0.3 }, { k: "level", icon: "vol", v: 0.25 }, { k: "closed" }] },
  { who: "Sharing", title: "AirDrop a pile of files", line: "Drop files on the notch as you find them, then AirDrop them all at once.",
    beats: [{ k: "shelf", files: ["Mockup.png"] }, { k: "shelf", files: ["Mockup.png", "Notes.md"] }, { k: "shelf", files: ["Mockup.png", "Notes.md", "Logo.svg"] }, { k: "notify", msg: "Sent with AirDrop" }] },
  { who: "Creators", title: "Watch an export finish", line: "Long renders and exports show a live bar, so you don't keep checking.",
    beats: [{ k: "progress", v: 0.12, label: "Exporting" }, { k: "progress", v: 0.58, label: "Exporting" }, { k: "progress", v: 0.94, label: "Exporting" }, { k: "notify", msg: "Export done 🎬" }] },
  { who: "On the go", title: "Battery that speaks up", line: "A charging animation when you plug in, and a heads-up at 20%.",
    beats: [{ k: "battery", v: 0.2, charging: false }, { k: "closed" }, { k: "battery", v: 0.21, charging: true }, { k: "closed" }] },
  { who: "Focus", title: "Pomodoro around the notch", line: "A timer ring that runs around the island while you work.", soon: true,
    beats: [{ k: "progress", v: 0.3, label: "Focus · 17:30" }, { k: "progress", v: 0.65, label: "Focus · 8:45" }, { k: "notify", msg: "Break time ☕" }] },
];

function size(b: Beat) {
  switch (b.k) {
    case "closed": return { w: 96, h: 18 };
    case "compact": return { w: 150, h: 18 };
    case "player": return { w: 270, h: 84 };
    case "shelf": return { w: 270, h: 84 };
    case "level": return { w: 180, h: 40 };
    default: return { w: 210, h: 44 };
  }
}

function Island({ b }: { b: Beat }) {
  const s = size(b);
  return (
    <motion.div className="uc-island" animate={{ width: s.w, height: s.h, borderBottomLeftRadius: s.h > 30 ? 18 : 8, borderBottomRightRadius: s.h > 30 ? 18 : 8 }} transition={{ type: "spring", stiffness: 300, damping: 26 }}>
      <AnimatePresence mode="popLayout" initial={false}>
        <motion.div key={JSON.stringify(b)} className="uc-in" initial={{ opacity: 0 }} animate={{ opacity: 1, transition: { delay: 0.12 } }} exit={{ opacity: 0, transition: { duration: 0.08 } }}>
          {b.k === "compact" && <><i className="uc-art sm" style={{ background: b.art }} /><span className="m-eq">{[0, 1, 2].map((i) => <i key={i} style={{ animationDelay: `${i * 0.14}s` }} />)}</span></>}
          {b.k === "player" && (
            <div className="uc-player">
              <i className="uc-art" style={{ background: b.art }}>{b.badge && <em style={{ background: b.badge }} />}</i>
              <div><b>{b.title}</b><span>{b.sub}</span><span className="uc-ctl">⏮ {b.playing ? "⏸" : "▶"} ⏭</span></div>
            </div>
          )}
          {b.k === "progress" && <div className="uc-row"><b>{b.label}</b><span className="uc-bar"><motion.i animate={{ width: `${b.v * 100}%` }} /></span></div>}
          {b.k === "notify" && <div className="uc-row"><i className="uc-badge">›_</i><b>{b.msg}</b></div>}
          {b.k === "level" && <div className="uc-row"><b>{b.icon === "vol" ? "🔈" : "☀︎"}</b><span className="uc-bar"><motion.i animate={{ width: `${b.v * 100}%` }} /></span></div>}
          {b.k === "battery" && <div className="uc-row"><b style={{ color: b.charging ? "var(--accent)" : "#ff5a5a" }}>{b.charging ? "⚡ Charging" : "Battery low"}</b><b>{Math.round(b.v * 100)}%</b></div>}
          {b.k === "shelf" && <div className="uc-shelf">{b.files.map((f) => <motion.span key={f} initial={{ scale: 0.4 }} animate={{ scale: 1 }}><i />{f}</motion.span>)}</div>}
        </motion.div>
      </AnimatePresence>
    </motion.div>
  );
}

function CaseCard({ c, i }: { c: Case; i: number }) {
  const ref = useRef<HTMLElement>(null);
  const inView = useInView(ref, { amount: 0.5 });
  const [n, setN] = useState(0);
  useEffect(() => {
    if (!inView) return;
    const id = setInterval(() => setN((x) => (x + 1) % c.beats.length), 1700);
    return () => clearInterval(id);
  }, [inView, c.beats.length]);

  return (
    <motion.article
      ref={ref}
      className={`uc${c.soon ? " soon" : ""}`}
      initial={{ opacity: 0, y: 40 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.3 }}
      transition={{ type: "spring", stiffness: 140, damping: 19, delay: (i % 3) * 0.06 }}
    >
      <div className="uc-stage"><Island b={c.beats[n]} /></div>
      <div className="nc-top"><span className="uc-who">{c.who}</span><span className={`tag${c.soon ? "" : " ok"}`}>{c.soon ? "v1.0" : "Works now"}</span></div>
      <h3>{c.title}</h3>
      <p>{c.line}</p>
    </motion.article>
  );
}

export default function NotchUseCases() {
  return (
    <section className="section" id="use-cases" data-notch="Use cases">
      <div className="wrap">
        <SectionHead eyebrow={`Use cases · ${CASES.length}`} title={"A day with\nthe notch"} sub="Real moments where the notch saves you a click, a tab or a glance at the terminal." />
        <div className="uc-grid">{CASES.map((c, i) => <CaseCard key={c.title} c={c} i={i} />)}</div>
      </div>
    </section>
  );
}
