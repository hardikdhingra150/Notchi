"use client";

import { AnimatePresence, motion, useInView } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { THEMES } from "@/lib/themes";
import { useTheme } from "@/lib/useTheme";
import { SectionHead } from "./ui";

/* A working copy of the real Notchi island (v0.1+): same sizes, same pages,
   same behaviour. Hover to open, dots or swipe for pages, the pill opens the
   player, pages slide back Home after 10 s, and the keys under the screen
   drive the volume and brightness indicators. */

const NOTCH = { w: 180, h: 32 };
const spring = { type: "spring", stiffness: 380, damping: 32, mass: 0.9 } as const;

type Track = { title: string; artist: string; app: string; appColor: string; dur: number; art: [string, string] };
const TRACKS: Track[] = [
  { title: "Night Drive", artist: "Notchi Radio", app: "Music", appColor: "#fa2d48", dur: 214, art: ["#ff6a3d", "#ffc64a"] },
  { title: "How the notch island works", artist: "Notchi", app: "Safari", appColor: "#1e88ff", dur: 754, art: ["#3fa9f5", "#8f7cff"] },
  { title: "Lo-fi to theme your Mac to", artist: "Notchi FM", app: "Spotify", appColor: "#1ed760", dur: 187, art: ["#4f9a3a", "#e9c46a"] },
];

type Page = "home" | "player" | "shelf";
type Banner = { kind: "volume"; v: number; muted: boolean } | { kind: "brightness"; v: number } | { kind: "notify"; msg: string } | null;

