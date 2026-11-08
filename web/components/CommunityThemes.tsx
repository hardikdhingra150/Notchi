"use client";

import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { COMMUNITY_THEMES, type CommunityTheme } from "@/lib/communityThemes";
import { WALLPAPERS } from "@/lib/wallpapers";
import { Down } from "./icons";
import { SectionHead } from "./ui";

const FILTERS = ["All", "Light", "Dark"] as const;

/** The theme laid over its wallpaper: menu bar, notch, a glass window and the dock, in the theme's own colours. */
function Scene({ t }: { t: CommunityTheme }) {
  const [bg, ink, accent, accent2] = t.swatches;
  const dark = t.appearance === "dark";
  return (
    <div className="ct-scene" style={{ backgroundImage: `url(/wallpapers/${t.wallpaper}.jpg)` }}>
      <div className="ct-menubar" style={{ background: `${bg}aa`, color: ink }}><i style={{ background: ink }} /><b>Finder</b><span>File</span><span>Edit</span></div>
      <div className="ct-island" style={{ boxShadow: `0 6px 22px ${accent}aa` }}>
        <i style={{ background: accent }} />
        <span style={{ color: "#f3efe6" }}>{t.name}</span>
        <em style={{ background: accent }} />
      </div>
      <div className="ct-win" style={{ background: dark ? "rgba(0,0,0,.42)" : "rgba(255,255,255,.55)", color: ink, borderColor: `${ink}33` }}>
        <span className="ct-dots"><i style={{ background: accent }} /><i /><i /></span>
        <b>{t.vibe}</b>
        <span className="ct-bar"><i style={{ background: accent, width: "62%" }} /></span>
      </div>
      <div className="ct-dock" data-style={t.dock} style={{ background: `${bg}99` }}>
        {[accent, accent2, ink, bg].map((c, i) => <i key={i} style={{ background: c, borderColor: `${ink}33` }} />)}
      </div>
    </div>
  );
}

export default function CommunityThemes() {
  const [f, setF] = useState<(typeof FILTERS)[number]>("All");
  const list = COMMUNITY_THEMES.filter((t) => f === "All" || t.appearance === f.toLowerCase());

  return (
    <section className="section" id="community-themes" data-notch="Community themes">
      <div className="wrap">
        <div className="mod-head">
          <SectionHead
            eyebrow={`Community themes · ${COMMUNITY_THEMES.length} more`}
            title={"Dress it\nany way"}
            sub="Twelve more themes, each paired with a wallpaper from the library. Every one is a real theme file you can download and drop into Notchi."
          />
          <div className="seg" role="tablist" aria-label="Filter themes">
            {FILTERS.map((x) => (
              <button key={x} role="tab" aria-selected={f === x} className={f === x ? "on" : ""} onClick={() => setF(x)}>
                {f === x && <motion.i layoutId="ct-pill" className="seg-pill" transition={{ type: "spring", stiffness: 420, damping: 32 }} />}
                <span>{x}</span>
              </button>
            ))}
          </div>
        </div>

        <motion.div className="ct-grid" layout>
          <AnimatePresence mode="popLayout">
            {list.map((t, i) => {
              const wp = WALLPAPERS.find((w) => w.id === t.wallpaper);
              return (
                <motion.article
                  key={t.id}
                  layout
                  className="ct"
                  initial={{ opacity: 0, y: 40, rotate: i % 2 ? 1.5 : -1.5 }}
                  animate={{ opacity: 1, y: 0, rotate: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  transition={{ type: "spring", stiffness: 140, damping: 19, delay: (i % 6) * 0.04 }}
                  whileHover={{ y: -6 }}
                >
                  <Scene t={t} />
                  <div className="ct-body">
                    <div className="ct-head">
                      <h3>{t.name}</h3>
                      <span className="tg-app">{t.appearance}</span>
                    </div>
                    <div className="tg-sw">{t.swatches.map((c, k) => <i key={k} style={{ background: c }} title={c} />)}</div>
                    <dl className="ct-dl">
                      <dt>Wallpaper</dt><dd>{wp?.name ?? t.wallpaper}</dd>
                      <dt>Notch</dt><dd>{t.idle}</dd>
                      <dt>Dock</dt><dd>{t.dock}</dd>
                      <dt>Sounds</dt><dd>{t.sounds}</dd>
                    </dl>
                    <div className="ct-actions">
                      <a className="pill sm" href={`/themes/${t.id}.json`} download={`${t.id}.json`}><Down /> Theme</a>
                      <a className="pill sm" href={`/wallpapers/${t.wallpaper}.mp4`} download={`notchi-${t.wallpaper}.mp4`}><Down /> Wallpaper</a>
                    </div>
                  </div>
                </motion.article>
              );
            })}
          </AnimatePresence>
        </motion.div>
        <p className="wg-note">Put theme files in <code>~/Library/Application Support/Notchi/Themes</code>, reopen Notchi and pick one from the menu bar. Make your own with the builder below.</p>
      </div>
    </section>
  );
}
