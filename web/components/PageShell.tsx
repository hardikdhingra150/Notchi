"use client";

import { motion, useScroll, useTransform } from "motion/react";
import Link from "next/link";
import { useRef } from "react";
import { PAGES, pageFor, type PageHref } from "@/lib/pages";
import { Arrow } from "./icons";
import { Reveal, SplitHeading } from "./ui";

/** The big ink band that opens each product page. */
export function PageHero({ href }: { href: PageHref }) {
  const p = pageFor(href);
  const ref = useRef<HTMLElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end start"] });
  const x = useTransform(scrollYProgress, [0, 1], ["0%", "22%"]);
  const rot = useTransform(scrollYProgress, [0, 1], [0, 8]);
  const fade = useTransform(scrollYProgress, [0, 0.9], [1, 0.2]);

  return (
    <section className="chapter page-hero" ref={ref} data-notch={`${p.no} · ${p.title}`}>
      <motion.span className="ch-no" style={{ x, rotate: rot, opacity: fade }} aria-hidden>
        <motion.span
          className="ch-no-in"
          initial={{ y: 80, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ type: "spring", stiffness: 70, damping: 16 }}
        >
          {p.no}
        </motion.span>
      </motion.span>
      <div className="wrap ch-body">
        <Reveal y={16}>
          <nav className="crumbs" aria-label="Breadcrumb">
            <Link href="/">Notchi</Link>
            <span aria-hidden>/</span>
            <span aria-current="page">{p.title}</span>
            <span className="crumb-no">{p.no} of 0{PAGES.length}</span>
          </nav>
        </Reveal>
        <SplitHeading as="h1" text={p.title} className="ch-title" />
        <Reveal delay={0.2} y={20}><p className="ch-line">{p.line}</p></Reveal>
        <motion.ul
          className="ch-chips"
          initial="hide"
          animate="show"
          variants={{ show: { transition: { staggerChildren: 0.06, delayChildren: 0.45 } } }}
        >
          {p.items.map((it) => (
            <motion.li key={it} variants={{ hide: { opacity: 0, y: 14 }, show: { opacity: 1, y: 0 } }}>{it}</motion.li>
          ))}
        </motion.ul>
        <motion.div className="ph-scroll" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 1 }} aria-hidden>
          <span className="mouse"><i /></span> Scroll
        </motion.div>
      </div>
    </section>
  );
}

/** Previous / next page cards at the bottom of every product page. */
export function PagePager({ href }: { href: PageHref }) {
  const i = PAGES.findIndex((p) => p.href === href);
  const prev = i > 0 ? PAGES[i - 1] : null;
  const next = i < PAGES.length - 1 ? PAGES[i + 1] : null;

  return (
    <section className="section pager-sec" data-notch="Keep exploring">
      <div className="wrap pager">
        {prev ? (
          <PagerCard p={prev} dir="prev" />
        ) : (
          <PagerCard home dir="prev" />
        )}
        {next ? <PagerCard p={next} dir="next" /> : <PagerCard home dir="next" />}
      </div>
    </section>
  );
}

function PagerCard({ p, dir, home }: { p?: (typeof PAGES)[number]; dir: "prev" | "next"; home?: boolean }) {
  const label = dir === "prev" ? "Previous" : "Next";
  return (
    <motion.div
      className={`pg-card ${dir}`}
      initial={{ opacity: 0, y: 50, rotate: dir === "prev" ? -2 : 2 }}
      whileInView={{ opacity: 1, y: 0, rotate: 0 }}
      viewport={{ once: true, amount: 0.4 }}
      transition={{ type: "spring", stiffness: 120, damping: 17 }}
    >
      <Link href={home ? "/" : p!.href} className="pg-link">
        <span className="pg-dir">{home ? "Back to start" : `${label} · ${p!.no}`}</span>
        <span className="pg-title">{home ? "Notchi" : p!.title}</span>
        <span className="pg-sub">{home ? "The overview, install and why it's free." : p!.card}</span>
        <span className="pg-arrow" aria-hidden><Arrow /></span>
      </Link>
    </motion.div>
  );
}
