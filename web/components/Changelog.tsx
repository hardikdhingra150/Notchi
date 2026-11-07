"use client";

import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { RELEASES, type Change } from "@/lib/changelog";

const FILTERS = ["All", "App", "Website"] as const;
const KIND: Record<Change["kind"], string> = { new: "New", better: "Better", fix: "Fixed" };
const STATUS = { unreleased: "In progress", complete: "Feature-complete", released: "Live" } as const;

export default function Changelog() {
  const [f, setF] = useState<(typeof FILTERS)[number]>("All");
  const releases = RELEASES.map((r) => ({ ...r, changes: r.changes.filter((c) => f === "All" || c.area === f) })).filter((r) => r.changes.length);

  return (
    <section className="section" id="changes" data-notch="Changelog">
      <div className="wrap cl">
        <div className="seg" role="tablist" aria-label="Filter changes">
          {FILTERS.map((x) => (
            <button key={x} role="tab" aria-selected={f === x} className={f === x ? "on" : ""} onClick={() => setF(x)}>
              {f === x && <motion.i layoutId="cl-pill" className="seg-pill" transition={{ type: "spring", stiffness: 420, damping: 32 }} />}
              <span>{x}</span>
            </button>
          ))}
        </div>

        <div className="cl-list">
          <AnimatePresence mode="popLayout" initial={false}>
            {releases.map((r, i) => (
              <motion.article
                key={r.version}
                layout
                className={`cl-rel ${r.status}`}
                initial={{ opacity: 0, y: 50 }}
                whileInView={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.97 }}
                viewport={{ once: true, amount: 0.15 }}
                transition={{ type: "spring", stiffness: 120, damping: 18, delay: i === 0 ? 0.1 : 0 }}
              >
                <header>
                  <span className="cl-v">{r.version}</span>
                  <span className={`cl-status ${r.status}`}><i />{STATUS[r.status]}</span>
                  <time dateTime={r.date}>{new Date(r.date + "T12:00:00").toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" })}</time>
                </header>
                <h2>{r.label}</h2>
                <p className="cl-sum">{r.summary}</p>
                <ul>
                  {r.changes.map((c) => (
                    <li key={c.text}>
                      <span className={`cl-kind ${c.kind}`}>{KIND[c.kind]}</span>
                      <span>{c.text}</span>
                      {f === "All" && <em>{c.area}</em>}
                    </li>
                  ))}
                </ul>
              </motion.article>
            ))}
          </AnimatePresence>
        </div>
      </div>
    </section>
  );
}
