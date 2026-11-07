"use client";

import { AnimatePresence, motion, useMotionValueEvent, useScroll, useTransform } from "motion/react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { PAGES } from "@/lib/pages";
import { PALETTE_EVENT } from "./CommandPalette";
import { REPO_URL } from "@/lib/site";
import { heroPast, heroProgress } from "@/lib/store";
import { fmtStars, useStars } from "@/lib/useStars";
import { Github, LogoMark, Star } from "./icons";
import { scrollTo } from "./SmoothScroll";

const LINKS = PAGES.map((p) => ({ href: p.href, label: p.short }));

export function TopBar() {
  const { scrollY } = useScroll();
  const opacity = useTransform(scrollY, [0, 160], [1, 0]);
  const y = useTransform(scrollY, [0, 160], [0, -18]);
  const [off, setOff] = useState(false);
  useMotionValueEvent(scrollY, "change", (v) => setOff(v > 150));
  const stars = useStars();
  const pathname = usePathname();

  return (
    <motion.header className={`topbar${PAGES.some((p) => p.href === pathname) ? " on-dark" : ""}`} style={{ opacity, y, pointerEvents: off ? "none" : undefined }}>
      <Link href="/" className="logo" aria-label="Notchi home" onClick={() => pathname === "/" && scrollTo(0, 1.4)}>
        <LogoMark /> <span className="logo-word">Notchi</span>
      </Link>
      <nav className="toplinks" aria-label="Main">
        {LINKS.map((l) => {
          const on = pathname === l.href;
          return (
            <Link key={l.href} href={l.href} className={`lnk${on ? " on" : ""}`} aria-current={on ? "page" : undefined}>
              {on && <motion.i layoutId="nav-dot" className="lnk-dot" transition={{ type: "spring", stiffness: 420, damping: 30 }} />}
              {l.label}
            </Link>
          );
        })}
        <button className="cp-trigger" onClick={() => window.dispatchEvent(new Event(PALETTE_EVENT))} aria-label="Open the command palette">
          <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden><circle cx="11" cy="11" r="7" fill="none" stroke="currentColor" strokeWidth="2.6" /><path d="m20 20-4-4" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" /></svg>
          <kbd>⌘K</kbd>
        </button>
        <a className="pill sm" href={REPO_URL} target="_blank" rel="noreferrer">
          <Github /> {stars ? <>Star · {fmtStars(stars)}</> : "Star"}
        </a>
      </nav>
    </motion.header>
  );
}

const KONAMI = ["ArrowUp", "ArrowUp", "ArrowDown", "ArrowDown", "ArrowLeft", "ArrowRight", "ArrowLeft", "ArrowRight", "b", "a"];

