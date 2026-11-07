"use client";

import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { ModIcons } from "./icons";
import { SectionHead } from "./ui";

const MODS = [
  { k: "notch", name: "Notch island", line: "Live activities, file shelf, clipboard, quick notes and a webcam mirror, all in the notch." },
  { k: "wallpaper", name: "Live wallpaper", line: "Video, Metal shaders and particles that react to your cursor, music and the time of day." },
  { k: "icons", name: "Icon studio", line: "Icon packs, emoji folder icons, accent retinting, and one-click restore." },
  { k: "sidebar", name: "Glass sidebar", line: "Your own Notification Center: calendar, to-dos, stats, toggles, world clocks." },
  { k: "dock", name: "Dock", line: "Floating glass, minimal, vertical or pill. Window previews and app groups." },
  { k: "menubar", name: "Menu bar", line: "A tinted glass bar, a custom clock and stats, and no more clutter icons." },
  { k: "effects", name: "Effects", line: "Cursor trails, click ripples, launch glows and sound packs that match the theme." },
  { k: "widgets", name: "Desktop widgets", line: "Free-floating glass widgets that snap to a grid. Clock, music, countdowns." },
  { k: "ai", name: "AI themes", line: "Type “cyberpunk rain” and get a full theme. On-device, no cloud, no cost." },
] as const;

export default function Modules() {
  const [on, setOn] = useState<Record<string, boolean>>(() => Object.fromEntries(MODS.map((m) => [m.k, true])));
  const count = Object.values(on).filter(Boolean).length;

  return (
    <section className="section" id="modules" data-notch="Modules">
      <div className="wrap">
        <div className="mod-head">
          <SectionHead eyebrow="Nine modules, one app" title={"Use only\nwhat you want"} sub="Every part of Notchi is its own module. Turn any of them off and it stops using memory or battery. Try the switches." />
          <motion.div className="mod-count" layout>
            <AnimatePresence mode="popLayout" initial={false}>
              <motion.b key={count} initial={{ y: 30, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: -30, opacity: 0 }} transition={{ type: "spring", stiffness: 420, damping: 28 }}>
                {count}
              </motion.b>
            </AnimatePresence>
            <span>of 9 modules on</span>
          </motion.div>
        </div>

        <motion.div className="mod-grid" initial="hide" whileInView="show" viewport={{ once: true, amount: 0.15 }} variants={{ show: { transition: { staggerChildren: 0.07 } } }}>
          {MODS.map((m, i) => {
            const Icon = ModIcons[m.k];
            const active = on[m.k];
            return (
              <motion.article
                key={m.k}
                className={`mod${active ? "" : " off"}`}
                variants={{ hide: { opacity: 0, y: 60, rotate: i % 2 ? 2 : -2 }, show: { opacity: 1, y: 0, rotate: 0, transition: { type: "spring", stiffness: 120, damping: 18 } } }}
                whileHover={{ y: -6 }}
              >
                <div className="mod-top">
                  <motion.span className="mod-ico" whileHover={{ rotate: -12, scale: 1.08 }} transition={{ type: "spring", stiffness: 400, damping: 12 }}>
                    <Icon width={30} height={30} />
                  </motion.span>
                  <button
                    role="switch"
                    aria-checked={active}
                    aria-label={`${m.name} module`}
                    className={`sw-t${active ? " on" : ""}`}
                    onClick={() => setOn((s) => ({ ...s, [m.k]: !s[m.k] }))}
                  >
                    <motion.i layout transition={{ type: "spring", stiffness: 600, damping: 30 }} />
                  </button>
                </div>
                <h3>{m.name}</h3>
                <p>{m.line}</p>
                <span className="mod-no">0{i + 1}</span>
              </motion.article>
            );
          })}
        </motion.div>
      </div>
    </section>
  );
}
