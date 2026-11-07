"use client";

import { AnimatePresence, motion, useInView } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { applyTheme } from "@/lib/applyTheme";
import { THEMES, type ThemeId } from "@/lib/themes";
import { Reveal, SectionHead } from "./ui";

type Notch = { kind: "idle" } | { kind: "theme"; name: string } | { kind: "progress"; n: number; label: string } | { kind: "notify"; msg: string } | { kind: "ok" };
type Line = { t: "cmd" | "out" | "err"; s: string };

const DEMO: { cmd: string; out: string[]; notch: Notch }[] = [
  { cmd: 'notchi notify "Build done ✅"', out: ["✓ Sent to the notch"], notch: { kind: "notify", msg: "Build done ✅" } },
  { cmd: 'notchi progress 42 "Exporting"', out: ["▸ Progress is showing in the notch"], notch: { kind: "progress", n: 42, label: "Exporting" } },
  { cmd: "notchi doctor", out: ["✓ Accessibility      granted", "✓ Conflicting apps   none", "✓ Energy governor    on"], notch: { kind: "ok" } },
];

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const ids = THEMES.map((t) => t.id);

function run(input: string): { out: Line[]; notch?: Notch; clear?: boolean; theme?: ThemeId } {
  const raw = input.trim();
  if (!raw) return { out: [] };
  const [cmd, sub, ...rest] = raw.split(/\s+/);
  const quoted = raw.match(/"([^"]*)"/)?.[1];
  if (cmd === "clear") return { out: [], clear: true };
  if (cmd !== "notchi") return { out: [{ t: "err", s: `zsh: command not found: ${cmd}. Try: notchi help` }] };
  switch (sub) {
    case undefined:
    case "help":
      return { out: ["notchi apply <theme>       apply a theme", "notchi theme list          list themes", 'notchi notify "<message>"  show it in the notch', 'notchi progress <0-100> "<label>"', "notchi doctor              check permissions", "clear"].map((s) => ({ t: "out", s })) };
    case "theme":
      return { out: ids.map((s) => ({ t: "out", s: `  ${s}` })) };
    case "apply": {
      const id = rest[0] as ThemeId;
      if (!ids.includes(id)) return { out: [{ t: "err", s: `No theme "${rest[0] ?? ""}". Try: ${ids.join(", ")}` }] };
      const name = THEMES.find((t) => t.id === id)!.name;
      return { out: [{ t: "out", s: `✓ ${name} applied to this whole page` }], notch: { kind: "theme", name }, theme: id };
    }
    case "notify": {
      const msg = quoted ?? rest.join(" ");
      if (!msg) return { out: [{ t: "err", s: 'Usage: notchi notify "<message>"' }] };
      return { out: [{ t: "out", s: "✓ Sent to the notch" }], notch: { kind: "notify", msg: msg.slice(0, 40) } };
    }
    case "progress": {
      const n = Math.max(0, Math.min(100, parseInt(rest[0] ?? "", 10) || 0));
      return { out: [{ t: "out", s: `▸ ${n}% is showing in the notch` }], notch: { kind: "progress", n, label: quoted ?? "Working" } };
    }
    case "doctor":
      return { out: DEMO[2].out.map((s) => ({ t: "out", s })), notch: { kind: "ok" } };
    default:
      return { out: [{ t: "err", s: `Unknown command "${sub}". Try: notchi help` }] };
  }
}

