"use client";

import { AnimatePresence, motion, useInView } from "motion/react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { Reveal, SectionHead } from "./ui";

const sp = { type: "spring", stiffness: 340, damping: 28, mass: 0.9 } as const;

function Bars({ n = 7, h = 30 }: { n?: number; h?: number }) {
  return (
    <div className="np-bars" style={{ height: h }}>
      {Array.from({ length: n }, (_, i) => (
        <motion.i key={i} animate={{ scaleY: [0.3, 1, 0.45, 0.85, 0.3] }} transition={{ duration: 0.9 + (i % 3) * 0.25, repeat: Infinity, ease: "easeInOut", delay: i * 0.08 }} />
      ))}
    </div>
  );
}

function Countdown() {
  const [s, setS] = useState(25 * 60 - 1);
  useEffect(() => {
    const id = setInterval(() => setS((v) => (v > 0 ? v - 1 : 25 * 60)), 1000);
    return () => clearInterval(id);
  }, []);
  const k = 1 - s / (25 * 60);
  return (
    <>
      <svg width="46" height="46" viewBox="0 0 46 46" className="np-ring">
        <circle cx="23" cy="23" r="19" stroke="#34302a" strokeWidth="5" fill="none" />
        <motion.circle cx="23" cy="23" r="19" stroke="var(--accent)" strokeWidth="5" fill="none" strokeLinecap="round"
          initial={{ pathLength: 0 }} animate={{ pathLength: Math.max(k, 0.02) }} transition={{ duration: 0.6 }} style={{ rotate: -90, transformOrigin: "50% 50%" }} />
      </svg>
      <div className="np-txt"><b>Focus</b><span>Deep work · 1 of 4</span></div>
      <b className="np-big">{String(Math.floor(s / 60)).padStart(2, "0")}:{String(s % 60).padStart(2, "0")}</b>
    </>
  );
}

type Act = { id: string; label: string; icon: string; w: number; h: number; body: ReactNode };

