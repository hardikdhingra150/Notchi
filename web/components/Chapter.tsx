"use client";

import { motion, useScroll, useTransform } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { scrollTo } from "./SmoothScroll";
import { Reveal, SplitHeading } from "./ui";

export const CHAPTERS = [
  { id: "notch", no: "01", title: "The Notch", short: "Notch" },
  { id: "theming", no: "02", title: "Themes", short: "Themes" },
  { id: "wallpapers", no: "03", title: "Wallpapers", short: "Wallpapers" },
  { id: "icons", no: "04", title: "Icons", short: "Icons" },
  { id: "terminal", no: "05", title: "Terminal", short: "CLI" },
  { id: "more", no: "06", title: "Everything else", short: "More" },
] as const;

type ChapterId = (typeof CHAPTERS)[number]["id"];

/** A full-width ink band that opens each part of the product, so the page reads like a table of contents. */
export function Chapter({ id, line, items }: { id: ChapterId; line: string; items: string[] }) {
  const ch = CHAPTERS.find((c) => c.id === id)!;
  const ref = useRef<HTMLElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] });
  const x = useTransform(scrollYProgress, [0, 1], ["-12%", "18%"]);
  const rot = useTransform(scrollYProgress, [0, 1], [-4, 4]);

  return (
    <section className="chapter" id={id} ref={ref} data-notch={`${ch.no} · ${ch.title}`}>
      <motion.span className="ch-no" style={{ x, rotate: rot }} aria-hidden>{ch.no}</motion.span>
      <div className="wrap ch-body">
        <Reveal y={16}><span className="ch-eyebrow">Chapter {ch.no} / 0{CHAPTERS.length}</span></Reveal>
        <SplitHeading text={ch.title} className="ch-title" />
        <Reveal delay={0.2} y={20}><p className="ch-line">{line}</p></Reveal>
        <motion.ul
          className="ch-chips"
          initial="hide"
          whileInView="show"
          viewport={{ once: true, amount: 0.6 }}
          variants={{ show: { transition: { staggerChildren: 0.05, delayChildren: 0.3 } } }}
        >
          {items.map((it) => (
            <motion.li key={it} variants={{ hide: { opacity: 0, y: 14 }, show: { opacity: 1, y: 0 } }}>{it}</motion.li>
          ))}
        </motion.ul>
      </div>
    </section>
  );
}

/** Floating chapter list on the left edge. Highlights the chapter you're reading. */
export function ChapterRail() {
  const [active, setActive] = useState<ChapterId | null>(null);

  useEffect(() => {
    // each chapter "owns" the page from its header until the next header
    const heads = CHAPTERS.map((c) => document.getElementById(c.id)).filter(Boolean) as HTMLElement[];
    const onScroll = () => {
      const mid = window.innerHeight * 0.45;
      let cur: ChapterId | null = null;
      for (const h of heads) if (h.getBoundingClientRect().top < mid) cur = h.id as ChapterId;
      const end = document.getElementById("install");
      if (end && end.getBoundingClientRect().top < mid) cur = null;
      setActive(cur);
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    const t = window.setTimeout(onScroll, 0);
    return () => { window.removeEventListener("scroll", onScroll); window.clearTimeout(t); };
  }, []);

  return (
    <motion.nav
      className="ch-rail"
      aria-label="Chapters"
      initial={false}
      animate={{ opacity: active ? 1 : 0, x: active ? 0 : -30, pointerEvents: active ? "auto" : "none" }}
      transition={{ type: "spring", stiffness: 260, damping: 26 }}
    >
      {CHAPTERS.map((c) => {
        const on = c.id === active;
        return (
          <a key={c.id} href={`#${c.id}`} className={on ? "on" : ""} aria-current={on ? "true" : undefined}
            onClick={(e) => { e.preventDefault(); scrollTo(`#${c.id}`, 1.6); }}>
            {on && <motion.i layoutId="ch-pill" className="ch-pill" transition={{ type: "spring", stiffness: 400, damping: 32 }} />}
            <b>{c.no}</b>
            <span>{c.short}</span>
          </a>
        );
      })}
    </motion.nav>
  );
}
