"use client";

import { motion, useScroll, useSpring, useTransform } from "motion/react";
import Image from "next/image";
import { useEffect, useRef, useState } from "react";
import { SectionHead } from "./ui";

type Shot = { src: string; title: string; line: string; cmd?: string; tall?: boolean };

/** Rendered straight from the app with `Notchi --snapshot`. Not mockups. */
const SHOTS: Shot[] = [
  { src: "closed", title: "Resting", line: "Sits over the notch with a soft breathing glow in your theme colour." },
  { src: "compact-music", title: "Now playing", line: "Album art and a live visualizer hug the notch while Music or Spotify plays." },
  { src: "expanded-player", title: "Hover to open", line: "Play, pause and skip without leaving what you're doing." },
  { src: "expanded-home", title: "Home", line: "Time, date and battery at a glance." },
  { src: "volume", title: "Volume", line: "Takes over from the macOS volume indicator, so only one shows." },
  { src: "brightness", title: "Brightness", line: "Same for the brightness keys. Shift+Option for fine steps." },
  { src: "notify", title: "Terminal pings", line: "Your scripts can talk to the notch.", cmd: 'notchi notify "Build done ✅"' },
  { src: "progress", title: "Progress", line: "Long jobs show a live bar.", cmd: 'notchi progress 42 "Exporting"' },
  { src: "theme", title: "Theme switch", line: "One theme recolours the notch, wallpaper and icons.", cmd: "notchi apply neon-rain" },
  { src: "battery", title: "Charging", line: "Plug in and the notch says so. Low battery gets a warning." },
  { src: "shelf", title: "File shelf", line: "Drop files on the notch, drag them out later or AirDrop them all.", tall: true },
];

const DONE = [
  "Notch island", "Now playing + controls", "Volume & brightness HUD", "File shelf",
  "Live video wallpaper", "Icon studio", "notchi CLI", "Onboarding", "Auto-updates",
];

export default function Shipped() {
  const outer = useRef<HTMLDivElement>(null);
  const track = useRef<HTMLDivElement>(null);
  const [dist, setDist] = useState(0);

  // how far the track has to slide so the last card ends at the right edge
  useEffect(() => {
    const el = track.current;
    if (!el) return;
    const ro = new ResizeObserver(() => setDist(Math.max(0, el.scrollWidth - el.clientWidth)));
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const { scrollYProgress } = useScroll({ target: outer, offset: ["start start", "end end"] });
  const p = useSpring(scrollYProgress, { stiffness: 140, damping: 30, restDelta: 0.001 });
  const x = useTransform(p, (v) => -v * dist);
  const bar = useTransform(p, [0, 1], ["0%", "100%"]);

  return (
    <section className="section shipped" id="shipped" data-notch="v0.1 is real">
      <div className="wrap">
        <SectionHead
          eyebrow="v0.1 · built so far"
          title={"Already\nworking"}
          sub="No mockups. Every frame below is rendered from the real app with Notchi --snapshot, straight from the repo."
        />
      </div>

      <div className="ship-outer" ref={outer} style={{ height: `calc(100vh + ${dist}px)` }}>
        <div className="ship-sticky">
          <motion.div className="ship-track" ref={track} style={{ x }}>
            {SHOTS.map((s, i) => (
              <motion.figure
                key={s.src}
                className={`shot${s.tall ? " tall" : ""}`}
                initial={{ opacity: 0, y: 70, rotate: i % 2 ? 2.5 : -2.5 }}
                whileInView={{ opacity: 1, y: 0, rotate: 0 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ type: "spring", stiffness: 110, damping: 17, delay: Math.min(i, 3) * 0.06 }}
                whileHover={{ y: -8, rotate: i % 2 ? 1 : -1 }}
              >
                <div className="shot-screen">
                  <Image src={`/shots/${s.src}.png`} alt={`Notchi island: ${s.title}`} width={1040} height={s.tall ? 520 : 340} sizes="(max-width: 760px) 90vw, 520px" />
                </div>
                <figcaption>
                  <span className="shot-no">{String(i + 1).padStart(2, "0")}</span>
                  <h3>{s.title}</h3>
                  <p>{s.line}</p>
                  {s.cmd && <code>$ {s.cmd}</code>}
                </figcaption>
              </motion.figure>
            ))}
          </motion.div>
          <div className="ship-progress" aria-hidden><motion.i style={{ width: bar }} /></div>
        </div>
      </div>

      <div className="wrap">
        <motion.ul
          className="ship-done"
          initial="hide"
          whileInView="show"
          viewport={{ once: true, amount: 0.4 }}
          variants={{ show: { transition: { staggerChildren: 0.06 } } }}
          aria-label="Shipped in v0.1"
        >
          {DONE.map((d) => (
            <motion.li key={d} variants={{ hide: { opacity: 0, scale: 0.6, y: 20 }, show: { opacity: 1, scale: 1, y: 0, transition: { type: "spring", stiffness: 300, damping: 18 } } }}>
              <svg viewBox="0 0 16 16" width="15" height="15" aria-hidden>
                <motion.path d="M3 8.5l3.2 3L13 4.5" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"
                  variants={{ hide: { pathLength: 0 }, show: { pathLength: 1, transition: { duration: 0.5, delay: 0.15 } } }} />
              </svg>
              {d}
            </motion.li>
          ))}
        </motion.ul>
      </div>
    </section>
  );
}
