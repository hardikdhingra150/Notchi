"use client";

import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { Check, Copy } from "./icons";
import { Folder } from "./IconStudio";
import { SectionHead } from "./ui";

type Item = [emoji: string, name: string, tint: string];
type Pack = { id: string; name: string; who: string; items: Item[] };

const PACKS: Pack[] = [
  {
    id: "dev", name: "Developer", who: "Repos, scripts and the screenshots folder that keeps growing.",
    items: [["🚀", "Projects", "#FF6A3D"], ["📦", "Repos", "#8F7CFF"], ["⚙️", "Scripts", "#6B7280"], ["📚", "Docs", "#3FA9F5"],
      ["🧪", "Experiments", "#14B8A6"], ["🗄️", "Archive", "#A16207"], ["📸", "Screenshots", "#E2507F"], ["⬇️", "Downloads", "#4F9A3A"]],
  },
  {
    id: "creator", name: "Creator", who: "Design files, footage, fonts and client work.",
    items: [["🎨", "Design", "#8F7CFF"], ["🎬", "Footage", "#111827"], ["🎧", "Music", "#4F9A3A"], ["📷", "Photos", "#E2507F"],
      ["🔤", "Fonts", "#6B7280"], ["📤", "Exports", "#FF6A3D"], ["✨", "Inspiration", "#F2A65A"], ["💼", "Clients", "#3FA9F5"]],
  },
  {
    id: "student", name: "Student", who: "Classes, notes and the deadline you forgot about.",
    items: [["🎓", "Classes", "#3FA9F5"], ["📝", "Notes", "#F2A65A"], ["📌", "Assignments", "#FF6A3D"], ["📖", "Reading", "#A16207"],
      ["🔬", "Labs", "#14B8A6"], ["🧩", "Projects", "#8F7CFF"], ["⏰", "Exams", "#E2507F"], ["💼", "Internship", "#4F9A3A"]],
  },
  {
    id: "home", name: "Home", who: "Bills, trips, recipes and everything family.",
    items: [["💰", "Finances", "#4F9A3A"], ["✈️", "Travel", "#3FA9F5"], ["🍳", "Recipes", "#F2A65A"], ["🩺", "Health", "#E2507F"],
      ["👨‍👩‍👧", "Family", "#8F7CFF"], ["🚗", "Car", "#6B7280"], ["🏡", "House", "#A16207"], ["🧾", "Taxes", "#FF6A3D"]],
  },
  {
    id: "theme", name: "Match my theme", who: "Every folder in your current theme's accent colour. Change theme, run it again.",
    items: [["🚀", "Projects", "accent"], ["🎨", "Design", "accent"], ["📚", "Docs", "accent"], ["🎧", "Music", "accent"],
      ["📷", "Photos", "accent"], ["💼", "Work", "accent"], ["✨", "Ideas", "accent"], ["🗄️", "Archive", "accent"]],
  },
];

const script = (p: Pack) =>
  ["# make the folders if they don't exist yet", `mkdir -p ${p.items.map(([, n]) => `~/${n}`).join(" ")}`, "",
    ...p.items.map(([e, n, t]) => `notchi icon set ~/${n} ${e} --tint ${t}`)].join("\n");

export default function IconPacks() {
  const [pid, setPid] = useState(PACKS[0].id);
  const [copied, setCopied] = useState(false);
  const pack = PACKS.find((p) => p.id === pid)!;

  return (
    <section className="section" id="icon-packs" data-notch="Icon packs">
      <div className="wrap">
        <div className="mod-head">
          <SectionHead
            eyebrow={`Icon packs · ${PACKS.length * 8} folders`}
            title={"Ready-made\nsets"}
            sub="Pick a set for the way you work. Copy one script and your folders get their emoji and colours in seconds. One command puts them all back."
          />
        </div>
        <div className="ip-tabs" role="tablist" aria-label="Icon packs">
          {PACKS.map((p) => (
            <button key={p.id} role="tab" aria-selected={p.id === pid} className={`chip${p.id === pid ? " on" : ""}`} onClick={() => { setPid(p.id); setCopied(false); }}>
              {p.name}
            </button>
          ))}
        </div>

        <div className="ip">
          <div className="is-finder ip-finder">
            <div className="is-bar"><i /><i /><i /><span>~/ · {pack.name}</span></div>
            <AnimatePresence mode="wait">
              <motion.div key={pack.id} className="ip-files" initial="hide" animate="show" exit="hide" variants={{ show: { transition: { staggerChildren: 0.05 } } }}>
                {pack.items.map(([e, n, t]) => (
                  <motion.div key={n} className="ip-file" variants={{ hide: { opacity: 0, y: 20, scale: 0.7 }, show: { opacity: 1, y: 0, scale: 1, transition: { type: "spring", stiffness: 300, damping: 18 } } }}>
                    <Folder tint={t} emoji={e} />
                    <span>{n}</span>
                  </motion.div>
                ))}
              </motion.div>
            </AnimatePresence>
          </div>

          <div className="ip-side">
            <h3>{pack.name}</h3>
            <p>{pack.who}</p>
            <div className="ip-script">
              <div className="tb-json-bar">
                <span>{pack.id}-pack.sh</span>
                <button onClick={() => { navigator.clipboard?.writeText(script(pack)).catch(() => {}); setCopied(true); setTimeout(() => setCopied(false), 1500); }} aria-label="Copy the setup script">
                  {copied ? <Check width={15} height={15} /> : <Copy width={15} height={15} />}
                </button>
              </div>
              <pre>{script(pack)}</pre>
            </div>
            <p className="is-note">Undo everything: <b>notchi icon restore --all</b></p>
          </div>
        </div>
      </div>
    </section>
  );
}
