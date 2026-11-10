"use client";

import { motion } from "motion/react";
import Link from "next/link";
import { PAGES, type PageHref } from "@/lib/pages";
import { THEMES } from "@/lib/themes";
import { Arrow } from "./icons";
import { SectionHead } from "./ui";

/** A small live preview for each page's card. CSS-animated, so it costs nothing while scrolling. */
function Preview({ href }: { href: PageHref }) {
  switch (href) {
    case "/notch":
      return (
        <div className="xp xp-notch" aria-hidden>
          <div className="xp-island">
            <i className="xp-art" />
            <span className="xp-lines"><b /><b /></span>
            <span className="m-eq">{[0, 1, 2, 3].map((i) => <i key={i} style={{ animationDelay: `${i * 0.14}s` }} />)}</span>
          </div>
          <div className="xp-dots"><i className="on" /><i /><i /></div>
        </div>
      );
    case "/themes":
      return (
        <div className="xp xp-themes" aria-hidden>
          {THEMES.map((t, i) => (
            <span key={t.id} className="xp-swatch" style={{ ["--i" as string]: i, background: t.swatches[0], borderColor: t.swatches[1] }}>
              <i style={{ background: t.accent }} />
            </span>
          ))}
        </div>
      );
    case "/wallpapers":
      return (
        <div className="xp xp-wall" aria-hidden>
          <video src="/wallpapers/earth-cloud-deck-preview.mp4" poster="/wallpapers/earth-cloud-deck.jpg" autoPlay muted loop playsInline preload="metadata" />
        </div>
      );
    case "/icons":
      return (
        <div className="xp xp-icons" aria-hidden>
          {["🚀", "🎨", "🎧"].map((e, i) => (
            <span key={e} className="xp-folder" style={{ ["--i" as string]: i }}><b>{e}</b></span>
          ))}
        </div>
      );
    case "/cli":
      return (
        <div className="xp xp-cli" aria-hidden>
          <code><span>$</span> notchi notify &quot;Build done ✅&quot;<i className="xp-caret" /></code>
          <code className="xp-ok">✓ shown in the notch</code>
        </div>
      );
    case "/roadmap":
      return (
        <div className="xp xp-road" aria-hidden>
          <svg viewBox="0 0 300 80" preserveAspectRatio="none">
            <path d="M10 60 C 70 10, 120 70, 170 35 S 260 20, 290 30" fill="none" stroke="currentColor" strokeOpacity=".25" strokeWidth="5" strokeLinecap="round" />
            <path className="xp-road-done" d="M10 60 C 70 10, 120 70, 170 35 S 260 20, 290 30" fill="none" stroke="var(--accent)" strokeWidth="5" strokeLinecap="round" />
          </svg>
          <span className="xp-pin" style={{ left: "3%" }}>0</span>
          <span className="xp-pin" style={{ left: "30%" }}>0.1</span>
          <span className="xp-pin dim" style={{ left: "56%" }}>0.5</span>
          <span className="xp-pin dim" style={{ left: "90%" }}>1.0</span>
        </div>
      );
  }
}

export default function Explore() {
  return (
    <section className="section" id="explore" data-notch="Explore">
      <div className="wrap">
        <SectionHead
          eyebrow="Six parts, one app"
          title={"Explore\nNotchi"}
          sub="Each part has its own page with live demos. Start anywhere."
        />
        <motion.div
          className="xp-grid"
          initial="hide"
          whileInView="show"
          viewport={{ once: true, amount: 0.1 }}
          variants={{ show: { transition: { staggerChildren: 0.08 } } }}
        >
          {PAGES.map((p, i) => (
            <motion.div
              key={p.href}
              className={`xp-card${i === 0 ? " big" : ""}`}
              variants={{
                hide: { opacity: 0, y: 70, rotate: i % 2 ? 2.5 : -2.5 },
                show: { opacity: 1, y: 0, rotate: 0, transition: { type: "spring", stiffness: 110, damping: 17 } },
              }}
              whileHover={{ y: -8 }}
            >
              <Link href={p.href} className="xp-link">
                <div className="xp-top">
                  <span className="xp-no">{p.no}</span>
                  <span className="xp-go" aria-hidden><Arrow /></span>
                </div>
                <Preview href={p.href} />
                <h3>{p.title}</h3>
                <p>{p.card}</p>
              </Link>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
