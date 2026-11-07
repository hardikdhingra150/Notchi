"use client";

import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { EXTRA_PAGES, PAGES } from "@/lib/pages";
import { REPO_URL } from "@/lib/site";
import { fmtStars, useStars } from "@/lib/useStars";
import { Arrow, Github, LogoMark, Star } from "./icons";
import { SplitHeading, Reveal } from "./ui";

/** The big notch pet. Watches your cursor; poke it and it gets happy. */
function Pet() {
  const ref = useRef<HTMLButtonElement>(null);
  const pupils = useRef<HTMLElement[]>([]);
  const [happy, setHappy] = useState(0);
  const [blink, setBlink] = useState(false);

  useEffect(() => {
    const move = (e: PointerEvent) => {
      const r = ref.current?.getBoundingClientRect();
      if (!r) return;
      const a = Math.atan2(e.clientY - (r.top + r.height / 2), e.clientX - (r.left + r.width / 2));
      const d = Math.min(Math.hypot(e.clientX - r.left - r.width / 2, e.clientY - r.top - r.height / 2) / 160, 1) * 9;
      pupils.current.forEach((p) => p && (p.style.transform = `translate(${Math.cos(a) * d}px,${Math.sin(a) * d}px)`));
    };
    addEventListener("pointermove", move, { passive: true });
    const id = setInterval(() => { setBlink(true); setTimeout(() => setBlink(false), 150); }, 3600);
    return () => { removeEventListener("pointermove", move); clearInterval(id); };
  }, []);

  return (
    <motion.button
      ref={ref}
      className="pet"
      aria-label="Poke the notch pet"
      onClick={() => setHappy((h) => h + 1)}
      animate={happy ? { y: [0, -22, 0, -10, 0], rotate: [0, -6, 6, -3, 0] } : {}}
      key={happy}
      transition={{ duration: 0.8 }}
      whileHover={{ scale: 1.04 }}
    >
      <div className="pet-eyes">
        {[0, 1].map((i) => (
          <motion.span key={i} className="pet-eye" animate={{ scaleY: blink ? 0.1 : 1 }} transition={{ duration: 0.08 }}>
            <i ref={(el) => { if (el) pupils.current[i] = el; }} />
          </motion.span>
        ))}
      </div>
      <motion.span className="pet-mouth" animate={{ scaleX: happy ? 1.3 : 1, height: happy ? 14 : 8 }} />
      <AnimatePresence>
        {happy > 0 && (
          <motion.span key={happy} className="pet-heart" initial={{ y: 0, opacity: 1, scale: 0.6 }} animate={{ y: -70, opacity: 0, scale: 1.4 }} exit={{ opacity: 0 }} transition={{ duration: 1.1 }}>
            ♥
          </motion.span>
        )}
      </AnimatePresence>
    </motion.button>
  );
}

export default function Footer() {
  const stars = useStars();
  return (
    <footer className="section foot" data-notch="Say hi">
      <div className="wrap">
        <Reveal className="cta" y={80}>
          <Pet />
          <span className="eyebrow">Free forever · open source</span>
          <SplitHeading text={"Make your Mac\nfeel like yours"} className="cta-title" />
          <p>Notchi is free, open source and built in public. A star helps more Mac people find it.</p>
          <div className="cta-btns">
            <a className="pill hot" href={REPO_URL} target="_blank" rel="noreferrer">
              <Star /> Star on GitHub{stars ? ` · ${fmtStars(stars)}` : ""}
            </a>
            <a className="pill" href={`${REPO_URL}/blob/main/PROJECT_BLUEPRINT.md`} target="_blank" rel="noreferrer">
              Read the blueprint <Arrow />
            </a>
          </div>
        </Reveal>

        <nav className="foot-pages" aria-label="All pages">
          {PAGES.map((p) => <Link key={p.href} href={p.href}><em>{p.no}</em>{p.title}</Link>)}
          {EXTRA_PAGES.map((p) => <Link key={p.href} href={p.href}><em>+</em>{p.title}</Link>)}
        </nav>

        <div className="foot-row">
          <div className="logo"><LogoMark /> Notchi</div>
          <nav className="foot-links" aria-label="Footer">
            <a href={REPO_URL} target="_blank" rel="noreferrer"><Github width={16} height={16} /> GitHub</a>
            <a href={`${REPO_URL}/issues`} target="_blank" rel="noreferrer">Issues</a>
            <a href={`${REPO_URL}/blob/main/LICENSE`} target="_blank" rel="noreferrer">GPL-3.0</a>
          </nav>
        </div>
        <p className="legal">
          Mac and macOS are trademarks of Apple Inc. Notchi is an independent project and is not affiliated with Apple, or with the other open-source app called “notchi”.
          <span> Psst: ↑ ↑ ↓ ↓ ← → ← → B A</span>
        </p>
      </div>
    </footer>
  );
}