const clock = (s: number) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`;
const step = (v: number, d: number) => Math.min(1, Math.max(0, (Math.round(v * 16) + d) / 16));

function useClock() {
  const [now, setNow] = useState<Date | null>(null);
  useEffect(() => {
    const tick = () => setNow(new Date());
    const t = setTimeout(tick, 0);
    const id = setInterval(tick, 20_000);
    return () => { clearTimeout(t); clearInterval(id); };
  }, []);
  return now;
}

function Art({ t, size, badge }: { t: Track; size: number; badge?: boolean }) {
  return (
    <span className="sim-art" style={{ width: size, height: size, borderRadius: size * 0.2, background: `linear-gradient(135deg, ${t.art[0]}, ${t.art[1]})` }}>
      <svg viewBox="0 0 24 24" width={size * 0.42} height={size * 0.42} aria-hidden><path d="M9 17V5l10-2v12M9 17a3 3 0 1 1-3-3 3 3 0 0 1 3 3Zm10-2a3 3 0 1 1-3-3 3 3 0 0 1 3 3Z" fill="none" stroke="rgba(0,0,0,.7)" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" /></svg>
      {badge && <i className="sim-badge" style={{ background: t.appColor }}>{t.app[0]}</i>}
    </span>
  );
}

function Eq({ on, n = 6, h = 28 }: { on: boolean; n?: number; h?: number }) {
  return (
    <span className="sim-eq" style={{ height: h }} aria-hidden>
      {Array.from({ length: n }, (_, i) => <i key={i} className={on ? "on" : ""} style={{ animationDelay: `${i * 0.12}s` }} />)}
    </span>
  );
}

const Icon = {
  play: <path d="M7 5v14l12-7z" fill="currentColor" />,
  pause: <path d="M7 5h3.5v14H7zM13.5 5H17v14h-3.5z" fill="currentColor" />,
  prev: <path d="M11 6v12L3 12zM20 6v12l-8-6z" fill="currentColor" />,
  next: <path d="M13 6v12l8-6zM4 6v12l8-6z" fill="currentColor" />,
  speaker: <path d="M4 9h4l5-4v14l-5-4H4z" fill="currentColor" />,
  sun: <><circle cx="12" cy="12" r="4.5" fill="currentColor" /><path d="M12 2v2.5M12 19.5V22M2 12h2.5M19.5 12H22M4.9 4.9l1.8 1.8M17.3 17.3l1.8 1.8M4.9 19.1l1.8-1.8M17.3 6.7l1.8-1.8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" /></>,
  term: <path d="m5 7 5 5-5 5M12 17h7" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />,
};
const Svg = ({ d, s = 18 }: { d: keyof typeof Icon; s?: number }) => <svg viewBox="0 0 24 24" width={s} height={s} aria-hidden>{Icon[d]}</svg>;

export default function NotchSimulator() {
  const themeId = useTheme();
  const theme = THEMES.find((t) => t.id === themeId) ?? THEMES[0];
  const now = useClock();

  const [open, setOpen] = useState(false);
  const [page, setPage] = useState<Page>("home");
  const [dir, setDir] = useState(1);
  const [banner, setBanner] = useState<Banner>(null);
  const [playing, setPlaying] = useState(true);
  const [ti, setTi] = useState(0);
  const [elapsed, setElapsed] = useState(63);
  const [vol, setVol] = useState({ v: 0.5, muted: false });
  const [bright, setBright] = useState(0.75);
  const [shelf, setShelf] = useState<string[]>([]);

  const root = useRef<HTMLDivElement>(null);
  const inView = useInView(root, { amount: 0.3 });
  const bannerT = useRef<ReturnType<typeof setTimeout>>(undefined);
  const homeT = useRef<ReturnType<typeof setTimeout>>(undefined);
  const leaveT = useRef<ReturnType<typeof setTimeout>>(undefined);
  const swipe = useRef({ x: 0, used: false, t: 0 });
  const track = TRACKS[ti];

  const pages: Page[] = ["home", "player", ...(shelf.length ? (["shelf"] as Page[]) : [])];
  const current: Page = pages.includes(page) ? page : "home";

  // the track keeps playing while you watch
  useEffect(() => {
    if (!playing || !inView) return;
    const id = setInterval(() => setElapsed((e) => (e + 1 >= track.dur ? 0 : e + 1)), 1000);
    return () => clearInterval(id);
  }, [playing, inView, track.dur]);

  const scheduleHome = useCallback(() => {
    clearTimeout(homeT.current);
    homeT.current = setTimeout(() => { setDir(-1); setPage("home"); }, 10_000);
  }, []);

  const go = (p: Page) => {
    const from = pages.indexOf(current), to = pages.indexOf(p);
    if (p === current) return scheduleHome();
    setDir(to > from ? 1 : -1);
    setPage(p);
    if (p === "home") clearTimeout(homeT.current); else scheduleHome();
  };

  const show = (b: Banner, ms = 1600) => {
    clearTimeout(bannerT.current);
    setBanner(b);
    bannerT.current = setTimeout(() => setBanner(null), ms);
  };

  const enter = () => { clearTimeout(leaveT.current); setOpen(true); };
  const leave = () => {
    clearTimeout(leaveT.current);
    leaveT.current = setTimeout(() => { setOpen(false); setPage("home"); setDir(1); clearTimeout(homeT.current); }, 220);
  };

  useEffect(() => () => { clearTimeout(bannerT.current); clearTimeout(homeT.current); clearTimeout(leaveT.current); }, []);

  const volume = (d: number) => {
    const v = step(vol.v, d);
    const next = { v, muted: d > 0 ? false : vol.muted };
    setVol(next);
    show({ kind: "volume", ...next });
  };
  const mute = () => { const next = { ...vol, muted: !vol.muted }; setVol(next); show({ kind: "volume", ...next }); };
  const brightness = (d: number) => { const v = Math.max(0.0625, step(bright, d)); setBright(v); show({ kind: "brightness", v }); };
  const skip = (d: number) => { setTi((i) => (i + d + TRACKS.length) % TRACKS.length); setElapsed(0); setPlaying(true); };
  const notify = () => show({ kind: "notify", msg: "Build done ✅" }, 3200);
  const drop = () => {
    const names = ["Mockup.png", "Notes.md", "Invoice.pdf", "Demo.mov", "Logo.svg"];
    setShelf((s) => [...s, names[s.length % names.length]].slice(-5));
    enter();
    setDir(1); setPage("shelf"); scheduleHome();
  };

  const onKey = (e: React.KeyboardEvent) => {
    const map: Record<string, () => void> = {
      ArrowUp: () => volume(1), ArrowDown: () => volume(-1), m: mute,
      ArrowRight: () => brightness(1), ArrowLeft: () => brightness(-1), " ": () => setPlaying((p) => !p),
    };
    const f = map[e.key];
    if (f) { e.preventDefault(); f(); }
  };

  const onWheel = (e: React.WheelEvent) => {
    if (!open || Math.abs(e.deltaX) < Math.abs(e.deltaY)) return;
    const s = swipe.current;
    if (performance.now() - s.t > 350) { s.x = 0; s.used = false; }
    s.t = performance.now();
    if (s.used) return;
    s.x += e.deltaX;
    if (Math.abs(s.x) > 40) {
      s.used = true;
      const i = pages.indexOf(current) + (s.x > 0 ? 1 : -1);
      if (pages[i]) go(pages[i]);
    }
  };

  // sizes match the app (IslandModel.size)
  const mode = open ? "expanded" : banner ? "banner" : playing ? "compact" : "closed";
  const isLevel = banner?.kind === "volume" || banner?.kind === "brightness";
  const size =
    mode === "expanded" ? { w: 520, h: NOTCH.h + 132 + 14 }
    : mode === "banner" ? (isLevel ? { w: 320, h: NOTCH.h + 40 } : { w: 380, h: NOTCH.h + 50 })
    : mode === "compact" ? { w: NOTCH.w + 2 * (NOTCH.h + 14), h: NOTCH.h }
    : NOTCH;

  const slide = {
    enter: (d: number) => ({ x: d > 0 ? 70 : -70, opacity: 0 }),
    center: { x: 0, opacity: 1 },
    exit: (d: number) => ({ x: d > 0 ? -70 : 70, opacity: 0 }),
  };

  return (
    <section className="section" id="simulator" data-notch="Try the notch">
      <div className="wrap">
        <SectionHead
          eyebrow="Live simulator"
          title={"Try the\nreal thing"}
          sub="This is the actual island from the app, rebuilt for the browser: same sizes, same pages, same timing. Hover it, swipe it, press the keys."
        />

        <div className="sim" ref={root} tabIndex={0} onKeyDown={onKey} aria-label="Notchi simulator. Arrow keys change volume and brightness, M mutes, space plays or pauses.">
          <div className="sim-screen" style={{ ["--b" as string]: 0.35 + bright * 0.65 }}>
            <div className="sim-wall" aria-hidden><i /><i /><i /></div>
            <div className="sim-menubar" aria-hidden>
              <span className="sim-apple" />
              <b>Finder</b><span>File</span><span>Edit</span><span>View</span>
              <span className="sim-mb-right">{now ? now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }) : ""}</span>
            </div>

            <motion.div
              className={`sim-island ${mode}`}
              initial={false}
              animate={{ width: size.w, height: size.h, borderBottomLeftRadius: mode === "expanded" ? 30 : mode === "banner" ? 22 : 12, borderBottomRightRadius: mode === "expanded" ? 30 : mode === "banner" ? 22 : 12 }}
              transition={spring}
              onMouseEnter={enter}
              onMouseLeave={leave}
              onClick={() => !open && enter()}
              onWheel={onWheel}
              style={{ boxShadow: mode === "expanded" || mode === "banner" ? `0 6px 28px color-mix(in srgb, ${theme.accent} 45%, transparent)` : "none" }}
            >
              <AnimatePresence mode="popLayout" initial={false}>
                {mode === "compact" && (
                  <motion.div key="compact" className="sim-compact" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
                    <Art t={track} size={22} />
                    <Eq on={playing} n={4} h={16} />
                  </motion.div>
                )}

                {mode === "banner" && banner && (
                  <motion.div key={`b-${banner.kind}`} className="sim-banner" initial={{ opacity: 0, scale: 0.92 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }}>
                    {banner.kind === "notify" ? (
                      <>
                        <span className="sim-pillicon"><Svg d="term" s={16} /></span>
                        <b>{banner.msg}</b>
                      </>
                    ) : (
                      <>
                        <span className="sim-lvl-ico"><Svg d={banner.kind === "volume" ? "speaker" : "sun"} /></span>
                        <span className="sim-lvl"><motion.i animate={{ width: `${Math.max(4, (banner.kind === "volume" && banner.muted ? 0 : banner.v) * 100)}%` }} transition={{ type: "spring", stiffness: 500, damping: 40 }} className={banner.kind === "volume" && banner.muted ? "muted" : ""} /></span>
                      </>
                    )}
                  </motion.div>
                )}

                {mode === "expanded" && (
                  <motion.div key="expanded" className="sim-open" initial={{ opacity: 0 }} animate={{ opacity: 1, transition: { delay: 0.08 } }} exit={{ opacity: 0, transition: { duration: 0.1 } }}>
                    <div className="sim-pages">
                      <AnimatePresence mode="popLayout" custom={dir} initial={false}>
                        <motion.div key={current} className="sim-page" custom={dir} variants={slide} initial="enter" animate="center" exit="exit" transition={spring}>
                          {current === "home" && (
                            <div className="sim-home">
                              <div>
                                <b className="sim-time">{now ? now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", hour12: false }) : "--:--"}</b>
                                <span className="sim-dim">{now ? now.toLocaleDateString([], { weekday: "long", day: "numeric", month: "short" }) : ""}</span>
                              </div>
                              <div className="sim-right">
                                <span className="sim-batt"><i style={{ width: "82%" }} /></span><b className="sim-small">82%</b>
                                <span className="sim-theme"><i />{theme.name}</span>
                                <span className="sim-pillrow">
                                  <button className="sim-pill" onClick={() => go("player")} aria-label={`Now playing: ${track.title}. Open the player`}>
                                    <Art t={track} size={26} />
                                    <span><b>{track.title}</b><em>{playing ? "Playing" : "Paused"} · {track.app}</em></span>
                                    <span className="sim-chev">›</span>
                                  </button>
                                  <button className="sim-btn" onClick={() => setPlaying((p) => !p)} aria-label={playing ? "Pause" : "Play"}><Svg d={playing ? "pause" : "play"} s={14} /></button>
                                </span>
                              </div>
                            </div>
                          )}
                          {current === "player" && (
                            <div className="sim-player">
                              <Art t={track} size={78} badge />
                              <div className="sim-meta">
                                <b>{track.title}</b>
                                <span className="sim-dim">{track.app === "Music" || track.app === "Spotify" ? track.artist : `${track.artist} · ${track.app}`}</span>
                                <span className="sim-prog">
                                  <em>{clock(elapsed)}</em>
                                  <span><i style={{ width: `${(elapsed / track.dur) * 100}%` }} /></span>
                                  <em>-{clock(track.dur - elapsed)}</em>
                                </span>
                                <span className="sim-ctrls">
                                  <button onClick={() => skip(-1)} aria-label="Previous track"><Svg d="prev" /></button>
                                  <button onClick={() => setPlaying((p) => !p)} aria-label={playing ? "Pause" : "Play"}><Svg d={playing ? "pause" : "play"} s={22} /></button>
                                  <button onClick={() => skip(1)} aria-label="Next track"><Svg d="next" /></button>
                                </span>
                              </div>
                              <Eq on={playing} />
                            </div>
                          )}
                          {current === "shelf" && (
                            <div className="sim-shelf">
                              <div className="sim-files">
                                {shelf.map((f, i) => (
                                  <motion.span key={f + i} className="sim-file" initial={{ scale: 0.4, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}>
                                    <i>{f.split(".").pop()}</i>{f}
                                  </motion.span>
                                ))}
                              </div>
                              <button className="sim-clear" onClick={() => { setShelf([]); go("home"); }} aria-label="Clear the shelf">×</button>
                            </div>
                          )}
                        </motion.div>
                      </AnimatePresence>
                    </div>
                    <div className="sim-dots" role="tablist" aria-label="Island pages">
                      {pages.map((p) => (
                        <button key={p} role="tab" aria-selected={p === current} aria-label={p === "home" ? "Home" : p === "player" ? "Now playing" : "File shelf"} onClick={() => go(p)}>
                          <motion.i animate={{ width: p === current ? 18 : 6, backgroundColor: p === current ? theme.accent : "rgba(255,255,255,.28)" }} transition={spring} />
                        </button>
                      ))}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>

            <AnimatePresence>
              {!open && !banner && (
                <motion.span className="sim-hint" initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} transition={{ delay: 0.4 }}>
                  ↑ hover the notch
                </motion.span>
              )}
            </AnimatePresence>
          </div>

          <div className="sim-keys" role="group" aria-label="Keyboard">
            <button onClick={() => brightness(-1)} aria-label="Brightness down"><Svg d="sun" s={14} /><small>F1</small></button>
            <button onClick={() => brightness(1)} aria-label="Brightness up"><Svg d="sun" s={20} /><small>F2</small></button>
            <button onClick={() => skip(-1)} aria-label="Previous track"><Svg d="prev" s={16} /><small>F7</small></button>
            <button onClick={() => setPlaying((p) => !p)} aria-label="Play or pause"><Svg d={playing ? "pause" : "play"} s={16} /><small>F8</small></button>
            <button onClick={() => skip(1)} aria-label="Next track"><Svg d="next" s={16} /><small>F9</small></button>
            <button onClick={mute} aria-label="Mute" className={vol.muted ? "on" : ""}><Svg d="speaker" s={14} /><small>F10</small></button>
            <button onClick={() => volume(-1)} aria-label="Volume down"><Svg d="speaker" s={16} /><small>F11</small></button>
            <button onClick={() => volume(1)} aria-label="Volume up"><Svg d="speaker" s={20} /><small>F12</small></button>
            <span className="sim-sep" />
            <button className="wide" onClick={notify}>notchi notify</button>
            <button className="wide" onClick={drop}>Drop a file</button>
          </div>
          <p className="sim-help">Click the simulator, then use the arrow keys for volume and brightness, M to mute and space to play or pause. Swipe sideways with two fingers on the open island to change pages.</p>
        </div>
      </div>
    </section>
  );
}