function MiniNotch({ n }: { n: Notch }) {
  const size = n.kind === "idle" ? { w: 160, h: 30 } : n.kind === "progress" ? { w: 330, h: 62 } : { w: 310, h: 56 };
  return (
    <motion.div className="mn" animate={{ width: size.w, height: size.h }} transition={{ type: "spring", stiffness: 380, damping: 26 }}>
      <AnimatePresence mode="popLayout" initial={false}>
        {n.kind !== "idle" && (
          <motion.div
            key={JSON.stringify(n)}
            className="mn-row"
            initial={{ opacity: 0, y: -8, filter: "blur(4px)" }}
            animate={{ opacity: 1, y: 0, filter: "blur(0px)", transition: { delay: 0.12 } }}
            exit={{ opacity: 0, filter: "blur(4px)", transition: { duration: 0.12 } }}
          >
            {n.kind === "notify" && <><span className="mn-ic">⌘</span><b>{n.msg}</b></>}
            {n.kind === "ok" && <><span className="mn-ic">✓</span><b>All good. No conflicts.</b></>}
            {n.kind === "theme" && <><motion.span className="mn-ic" animate={{ rotate: 360 }} transition={{ duration: 0.8 }}>◐</motion.span><b>{n.name} applied</b></>}
            {n.kind === "progress" && (
              <div className="mn-prog">
                <div className="mn-pl"><b>{n.label}</b><span>{n.n}%</span></div>
                <div className="mn-bar"><motion.i initial={{ width: 0 }} animate={{ width: `${n.n}%` }} transition={{ duration: 1.2, ease: [0.2, 0.9, 0.2, 1] }} /></div>
              </div>
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}

export default function Terminal() {
  const [lines, setLines] = useState<Line[]>([]);
  const [typing, setTyping] = useState("");
  const [notch, setNotch] = useState<Notch>({ kind: "idle" });
  const [mine, setMine] = useState(false);
  const [value, setValue] = useState("");
  const [hist, setHist] = useState<string[]>([]);
  const [hi, setHi] = useState(-1);
  const box = useRef<HTMLDivElement>(null);
  const body = useRef<HTMLDivElement>(null);
  const input = useRef<HTMLInputElement>(null);
  const inView = useInView(box, { amount: 0.45 });

  // autoplay demo until the visitor types
  useEffect(() => {
    if (!inView || mine) return;
    let dead = false;
    (async () => {
      while (!dead) {
        setLines([]); setNotch({ kind: "idle" });
        await sleep(600);
        for (const step of DEMO) {
          for (let i = 1; i <= step.cmd.length && !dead; i++) { setTyping(step.cmd.slice(0, i)); await sleep(34 + Math.random() * 40); }
          await sleep(260); if (dead) return;
          setTyping(""); setLines((l) => [...l, { t: "cmd", s: step.cmd }]);
          await sleep(220); if (dead) return;
          setNotch(step.notch);
          for (const o of step.out) { setLines((l) => [...l, { t: "out", s: o }]); await sleep(140); }
          await sleep(2300); if (dead) return;
          setNotch({ kind: "idle" });
          await sleep(500);
        }
        await sleep(1200);
      }
    })();
    return () => { dead = true; };
  }, [inView, mine]);

  useEffect(() => { body.current?.scrollTo({ top: 1e6, behavior: "smooth" }); }, [lines, typing]);

  const takeOver = () => {
    if (mine) return;
    setMine(true); setTyping("");
    setLines([{ t: "out", s: "Your turn. Try: notchi apply sakura · notchi notify \"hi\" · notchi help" }]);
    setNotch({ kind: "idle" });
  };

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const r = run(value);
    if (r.clear) setLines([]);
    else setLines((l) => [...l.slice(-30), { t: "cmd", s: value }, ...r.out]);
    if (value.trim()) setHist((h) => [...h, value]);
    setHi(-1);
    if (r.notch) setNotch(r.notch);
    if (r.theme) {
      const rect = input.current?.getBoundingClientRect();
      applyTheme(r.theme, rect ? rect.left + 40 : innerWidth / 2, rect ? rect.top : innerHeight / 2);
    }
    setValue("");
  };

  const keys = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "ArrowUp" && hist.length) {
      e.preventDefault();
      const n = hi < 0 ? hist.length - 1 : Math.max(0, hi - 1);
      setHi(n); setValue(hist[n]);
    } else if (e.key === "ArrowDown" && hi >= 0) {
      e.preventDefault();
      const n = hi + 1;
      if (n >= hist.length) { setHi(-1); setValue(""); } else { setHi(n); setValue(hist[n]); }
    }
  };

  return (
    <section className="section" id="cli" data-notch="CLI">
      <div className="wrap cli-grid">
        <div>
          <SectionHead eyebrow="For terminal people" title={"Talk to\nyour notch"} sub="The notchi command-line tool shows build results, git pushes and AI-agent status right in the notch. Apply themes, set wallpapers and icons, all from your shell." />
          <Reveal delay={0.25} className="cli-tip">
            <span className="small-caps">This terminal is real.</span> Click it and type <code>notchi apply midnight</code>.
          </Reveal>
        </div>
        <Reveal y={60} delay={0.1}>
          <div className="term-wrap" ref={box}>
            <MiniNotch n={notch} />
            <div className="term" onClick={() => { takeOver(); input.current?.focus({ preventScroll: true }); }} data-hover>
              <div className="term-bar"><i /><i /><i /><span>~/projects/app · zsh</span></div>
              <div className="term-body" ref={body} data-lenis-prevent>
                {lines.map((l, i) => (
                  <div key={i} className={`tl ${l.t}`}>{l.t === "cmd" && <span className="ps">❯</span>}{l.s}</div>
                ))}
                {!mine ? (
                  <div className="tl cmd"><span className="ps">❯</span>{typing}<span className="caret" /></div>
                ) : (
                  <form onSubmit={submit} className="tl cmd">
                    <span className="ps">❯</span>
                    <input
                      ref={input}
                      value={value}
                      onChange={(e) => setValue(e.target.value)}
                      onKeyDown={keys}
                      aria-label="Type a notchi command"
                      spellCheck={false}
                      autoCapitalize="off"
                      autoComplete="off"
                      autoFocus
                    />
                  </form>
                )}
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
