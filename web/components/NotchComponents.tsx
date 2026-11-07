"use client";

import { motion } from "motion/react";
import { useState } from "react";
import { SectionHead } from "./ui";

type Kind = "eq" | "bar" | "text" | "ring" | "dots";
type Comp = { name: string; line: string; glyph: Glyph; kind: Kind; label?: string; status: "shipped" | "v1.0" | "v1.5" };

const COMPONENTS: Comp[] = [
  { name: "Now playing", line: "Any app: YouTube in Safari or Chrome, Music, Spotify, Podcasts. Art, controls, progress.", glyph: "note", kind: "eq", status: "shipped" },
  { name: "Volume", line: "Replaces the macOS volume indicator. Fine steps with Shift+Option.", glyph: "speaker", kind: "bar", status: "shipped" },
  { name: "Brightness", line: "Same for the brightness keys, in your theme colour.", glyph: "sun", kind: "bar", status: "shipped" },
  { name: "Battery", line: "A charging animation when you plug in, a warning when it runs low.", glyph: "bolt", kind: "text", label: "87%", status: "shipped" },
  { name: "File shelf", line: "Drop files on the notch, drag them out later or AirDrop them all.", glyph: "tray", kind: "dots", status: "shipped" },
  { name: "Terminal pings", line: "notchi notify from any script, build or AI agent.", glyph: "term", kind: "text", label: "Build done", status: "shipped" },
  { name: "Progress", line: "Exports, downloads and long jobs with a live bar.", glyph: "down", kind: "bar", status: "shipped" },
  { name: "Theme switch", line: "Pick a theme and the whole notch recolours with it.", glyph: "palette", kind: "dots", status: "shipped" },
  { name: "Home", line: "Hover for the time, date and battery at a glance.", glyph: "clock", kind: "text", label: "21:44", status: "shipped" },
  { name: "Timers & Pomodoro", line: "A progress ring that runs around the notch.", glyph: "timer", kind: "ring", status: "v1.0" },
  { name: "Next meeting", line: "Countdown to your next calendar event with a join button.", glyph: "cal", kind: "text", label: "in 5 min", status: "v1.0" },
  { name: "AirPods", line: "A connect animation with each bud's battery.", glyph: "pods", kind: "text", label: "92 · 88", status: "v1.0" },
  { name: "Clipboard", line: "Your last few copies, one click away.", glyph: "clip", kind: "dots", status: "v1.0" },
  { name: "Quick notes", line: "Jot something down without opening an app.", glyph: "pen", kind: "text", label: "buy milk", status: "v1.5" },
  { name: "Mirror", line: "A quick webcam check before a call.", glyph: "cam", kind: "ring", status: "v1.5" },
];

type Glyph = "note" | "speaker" | "sun" | "bolt" | "tray" | "term" | "down" | "palette" | "clock" | "timer" | "cal" | "pods" | "clip" | "pen" | "cam";

const G: Record<Glyph, React.ReactNode> = {
  note: <path d="M9 17V5l10-2v12M9 17a3 3 0 1 1-3-3 3 3 0 0 1 3 3Zm10-2a3 3 0 1 1-3-3 3 3 0 0 1 3 3Z" />,
  speaker: <path d="M4 9h4l5-4v14l-5-4H4zM16 8.5a5 5 0 0 1 0 7M18.5 6a8.5 8.5 0 0 1 0 12" />,
  sun: <><circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" /></>,
  bolt: <path d="M13 2 4 14h7l-1 8 9-12h-7z" />,
  tray: <path d="M3 13h5l1.5 3h5L16 13h5M5 5h14l2 8v6H3v-6z" />,
  term: <path d="m5 7 5 5-5 5M12 17h7" />,
  down: <path d="M12 3v12m0 0-5-5m5 5 5-5M4 21h16" />,
  palette: <><path d="M12 3a9 9 0 1 0 0 18c1.5 0 2-1 2-2s-1-1.5-1-2.5S14 15 15.5 15H18a3 3 0 0 0 3-3 9 9 0 0 0-9-9Z" /><circle cx="7.5" cy="11" r="1" /><circle cx="10" cy="7" r="1" /><circle cx="15" cy="7.5" r="1" /></>,
  clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
  timer: <><circle cx="12" cy="13" r="8" /><path d="M12 9v4l2 2M9 2h6" /></>,
  cal: <><rect x="3" y="5" width="18" height="16" rx="3" /><path d="M3 10h18M8 3v4M16 3v4" /></>,
  pods: <path d="M7 4a3 3 0 0 0-3 3v3a3 3 0 0 0 3 3v7M17 4a3 3 0 0 1 3 3v3a3 3 0 0 1-3 3v7M7 4h0M17 4h0" />,
  clip: <><rect x="6" y="4" width="12" height="17" rx="2" /><path d="M9 4V3h6v1M9 10h6M9 14h4" /></>,
  pen: <path d="M4 20h4L19 9l-4-4L4 16zM14 6l4 4" />,
  cam: <><rect x="3" y="7" width="13" height="11" rx="2" /><path d="m16 11 5-3v9l-5-3" /></>,
};