/** The site's own notch: a pet that watches the cursor, shows where you are, and opens into the nav. */
export function SiteNotch() {
  const [open, setOpen] = useState(false);
  const [label, setLabel] = useState("Hello");
  const [hidden, setHidden] = useState(false);
  const [love, setLove] = useState(false);
  const [blink, setBlink] = useState(false);
  const [narrow, setNarrow] = useState(false);
  const pupils = useRef<HTMLElement[]>([]);
  const pathname = usePathname();
  const box = useRef<HTMLDivElement>(null);

  // hide while the hero's own (real) notch takes the top of the screen
  useEffect(() => {
    // only the landing page has the hero; elsewhere the site notch always shows
    if (pathname !== "/") { heroProgress.set(0); heroPast.set(1); }
    const upd = () => setHidden(pathname === "/" && heroProgress.get() > 0.16 && heroPast.get() < 1);
    upd();
    const a = heroProgress.on("change", upd);
    const b = heroPast.on("change", upd);
    return () => { a(); b(); };
  }, [pathname]);

  // which section are we in (re-scan on every page)
  useEffect(() => {
    const els = [...document.querySelectorAll<HTMLElement>("[data-notch]")];
    const first = els[0]?.getAttribute("data-notch");
    const t = window.setTimeout(() => first && setLabel(first), 0);
    const io = new IntersectionObserver(
      (es) => es.forEach((e) => e.isIntersecting && setLabel(e.target.getAttribute("data-notch") || "")),
      { rootMargin: "-45% 0px -50% 0px" },
    );
    els.forEach((el) => io.observe(el));
    return () => { io.disconnect(); window.clearTimeout(t); };
  }, [pathname]);

  // eyes follow the cursor, blink now and then
  useEffect(() => {
    const move = (e: PointerEvent) => {
      const r = box.current?.getBoundingClientRect();
      if (!r) return;
      const a = Math.atan2(e.clientY - (r.top + 20), e.clientX - (r.left + r.width / 2));
      const d = Math.min(Math.hypot(e.clientX - r.left, e.clientY - r.top) / 200, 1) * 2.4;
      pupils.current.forEach((p) => p && (p.style.transform = `translate(${Math.cos(a) * d}px,${Math.sin(a) * d}px)`));
    };
    addEventListener("pointermove", move, { passive: true });
    let t: ReturnType<typeof setTimeout>;
    const loop = () => {
      t = setTimeout(() => { setBlink(true); setTimeout(() => setBlink(false), 140); loop(); }, 2800 + Math.random() * 3200);
    };
    loop();
    const mq = matchMedia("(max-width: 760px)");
    const n = () => setNarrow(mq.matches);
    n(); mq.addEventListener("change", n);
    return () => { removeEventListener("pointermove", move); clearTimeout(t); mq.removeEventListener("change", n); };
  }, []);

  // ↑↑↓↓←→←→BA
  useEffect(() => {
    let i = 0;
    const key = (e: KeyboardEvent) => {
      i = e.key === KONAMI[i] ? i + 1 : e.key === KONAMI[0] ? 1 : 0;
      if (i === KONAMI.length) {
        i = 0; setLove(true);
        setTimeout(() => setLove(false), 4200);
      }
    };
    addEventListener("keydown", key);
    return () => removeEventListener("keydown", key);
  }, []);

  const w = open ? (narrow ? 300 : 430) : narrow ? 190 : 232;
  const h = open ? (narrow ? 152 : 108) : 40;

  return (
    <motion.div
      ref={box}
      className="sitenotch"
      role="navigation"
      aria-label="Notch menu"
      initial={false}
      animate={{ width: w, height: h, y: hidden ? -60 : 0, borderRadius: open ? "0 0 30px 30px" : "0 0 22px 22px" }}
      transition={{ type: "spring", stiffness: 380, damping: 30, mass: 0.8 }}
      onMouseEnter={() => setOpen(true)}
      onMouseLeave={() => setOpen(false)}
      onClick={() => setOpen((o) => !o)}
      data-hover
    >
      <div className="sn-row" style={{ height: 40 }}>
        <motion.div className="eyes" animate={love ? { y: [0, -4, 0, -4, 0] } : { y: 0 }} transition={{ duration: 0.9, repeat: love ? 3 : 0 }}>
          {[0, 1].map((i) =>
            love ? (
              <span key={i} style={{ color: "var(--accent)", fontSize: 13, lineHeight: "11px" }}>♥</span>
            ) : (
              <motion.span key={i} className="eye" animate={{ scaleY: blink ? 0.12 : 1 }} transition={{ duration: 0.07 }}>
                <i ref={(el) => { if (el) pupils.current[i] = el; }} />
              </motion.span>
            ),
          )}
        </motion.div>
        <AnimatePresence mode="popLayout" initial={false}>
          <motion.span
            key={love ? "love" : label}
            className="sn-label"
            initial={{ y: 16, opacity: 0, filter: "blur(4px)" }}
            animate={{ y: 0, opacity: 1, filter: "blur(0px)" }}
            exit={{ y: -16, opacity: 0, filter: "blur(4px)" }}
            transition={{ type: "spring", stiffness: 420, damping: 30 }}
          >
            {love ? "You found me" : label}
          </motion.span>
        </AnimatePresence>
        <span style={{ marginLeft: "auto", display: "flex", gap: 4, alignItems: "end", height: 14 }} aria-hidden>
          {[0, 1, 2].map((i) => (
            <motion.i
              key={i}
              style={{ width: 3, borderRadius: 2, background: "var(--accent)", display: "block" }}
              animate={{ height: [4, 13, 6, 11, 4] }}
              transition={{ duration: 1.1 + i * 0.2, repeat: Infinity, ease: "easeInOut", delay: i * 0.15 }}
            />
          ))}
        </span>
      </div>
      <AnimatePresence>
        {open && (
          <motion.nav
            className="sn-links"
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0, transition: { delay: 0.08 } }}
            exit={{ opacity: 0, y: -6, transition: { duration: 0.12 } }}
          >
            {LINKS.map((l) => (
              <Link key={l.href} href={l.href} className={pathname === l.href ? "on" : ""} onClick={(e) => { e.stopPropagation(); setOpen(false); }}>{l.label}</Link>
            ))}
            <a href={REPO_URL} target="_blank" rel="noreferrer" onClick={(e) => e.stopPropagation()} style={{ display: "inline-flex", gap: 6, alignItems: "center", color: "var(--accent)" }}>
              <Star width={13} height={13} /> Star
            </a>
          </motion.nav>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