const ACTS: Act[] = [
  {
    id: "music", label: "Music", icon: "♫", w: 440, h: 116,
    body: (
      <>
        <div className="np-art"><motion.i animate={{ rotate: 360 }} transition={{ duration: 4, repeat: Infinity, ease: "linear" }} /></div>
        <div className="np-txt grow">
          <b>Night Drive</b><span>Notchi Radio</span>
          <div className="np-prog"><motion.i initial={{ scaleX: 0.1 }} animate={{ scaleX: 0.72 }} transition={{ duration: 6, ease: "linear" }} /></div>
        </div>
        <Bars />
      </>
    ),
  },
  { id: "timer", label: "Pomodoro", icon: "◔", w: 380, h: 84, body: <Countdown /> },
  {
    id: "battery", label: "Battery", icon: "⚡", w: 330, h: 64,
    body: (
      <>
        <motion.span className="np-bolt" animate={{ scale: [1, 1.25, 1], opacity: [1, 0.6, 1] }} transition={{ duration: 1.4, repeat: Infinity }}>⚡</motion.span>
        <div className="np-txt grow"><b>Charging</b></div>
        <div className="np-batt"><motion.i initial={{ width: "8%" }} animate={{ width: "87%" }} transition={{ duration: 1.6, ease: [0.2, 0.9, 0.2, 1] }} /></div>
        <b className="np-num">87%</b>
      </>
    ),
  },
  {
    id: "calendar", label: "Calendar", icon: "▦", w: 420, h: 88,
    body: (
      <>
        <div className="np-cal"><span>NOV</span><b>12</b></div>
        <div className="np-txt grow"><b>Design sync</b><span>Starts in 4 min · Zoom</span></div>
        <motion.span className="np-join" initial={{ scale: 0.6, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} transition={{ ...sp, delay: 0.25 }}>Join</motion.span>
      </>
    ),
  },
  {
    id: "airpods", label: "AirPods", icon: "◖◗", w: 400, h: 96,
    body: (
      <>
        <motion.div className="np-pods" initial={{ x: -40, opacity: 0 }} animate={{ x: 0, opacity: 1 }} transition={{ ...sp, delay: 0.1 }}><i /><i /></motion.div>
        <div className="np-txt grow"><b>Connected</b><span>L 92% · R 88% · Case 64%</span></div>
        <motion.div className="np-dot" animate={{ scale: [1, 1.6, 1], opacity: [1, 0.3, 1] }} transition={{ duration: 1.6, repeat: Infinity }} />
      </>
    ),
  },
  {
    id: "terminal", label: "Terminal", icon: ">_", w: 420, h: 70,
    body: (
      <>
        <motion.span className="np-check" initial={{ scale: 0, rotate: -90 }} animate={{ scale: 1, rotate: 0 }} transition={{ ...sp, delay: 0.15 }}>✓</motion.span>
        <div className="np-txt grow"><b>Build done ✅</b><span className="mono">notchi notify · just now</span></div>
      </>
    ),
  },
  {
    id: "shelf", label: "File shelf", icon: "⇣", w: 460, h: 124,
    body: (
      <>
        <div className="np-files">
          {["PDF", "PNG", "ZIP"].map((f, i) => (
            <motion.div key={f} className="np-file" initial={{ y: -50, opacity: 0, rotate: -12 }} animate={{ y: 0, opacity: 1, rotate: (i - 1) * 6 }} transition={{ ...sp, delay: 0.1 + i * 0.1 }}>
              <span>{f}</span>
            </motion.div>
          ))}
        </div>
        <div className="np-txt grow"><b>3 files on the shelf</b><span>Drop to AirDrop or share</span></div>
      </>
    ),
  },
  {
    id: "volume", label: "Volume", icon: "◢", w: 340, h: 58,
    body: (
      <>
        <span className="np-spk">🔊</span>
        <div className="np-vol"><motion.i initial={{ width: "30%" }} animate={{ width: ["30%", "78%", "62%"] }} transition={{ duration: 1.6, ease: "easeInOut" }} /></div>
      </>
    ),
  },
];

export default function NotchPlayground() {
  const [i, setI] = useState(0);
  const [auto, setAuto] = useState(true);
  const box = useRef<HTMLDivElement>(null);
  const inView = useInView(box, { amount: 0.4 });
  const act = ACTS[i];

  useEffect(() => {
    if (!auto || !inView) return;
    const id = setTimeout(() => setI((v) => (v + 1) % ACTS.length), 4200);
    return () => clearTimeout(id);
  }, [i, auto, inView]);

  useEffect(() => {
    if (auto) return;
    const id = setTimeout(() => setAuto(true), 14000);
    return () => clearTimeout(id);
  }, [auto, i]);

  return (
    <section className="section" id="live" data-notch="Live activities">
      <div className="wrap np-grid">
        <div>
          <SectionHead eyebrow="The notch island" title={"Your notch,\nbut useful"} sub="Music, timers, calls, battery, AirPods, downloads and your terminal. Live activities slide out of the notch with real spring physics, then tuck back in." />
          <Reveal delay={0.2} className="np-tabs" role="tablist" aria-label="Live activities">
            {ACTS.map((a, k) => (
              <button key={a.id} role="tab" aria-selected={k === i} className={`np-tab${k === i ? " on" : ""}`} onClick={() => { setI(k); setAuto(false); }}>
                <span className="np-ico">{a.icon}</span>{a.label}
                {k === i && auto && inView && (
                  <motion.i className="np-timer" initial={{ scaleX: 0 }} animate={{ scaleX: 1 }} transition={{ duration: 4.2, ease: "linear" }} key={`t${i}`} />
                )}
              </button>
            ))}
          </Reveal>
        </div>

        <Reveal delay={0.1} y={60}>
          <div className="np-mac" ref={box}>
            <div className="np-screen">
              <svg className="np-wall" viewBox="0 0 600 380" preserveAspectRatio="none" aria-hidden>
                <circle cx="440" cy="150" r="44" fill="var(--accent2)" stroke="var(--line)" strokeWidth="3" />
                <path d="M0 250C80 230 140 270 220 250S380 230 460 252 560 262 600 248V380H0Z" fill="var(--band)" stroke="var(--line)" strokeWidth="3" />
                <path d="M0 296C90 280 160 312 250 294S410 280 490 300 580 306 600 296V380H0Z" fill="var(--paper2)" stroke="var(--line)" strokeWidth="3" />
                <path d="M40 336C120 326 200 348 300 334" fill="none" stroke="var(--line)" strokeWidth="3" strokeLinecap="round" />
              </svg>
              <motion.div className="np-notch" layout animate={{ width: act.w, height: act.h, borderRadius: act.h > 70 ? 36 : 26 }} transition={sp} style={{ borderTopLeftRadius: 0, borderTopRightRadius: 0 }}>
                <AnimatePresence mode="popLayout" initial={false}>
                  <motion.div
                    key={act.id}
                    className="np-row"
                    initial={{ opacity: 0, scale: 0.9, filter: "blur(6px)" }}
                    animate={{ opacity: 1, scale: 1, filter: "blur(0px)", transition: { delay: 0.12, duration: 0.35 } }}
                    exit={{ opacity: 0, scale: 0.92, filter: "blur(6px)", transition: { duration: 0.16 } }}
                  >
                    {act.body}
                  </motion.div>
                </AnimatePresence>
              </motion.div>
            </div>
            <div className="np-base" />
          </div>
          <p className="np-cap small-caps">Click an activity · it plays in the notch</p>
        </Reveal>
      </div>
    </section>
  );
}
