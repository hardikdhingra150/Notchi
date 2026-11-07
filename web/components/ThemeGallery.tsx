"use client";

import { motion } from "motion/react";
import { applyTheme } from "@/lib/applyTheme";
import { THEMES, type ThemeMeta } from "@/lib/themes";
import { useTheme } from "@/lib/useTheme";
import { SectionHead } from "./ui";

/** A tiny desktop painted in the theme's own colours (not the page's). */
function Desk({ t }: { t: ThemeMeta }) {
  const [bg, ink, accent, accent2] = t.swatches;
  return (
    <svg className="tg-desk" viewBox="0 0 280 170" aria-hidden>
      <defs>
        <linearGradient id={`g-${t.id}`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor={bg} />
          <stop offset="1" stopColor={accent2} stopOpacity=".55" />
        </linearGradient>
      </defs>
      <rect width="280" height="170" fill={`url(#g-${t.id})`} />
      <circle className="tg-sun" cx="206" cy="64" r="22" fill={accent} opacity=".85" />
      <path d="M0 118C40 104 80 128 130 114S220 102 280 116V170H0Z" fill={ink} opacity=".14" />
      <rect width="280" height="12" fill={ink} opacity=".18" />
      <path d="M112 0H168V10Q168 18 160 18H120Q112 18 112 10Z" fill="#000" />
      <rect className="tg-glow" x="128" y="20" width="24" height="2.5" rx="1.25" fill={accent} />
      <rect x="86" y="144" width="108" height="18" rx="8" fill={bg} opacity=".75" stroke={ink} strokeOpacity=".3" />
      {[0, 1, 2, 3].map((i) => (
        <rect key={i} x={95 + i * 24} y="147.5" width="15" height="11" rx="3" fill={i === 0 ? accent : i === 1 ? accent2 : ink} opacity={i > 1 ? 0.5 : 1} />
      ))}
    </svg>
  );
}

export default function ThemeGallery() {
  const active = useTheme();

  return (
    <section className="section" id="theme-gallery" data-notch="Theme gallery">
      <div className="wrap">
        <SectionHead
          eyebrow="Built-in themes"
          title={"Five themes\nin the box"}
          sub="Each theme is one small JSON file that sets the notch, wallpaper, dock, sounds and cursor. Apply one to this page."
        />
        <motion.div
          className="tg-grid"
          initial="hide"
          whileInView="show"
          viewport={{ once: true, amount: 0.15 }}
          variants={{ show: { transition: { staggerChildren: 0.08 } } }}
        >
          {THEMES.map((t, i) => {
            const on = t.id === active;
            return (
              <motion.article
                key={t.id}
                className={`tg${on ? " on" : ""}`}
                variants={{ hide: { opacity: 0, y: 60, rotate: i % 2 ? 3 : -3 }, show: { opacity: 1, y: 0, rotate: 0, transition: { type: "spring", stiffness: 120, damping: 17 } } }}
                whileHover={{ y: -8 }}
                style={{ ["--t-accent" as string]: t.accent }}
              >
                <Desk t={t} />
                <div className="tg-body">
                  <div className="tg-head">
                    <h3>{t.name}</h3>
                    <span className="tg-app">{t.appearance}</span>
                  </div>
                  <p className="tg-vibe">{t.vibe}</p>
                  <div className="tg-sw">{t.swatches.map((c) => <i key={c} style={{ background: c }} title={c} />)}</div>
                  <dl>
                    <dt>Wallpaper</dt><dd>{t.wallpaper.replace(".metal", "")}</dd>
                    <dt>Notch idle</dt><dd>{t.idle}</dd>
                    <dt>Sounds</dt><dd>{t.sounds}</dd>
                  </dl>
                  <button className={`tg-btn${on ? " on" : ""}`} onClick={(e) => applyTheme(t.id, e.clientX, e.clientY)} aria-pressed={on}>
                    {on ? "Applied" : `Apply ${t.name}`}
                  </button>
                </div>
              </motion.article>
            );
          })}
          <motion.article className="tg tg-make" variants={{ hide: { opacity: 0, y: 60 }, show: { opacity: 1, y: 0 } }}>
            <span className="tg-plus" aria-hidden>+</span>
            <h3>Your theme</h3>
            <p>Copy a theme file, change the colours, drop it in ~/Library/Application Support/Notchi/Themes. A theme editor and a community gallery are next.</p>
            <code>$ notchi theme list</code>
          </motion.article>
        </motion.div>
      </div>
    </section>
  );
}
