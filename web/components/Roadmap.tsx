"use client";

import { motion, useScroll, useSpring, useTransform, type MotionValue } from "motion/react";
import { useRef } from "react";
import { SectionHead } from "./ui";

const PHASES = [
  { v: "Phase 0", when: "Week 1", title: "Setup", items: ["Repo, licences and automated builds", "Free self-signed certificate + Sparkle", "This website"], status: "now" },
  { v: "v0.1", when: "Weeks 2–6", title: "MVP", items: ["Notch island: music, battery, volume, file shelf", "Live video wallpaper and icon studio", "notchi CLI basics and onboarding"], status: "next" },
  { v: "v0.5", when: "Weeks 7–10", title: "Themes", items: ["Theme engine and file format", "5 built-in themes", "Energy governor, backup and restore"], status: "later" },
  { v: "v1.0", when: "Weeks 11–16", title: "Launch", items: ["Glass sidebar and profiles", "Shader wallpapers, virtual island", "Community gallery, accessibility pass"], status: "later" },
  { v: "v1.5", when: "Months 5–6", title: "Desktop", items: ["Custom dock and menu bar styling", "Cursor and sound effects", "Desktop widgets"], status: "later" },
  { v: "v2.0", when: "Months 7–9", title: "Platform", items: ["Plugin SDK (MIT)", "On-device AI theme generator", "In-app store and 8 languages"], status: "later" },
];

function Node({ p, at }: { p: MotionValue<number>; at: number }) {
  const scale = useTransform(p, [at - 0.04, at + 0.02], [0.4, 1]);
  const fill = useTransform(p, [at - 0.02, at], ["var(--paper)", "var(--accent)"]);
  return <motion.span className="rm-node" style={{ scale, backgroundColor: fill }} />;
}

export default function Roadmap() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start 0.7", "end 0.6"] });
  const p = useSpring(scrollYProgress, { stiffness: 120, damping: 30, restDelta: 0.001 });
  const n = PHASES.length;

  return (
    <section className="section" id="roadmap" data-notch="Roadmap">
      <div className="wrap">
        <SectionHead center eyebrow="Built in public" title={"The road\nahead"} sub="A solo, part-time project for now, with a public roadmap. Every phase ships free." />
        <div className="rm" ref={ref}>
          <svg className="rm-line" viewBox="0 0 40 1000" preserveAspectRatio="none" aria-hidden>
            <path d="M20 0C38 80 2 160 20 250S38 420 20 500 2 660 20 750 38 920 20 1000" fill="none" stroke="var(--band)" strokeWidth="6" vectorEffect="non-scaling-stroke" strokeLinecap="round" />
            <motion.path d="M20 0C38 80 2 160 20 250S38 420 20 500 2 660 20 750 38 920 20 1000" fill="none" stroke="var(--line)" strokeWidth="6" vectorEffect="non-scaling-stroke" strokeLinecap="round" style={{ pathLength: p }} />
          </svg>
          {PHASES.map((ph, i) => (
            <div className={`rm-row ${i % 2 ? "r" : "l"}`} key={ph.v}>
              <Node p={p} at={(i + 0.5) / n} />
              <motion.article
                className={`rm-card ${ph.status}`}
                initial={{ opacity: 0, x: i % 2 ? 80 : -80, rotate: i % 2 ? 3 : -3 }}
                whileInView={{ opacity: 1, x: 0, rotate: 0 }}
                viewport={{ once: true, amount: 0.4 }}
                transition={{ type: "spring", stiffness: 90, damping: 16 }}
              >
                <div className="rm-top">
                  <span className="rm-v">{ph.v}</span>
                  <span className="rm-when">{ph.when}</span>
                  {ph.status === "now" && <span className="rm-now"><i /> In progress</span>}
                </div>
                <h3>{ph.title}</h3>
                <ul>{ph.items.map((it) => <li key={it}>{it}</li>)}</ul>
              </motion.article>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