function MiniIsland({ c }: { c: Comp }) {
  return (
    <div className={`mini ${c.kind}`} aria-hidden>
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">{G[c.glyph]}</svg>
      {c.kind === "eq" && <span className="m-eq">{[0, 1, 2, 3, 4].map((i) => <i key={i} style={{ animationDelay: `${i * 0.13}s` }} />)}</span>}
      {c.kind === "bar" && <span className="m-bar"><i /></span>}
      {c.kind === "text" && <span className="m-text">{c.label}</span>}
      {c.kind === "dots" && <span className="m-dots"><i /><i /><i /></span>}
      {c.kind === "ring" && <span className="m-ring" />}
    </div>
  );
}

const FILTERS = [
  { k: "all", label: "All" },
  { k: "shipped", label: "Working now" },
  { k: "soon", label: "Coming" },
] as const;

export default function NotchComponents() {
  const [f, setF] = useState<(typeof FILTERS)[number]["k"]>("all");
  const list = COMPONENTS.filter((c) => f === "all" || (f === "shipped" ? c.status === "shipped" : c.status !== "shipped"));
  const shipped = COMPONENTS.filter((c) => c.status === "shipped").length;

  return (
    <section className="section" id="notch-parts" data-notch="Notch components">
      <div className="wrap">
        <div className="mod-head">
          <SectionHead
            eyebrow="Notch components"
            title={"Everything the\nnotch can do"}
            sub={`${shipped} components work today. The rest are on the roadmap, and every one follows your theme.`}
          />
          <div className="seg" role="tablist" aria-label="Filter notch components">
            {FILTERS.map((x) => (
              <button key={x.k} role="tab" aria-selected={f === x.k} className={f === x.k ? "on" : ""} onClick={() => setF(x.k)}>
                {f === x.k && <motion.i layoutId="seg-pill" className="seg-pill" transition={{ type: "spring", stiffness: 420, damping: 32 }} />}
                <span>{x.label}</span>
              </button>
            ))}
          </div>
        </div>

        <motion.div className="nc-grid" layout>
          {list.map((c, i) => (
            <motion.article
              key={c.name}
              layout
              className={`nc${c.status === "shipped" ? "" : " soon"}`}
              initial={{ opacity: 0, y: 40, scale: 0.96 }}
              whileInView={{ opacity: 1, y: 0, scale: 1 }}
              viewport={{ once: true, amount: 0.3 }}
              transition={{ type: "spring", stiffness: 160, damping: 20, delay: (i % 3) * 0.05 }}
              whileHover={{ y: -6 }}
            >
              <div className="nc-stage"><MiniIsland c={c} /></div>
              <div className="nc-top">
                <h3>{c.name}</h3>
                <span className={`tag ${c.status === "shipped" ? "ok" : ""}`}>{c.status === "shipped" ? "Works now" : c.status}</span>
              </div>
              <p>{c.line}</p>
            </motion.article>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
