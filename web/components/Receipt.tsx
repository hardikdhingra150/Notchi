"use client";

import { AnimatePresence, motion, useMotionValueEvent, useScroll, useTransform } from "motion/react";
import { useRef, useState } from "react";
import { Reveal, SectionHead } from "./ui";

const ITEMS = [
  { name: "NotchNook", kind: "Notch app", price: "~$25.00" },
  { name: "Alcove", kind: "Notch app", price: "$14.99" },
  { name: "Live wallpaper app", kind: "Wallpaper", price: "paid" },
  { name: "Dock replacement", kind: "Dock", price: "paid" },
  { name: "Menu bar manager", kind: "Menu bar", price: "paid" },
  { name: "Desktop widgets", kind: "Widgets", price: "paid" },
];

export default function Receipt() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start 0.85", "end 0.75"] });
  const clip = useTransform(scrollYProgress, [0, 0.85], [100, 0]);
  const clipPath = useTransform(clip, (v) => `inset(0 0 ${v}% 0)`);
  const y = useTransform(scrollYProgress, [0, 0.85], [-30, 0]);
  const [stamp, setStamp] = useState(false);
  useMotionValueEvent(scrollYProgress, "change", (v) => setStamp(v > 0.86));

  return (
    <section className="section" id="compare" data-notch="Compare">
      <div className="wrap rc-grid">
        <div>
          <SectionHead eyebrow="The stack you'd pay for" title={"Five apps.\nOr one, free."} sub="Today, a themed Mac means stacking four or five separate paid apps. They don't match, they sometimes fight, and each one costs battery. Notchi replaces them with one free, open-source app where everything follows one theme." />
          <Reveal delay={0.2} className="rc-points">
            {["One suite, one theme", "Works on Macs without a notch", "Built-in battery panel", "GPL-3.0, verifiable, no tracking"].map((p) => (
              <span key={p}><i>✓</i>{p}</span>
            ))}
          </Reveal>
        </div>

        <div className="rc-stage" ref={ref}>
          <div className="printer"><i /></div>
          <motion.div className="receipt" style={{ clipPath, y }}>
            <div className="rc-top">
              <b>THE USUAL STACK</b>
              <span>Mac desktop customisation · 2026</span>
            </div>
            <div className="rc-dash" />
            {ITEMS.map((it) => (
              <div key={it.name} className="rc-line">
                <div><b>{it.name}</b><span>{it.kind}</span></div>
                <em>{it.price}</em>
              </div>
            ))}
            <div className="rc-dash" />
            <div className="rc-line total"><b>Usual total</b><em className="strike">$60–100</em></div>
            <div className="rc-line total hot"><b>Notchi</b><em>$0.00</em></div>
            <div className="rc-dash" />
            <p className="rc-foot">No subscription · No account · No ads<br />Thank you for shopping open source</p>
            <div className="rc-barcode" aria-hidden>{Array.from({ length: 38 }, (_, i) => <i key={i} style={{ width: (i * 7) % 5 === 0 ? 4 : (i % 3) + 1 }} />)}</div>
            <AnimatePresence>
              {stamp && (
                <motion.div className="stamp" initial={{ scale: 2.4, opacity: 0, rotate: 8 }} animate={{ scale: 1, opacity: 1, rotate: -14 }} exit={{ opacity: 0, scale: 1.4 }} transition={{ type: "spring", stiffness: 420, damping: 16 }}>
                  FREE<br />FOREVER
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
