"use client";

import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { Check, Copy } from "./icons";
import { SectionHead } from "./ui";

const GROUPS = [
  {
    name: "Notch",
    cmds: [
      ['notchi notify "Build done ✅"', "Show a message in the notch."],
      ['notchi progress 42 "Exporting"', "Show a progress bar. 100 hides it."],
      ["notchi status", "What the notch is showing right now."],
    ],
  },
  {
    name: "Themes",
    cmds: [
      ["notchi theme list", "List installed themes."],
      ["notchi apply neon-rain", "Apply a theme everywhere at once."],
    ],
  },
  {
    name: "Wallpaper",
    cmds: [
      ["notchi wallpaper set ~/Movies/waves.mp4", "Loop a video behind your desktop icons."],
      ["notchi wallpaper off", "Back to your normal wallpaper."],
    ],
  },
  {
    name: "Icons",
    cmds: [
      ["notchi icon set ~/Projects 🚀 --tint accent", "Badge and retint a folder."],
      ["notchi icon list", "Every icon Notchi has changed."],
      ["notchi icon restore --all", "Put all the original icons back."],
    ],
  },
  {
    name: "Health",
    cmds: [
      ["notchi doctor", "Check permissions, signing and conflicts."],
      ["notchi --version", "Which version you have."],
    ],
  },
] as const;

const RECIPES = [
  { group: "Build & test", title: "After every build", code: 'npm run build && notchi notify "Build done ✅" || notchi notify "Build failed ❌"' },
  { group: "Build & test", title: "When tests finish", code: 'npm test && notchi notify "Tests passed 🧪" || notchi notify "Tests failed ❌"' },
  { group: "Build & test", title: "Xcode builds", code: 'xcodebuild -scheme MyApp build | tail -1 && notchi notify "Xcode build finished 🔨"' },
  { group: "Build & test", title: "Rust and cargo", code: 'cargo build --release && notchi notify "cargo build done 🦀"' },
  { group: "Git & CI", title: "When a push lands", code: 'git push && notchi notify "Pushed $(git branch --show-current) 🚀"' },
  { group: "Git & CI", title: "Wait for CI on GitHub", code: 'gh run watch --exit-status && notchi notify "CI passed ✅" || notchi notify "CI failed ❌"' },
  { group: "Git & CI", title: "Every commit (git hook)", code: 'echo \'notchi notify "Committed: $(git log -1 --pretty=%s)"\' >> .git/hooks/post-commit && chmod +x .git/hooks/post-commit' },
  { group: "AI agents", title: "When an AI agent finishes", code: 'your-agent run task.md; notchi notify "Agent finished 🤖"' },
  { group: "AI agents", title: "Long-running scripts", code: 'python train.py && notchi notify "Training done 📈" || notchi notify "Training crashed 💥"' },
  { group: "Everyday", title: "Long exports", code: 'for i in {0..100..10}; do notchi progress $i "Exporting"; sleep 1; done' },
  { group: "Everyday", title: "Downloads", code: 'curl -LO https://example.com/big.zip && notchi notify "Download finished ⬇️"' },
  { group: "Everyday", title: "A quick timer", code: 'sleep 1500 && notchi notify "25 minutes up ⏰"' },
  { group: "Everyday", title: "Switch theme at night", code: '[ $(date +%H) -ge 19 ] && notchi apply midnight || notchi apply paper' },
  { group: "Everyday", title: "Docker containers", code: 'docker compose up -d && notchi notify "Containers are up 🐳"' },
];

function CopyBtn({ text }: { text: string }) {
  const [done, setDone] = useState(false);
  return (
    <button
      className="cr-copy"
      aria-label={done ? "Copied" : `Copy ${text}`}
      onClick={() => {
        navigator.clipboard?.writeText(text).catch(() => {});
        setDone(true);
        setTimeout(() => setDone(false), 1400);
      }}
    >
      <AnimatePresence mode="popLayout" initial={false}>
        <motion.span key={String(done)} initial={{ scale: 0.4, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.4, opacity: 0 }} style={{ display: "grid" }}>
          {done ? <Check width={15} height={15} /> : <Copy width={15} height={15} />}
        </motion.span>
      </AnimatePresence>
    </button>
  );
}

export default function CommandReference() {
  const [group, setGroup] = useState<string>("Notch");
  const g = GROUPS.find((x) => x.name === group)!;

  return (
    <section className="section" id="commands" data-notch="Command reference">
      <div className="wrap">
        <SectionHead eyebrow="Command reference" title={"Every\ncommand"} sub="The notchi command ships inside Notchi.app. Everything here works today." />
        <div className="cr">
          <div className="seg cr-tabs" role="tablist" aria-label="Command groups">
            {GROUPS.map((x) => (
              <button key={x.name} role="tab" aria-selected={group === x.name} className={group === x.name ? "on" : ""} onClick={() => setGroup(x.name)}>
                {group === x.name && <motion.i layoutId="cr-pill" className="seg-pill" transition={{ type: "spring", stiffness: 420, damping: 32 }} />}
                <span>{x.name}</span>
              </button>
            ))}
          </div>
          <AnimatePresence mode="wait">
            <motion.ul key={group} className="cr-list" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }} transition={{ duration: 0.25 }}>
              {g.cmds.map(([c, d]) => (
                <li key={c}>
                  <code><span className="cr-dollar">$</span> {c}</code>
                  <span className="cr-desc">{d}</span>
                  <CopyBtn text={c} />
                </li>
              ))}
            </motion.ul>
          </AnimatePresence>
        </div>

        <h3 className="cr-h">Recipes <em>{RECIPES.length}</em></h3>
        <div className="cr-recipes">
          {RECIPES.map((r, i) => (
            <motion.div
              key={r.title}
              className="cr-recipe"
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, amount: 0.4 }}
              transition={{ delay: i * 0.07, type: "spring", stiffness: 140, damping: 18 }}
            >
              <div className="cr-recipe-top"><span><em>{r.group}</em><b>{r.title}</b></span><CopyBtn text={r.code} /></div>
              <code>{r.code}</code>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
