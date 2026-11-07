"use client";

import { animate, motion, useInView } from "motion/react";
import { useEffect, useRef } from "react";
import { SectionHead } from "./ui";

const STATS = [
  { pre: "<", n: 1, suf: "%", label: "Idle CPU", note: "Drops to 0 fps when nothing changes" },
  { pre: "<", n: 150, suf: "MB", label: "Memory", note: "With every module turned on" },
  { pre: "<", n: 1, suf: "s", label: "Launch", note: "Theme switch in under 500 ms" },
  { pre: "$", n: 0, suf: "", label: "Forever", note: "No Pro tier. No subscriptions." },
];

const ENERGY = [
  { m: "Notch island", v: 0.3 },
  { m: "Live wallpaper", v: 0.6 },
  { m: "Dock", v: 0.2 },
  { m: "Glass sidebar", v: 0.1 },
  { m: "Effects", v: 0.15 },
];

function Count({ to }: { to: number }) {
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, amount: 0.6 });
  useEffect(() => {
    if (!inView || !ref.current) return;
    const el = ref.current;
    const from = to === 0 ? 99 : 0;
    const c = animate(from, to, { duration: 1.8, ease: [0.2, 0.9, 0.2, 1], onUpdate: (v) => (el.textContent = String(Math.round(v))) });
    return () => c.stop();
  }, [inView, to]);
  return <span ref={ref}>{to === 0 ? 99 : 0}</span>;
}

export default function Battery() {
  return (
    <section className="section" id="battery" data-notch="Battery first">
      <div className="wrap">
        <SectionHead eyebrow="Battery first" title={"Never the app\nyou uninstall"} sub="An energy governor has the final say over every animation. Desktop effects pause in full screen, when a window covers them, on battery and in Low Power Mode. These are the targets every release is tested against." />

        <div className="stats">
          {STATS.map((s, i) => (
            <motion.div
              key={s.label}
              className="stat"
              initial={{ opacity: 0, y: 50, scale: 0.94 }}
              whileInView={{ opacity: 1, y: 0, scale: 1 }}
              viewport={{ once: true, amount: 0.4 }}
              transition={{ type: "spring", stiffness: 140, damping: 18, delay: i * 0.08 }}
            >
              <b className="display">{s.pre}<Count to={s.n} />{s.suf}</b>
              <span className="small-caps">{s.label}</span>
              <p>{s.note}</p>
            </motion.div>
          ))}
        </div>

        <motion.div className="energy" initial={{ opacity: 0, y: 40 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, amount: 0.3 }} transition={{ duration: 0.8 }}>
          <div className="energy-head">
            <b>Energy panel</b>
            <span className="small-caps">Battery budget per module · targets</span>
          </div>
          {ENERGY.map((e, i) => (
            <div className="erow" key={e.m}>
              <span>{e.m}</span>
              <div className="ebar">
                <motion.i initial={{ width: 0 }} whileInView={{ width: `${(e.v / 0.6) * 100}%` }} viewport={{ once: true }} transition={{ duration: 1.2, delay: 0.3 + i * 0.1, ease: [0.2, 0.9, 0.2, 1] }} />
              </div>
              <b>{e.v.toFixed(2)}%</b>
            </div>
          ))}
          <div className="echips">
            {["Paused in full screen", "15 fps on battery", "Off in Low Power Mode", "Respects Reduce Motion"].map((c, i) => (
              <motion.span key={c} initial={{ opacity: 0, scale: 0.8 }} whileInView={{ opacity: 1, scale: 1 }} viewport={{ once: true }} transition={{ delay: 0.8 + i * 0.08, type: "spring", stiffness: 300, damping: 18 }}>{c}</motion.span>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
