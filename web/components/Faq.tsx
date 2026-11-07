"use client";

import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";

const QA: { q: string; a: string; tag: string }[] = [
  { tag: "Basics", q: "Is Notchi really free?", a: "Yes. It's open source under GPL-3.0, with no paid tier, no ads, no subscription and no tracking. It's built in public on GitHub." },
  { tag: "Basics", q: "Which Macs does it work on?", a: "macOS 14 Sonoma or newer, on Apple Silicon and Intel. On a MacBook with a notch the island sits over it; on other screens Notchi draws a virtual island at the top centre." },
  { tag: "Privacy", q: "Does Notchi send any of my data anywhere?", a: "No. Everything happens on your Mac. The only network calls are update checks (which you can turn off) and, later, the optional community theme gallery. It never uses screen recording." },
  { tag: "Privacy", q: "How does it know what's playing in Safari, Chrome or Spotify?", a: "It reads the same Now Playing information macOS shows in Control Center. Since macOS 15.4 only Apple-signed programs may read that, so Notchi loads a tiny open-source helper into the perl that ships with macOS. The helper only reads the song or video title, artist, artwork and position, and passes play/pause/skip back. Nothing leaves your Mac." },
  { tag: "Permissions", q: "Why does it ask for Accessibility?", a: "Only for the volume and brightness keys. To stop the macOS indicator from showing on top of Notchi's, Notchi has to see those keys first. It's asked only when you turn that feature on, and the rest of the app works without it." },
  { tag: "Permissions", q: "Why does it ask to control Music or Spotify?", a: "Only on older setups where the system-wide Now Playing helper can't run. Then Notchi talks to Music and Spotify directly for artwork and controls, and macOS asks once." },
  { tag: "Permissions", q: "I allowed Accessibility but the macOS volume indicator still shows twice.", a: "If you build Notchi yourself, each ad hoc build gets a new signature and macOS quietly stops applying the permission. Run ./scripts/dev-signing.sh once, rebuild, and allow Notchi again. notchi doctor tells you if this is the problem." },
  { tag: "Install", q: "macOS says it can't check Notchi for malware. Is that safe?", a: "Notchi is signed with a free self-signed certificate instead of a paid Apple Developer ID, so macOS shows that warning the first time. Open System Settings → Privacy & Security, scroll down and click Open Anyway next to Notchi, then open it again. You can read every line of the code on GitHub." },
  { tag: "Install", q: "How do I undo everything Notchi changed?", a: "Icons: menu bar → Restore Original Icons, or notchi icon restore --all. Wallpaper: menu bar → Live Wallpaper → Turn Off. Then quit Notchi and drag it to the Trash. Notchi never edits system files." },
  { tag: "Battery", q: "Will it drain my battery?", a: "It's designed not to. Animations drop to 15 fps on battery and stop in Low Power Mode, and the video wallpaper pauses whenever it's covered and while your screen is asleep." },
  { tag: "Basics", q: "Can I make my own theme?", a: "Yes. Use the theme builder on the Themes page to download a theme file, put it in ~/Library/Application Support/Notchi/Themes, reopen Notchi and pick it from the menu bar." },
  { tag: "Basics", q: "How do I report a bug or ask for a feature?", a: "Open an issue on GitHub. Running notchi doctor and pasting its output helps a lot." },
];

const TAGS = ["All", ...Array.from(new Set(QA.map((x) => x.tag)))];

export default function Faq() {
  const [open, setOpen] = useState<number | null>(0);
  const [tag, setTag] = useState("All");
  const list = QA.map((x, i) => ({ ...x, i })).filter((x) => tag === "All" || x.tag === tag);

  return (
    <section className="section" id="questions" data-notch="Questions">
      <div className="wrap faq">
        <div className="seg faq-tags" role="tablist" aria-label="Filter questions">
          {TAGS.map((t) => (
            <button key={t} role="tab" aria-selected={tag === t} className={tag === t ? "on" : ""} onClick={() => setTag(t)}>
              {tag === t && <motion.i layoutId="faq-pill" className="seg-pill" transition={{ type: "spring", stiffness: 420, damping: 32 }} />}
              <span>{t}</span>
            </button>
          ))}
        </div>
        <motion.ul className="faq-list" layout>
          {list.map((x) => {
            const on = open === x.i;
            return (
              <motion.li key={x.q} layout className={on ? "on" : ""} initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }}>
                <button aria-expanded={on} aria-controls={`faq-${x.i}`} onClick={() => setOpen(on ? null : x.i)}>
                  <em>{x.tag}</em>
                  <b>{x.q}</b>
                  <motion.span className="faq-plus" animate={{ rotate: on ? 45 : 0 }} aria-hidden>+</motion.span>
                </button>
                <AnimatePresence initial={false}>
                  {on && (
                    <motion.div id={`faq-${x.i}`} className="faq-a" initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} transition={{ type: "spring", stiffness: 260, damping: 30 }}>
                      <p>{x.a}</p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.li>
            );
          })}
        </motion.ul>
      </div>
    </section>
  );
}
