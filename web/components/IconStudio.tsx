"use client";

import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { SectionHead } from "./ui";

const EMOJI = ["🚀", "🎨", "📸", "🎧", "💼", "🧪", "📚", "🌱"];
const TINTS = [
  { name: "Theme accent", v: "accent" },
  { name: "Tomato", v: "#FF6A3D" },
  { name: "Lilac", v: "#8F7CFF" },
  { name: "Matcha", v: "#4F9A3A" },
  { name: "Sakura", v: "#E2507F" },
  { name: "Sky", v: "#3FA9F5" },
];
const FOLDERS = ["Projects", "Design", "Photos", "Music"];

export function Folder({ tint, emoji }: { tint: string; emoji: string }) {
  const fill = tint === "accent" ? "var(--accent)" : tint;
  return (
    <svg viewBox="0 0 200 160" className="is-folder" aria-hidden>
      <motion.path d="M14 30q0-12 12-12h50l14 14h84q12 0 12 12v6H14z" animate={{ fill }} style={{ filter: "brightness(.82)" }} transition={{ duration: 0.5 }} />
      <motion.path d="M10 52q0-10 10-10h160q10 0 10 10v86q0 12-12 12H22q-12 0-12-12z" animate={{ fill }} transition={{ duration: 0.5 }} />
      <path d="M10 60h180" stroke="#fff" strokeOpacity=".35" strokeWidth="2" />
      <AnimatePresence mode="popLayout" initial={false}>
        <motion.text
          key={emoji}
          x="100" y="118" textAnchor="middle" fontSize="54"
          initial={{ scale: 0.3, opacity: 0, rotate: -30 }}
          animate={{ scale: 1, opacity: 1, rotate: 0 }}
          exit={{ scale: 0.3, opacity: 0, rotate: 30 }}
          transition={{ type: "spring", stiffness: 380, damping: 18 }}
          style={{ transformOrigin: "100px 100px" }}
        >
          {emoji}
        </motion.text>
      </AnimatePresence>
    </svg>
  );
}

export default function IconStudio() {
  const [emoji, setEmoji] = useState("🚀");
  const [tint, setTint] = useState("accent");
  const [folder, setFolder] = useState("Projects");
  const cmd = `notchi icon set ~/${folder} ${emoji}${tint === "accent" ? " --tint accent" : ` --tint ${tint}`}`;

  return (
    <section className="section" id="icon-studio" data-notch="Icon studio">
      <div className="wrap is-wrap">
        <div>
          <SectionHead
            eyebrow="Icon studio"
            title={"Folders that\nlook like yours"}
            sub="Give any folder an emoji or image badge and recolour it, from the menu or one command. Every change is recorded, so one click puts the originals back."
          />
          <div className="is-controls">
            <div>
              <span className="is-label">Folder</span>
              <div className="is-row">
                {FOLDERS.map((f) => <button key={f} className={`chip${f === folder ? " on" : ""}`} onClick={() => setFolder(f)}>{f}</button>)}
              </div>
            </div>
            <div>
              <span className="is-label">Badge</span>
              <div className="is-row">
                {EMOJI.map((e) => <button key={e} className={`is-emo${e === emoji ? " on" : ""}`} onClick={() => setEmoji(e)} aria-label={`Badge ${e}`}>{e}</button>)}
              </div>
            </div>
            <div>
              <span className="is-label">Tint</span>
              <div className="is-row">
                {TINTS.map((t) => (
                  <button key={t.v} className={`is-tint${t.v === tint ? " on" : ""}`} onClick={() => setTint(t.v)} aria-label={t.name} title={t.name}
                    style={{ background: t.v === "accent" ? "var(--accent)" : t.v }} />
                ))}
              </div>
            </div>
          </div>
        </div>

        <motion.div className="is-stage" initial={{ opacity: 0, scale: 0.9, rotate: 3 }} whileInView={{ opacity: 1, scale: 1, rotate: 0 }} viewport={{ once: true, amount: 0.4 }} transition={{ type: "spring", stiffness: 120, damping: 16 }}>
          <div className="is-finder">
            <div className="is-bar"><i /><i /><i /><span>~/</span></div>
            <div className="is-files">
              {FOLDERS.map((f) => (
                <div key={f} className={`is-file${f === folder ? " on" : ""}`}>
                  {f === folder ? <Folder tint={tint} emoji={emoji} /> : <Folder tint="#8fb8e8" emoji="" />}
                  <span>{f}</span>
                </div>
              ))}
            </div>
          </div>
          <AnimatePresence mode="popLayout" initial={false}>
            <motion.code key={cmd} className="is-cmd" initial={{ y: 10, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: -10, opacity: 0 }}>
              $ {cmd}
            </motion.code>
          </AnimatePresence>
          <p className="is-note">Undo everything: <b>notchi icon restore --all</b> or the menu bar.</p>
        </motion.div>
      </div>
    </section>
  );
}
