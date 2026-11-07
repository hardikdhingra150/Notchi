"use client";

import Link from "next/link";
import { useEffect, useRef } from "react";
import { REPO_URL } from "@/lib/site";
import { heroPast, heroProgress } from "@/lib/store";
import { Down, Github, LogoMark } from "./icons";
import { scrollTo } from "./SmoothScroll";

/* ───────── math ───────── */
const clamp = (v: number, a = 0, b = 1) => Math.min(b, Math.max(a, v));
const mix = (a: number, b: number, t: number) => a + (b - a) * t;
const seg = (p: number, a: number, b: number) => clamp((p - a) / (b - a));
const io = (k: number) => (k < 0.5 ? 4 * k ** 3 : 1 - (-2 * k + 2) ** 3 / 2);
const out = (k: number) => 1 - (1 - k) ** 3;
const back = (k: number) => 1 + 2.4 * (k - 1) ** 3 + 1.4 * (k - 1) ** 2;

/* ───────── geometry ─────────
   The scene is a fixed design box scaled to fit the frame ("contain").
   The rig (desk + MacBook) lives in landscape coords; the screen inside
   it is its own 1440×900 desktop. */
const SW = 1440, SH = 900;
const SCR = { x: 916, y: 250, w: 528, h: 330 };
const FOC = { x: SCR.x + SCR.w / 2, y: SCR.y + SCR.h / 2 };
const LID_BOTTOM = 598;

type Lay = { w: number; h: number; rig: { x: number; y: number; s: number }; sticker: { x: number; y: number } };
const LAY: Record<"land" | "port", Lay> = {
  land: { w: 1600, h: 900, rig: { x: FOC.x, y: FOC.y, s: 1 }, sticker: { x: 806, y: 150 } },
  port: { w: 800, h: 1500, rig: { x: 400, y: 1090, s: 1.28 }, sticker: { x: 560, y: 690 } },
};

/* ───────── wallpaper waves ("Ink Tide", the default live wallpaper) ───────── */
type Layer = { dy: number; a: number; k: number; v: number; ph: number; fill?: string; span?: [number, number] };
const WAVES: Layer[] = [
  { dy: -96, a: 16, k: 1.4, v: 0.8, ph: 0, fill: "var(--band)" },
  { dy: -50, a: 18, k: 1.8, v: 1.05, ph: 1.7, fill: "var(--paper2)" },
  // ↓ main swell, the boat rides this one
  { dy: 0, a: 21, k: 1.6, v: 1.2, ph: 3.1, fill: "var(--band)" },
  { dy: 26, a: 13, k: 2.3, v: 0.95, ph: 4.4, span: [0.06, 0.4] },
  { dy: 54, a: 18, k: 1.35, v: 1.3, ph: 0.6, fill: "var(--paper2)" },
  { dy: 84, a: 12, k: 2.1, v: 1.1, ph: 5.1, span: [0.55, 0.95] },
  { dy: 116, a: 20, k: 1.7, v: 1.2, ph: 2.2, fill: "var(--band)" },
  { dy: 146, a: 11, k: 2.6, v: 1, ph: 1.1, span: [0.08, 0.6] },
];
const MAIN = 2;

function yAt(l: Layer, x: number, t: number, base: number, r: number) {
  const a = l.a * mix(1, 0.8, r);
  const f = ((Math.PI * 2) / 1000) * l.k;
  return base + l.dy * mix(1, 0.78, r) + a * Math.sin(f * x + t * l.v + l.ph) + a * 0.45 * Math.sin(f * 2.3 * x - t * l.v * 0.7 + l.ph * 1.7);
}
function wavePath(l: Layer, t: number, base: number, r: number) {
  const x0 = l.span ? l.span[0] * SW : -24;
  const x1 = l.span ? l.span[1] * SW : SW + 24;
  let d = "";
  for (let x = x0; x < x1 + 24; x += 24) {
    const xx = Math.min(x, x1);
    d += `${d ? "L" : "M"}${xx.toFixed(1)} ${yAt(l, xx, t, base, r).toFixed(1)}`;
  }
  if (l.fill) d += `L${x1} ${SH + 60}L${x0} ${SH + 60}Z`;
  return d;
}

const CLOUD = "M0 60C8 42 30 36 44 46 50 22 86 12 104 34 116 22 142 26 148 46 164 43 178 52 180 60Z";

/* ───────── dock ───────── */
const DOCK = [
  { bg: "var(--accent3)", g: <path d="M8 15a4 4 0 0 1 4-4h6l3 3h11a4 4 0 0 1 4 4v12a4 4 0 0 1-4 4H12a4 4 0 0 1-4-4z" /> },
  { bg: "var(--paper)", g: <><circle cx="22" cy="22" r="13" /><path d="m27 17-3 8-7 2 3-8z" /></> },
  { bg: "var(--accent2)", g: <path d="M12 10h20v24H12zM16 17h12M16 22h12M16 27h7" /> },
  { bg: "var(--accent)", g: <><path d="M18 30V13l13-3v17" /><circle cx="15" cy="30" r="3.5" /><circle cx="28" cy="27" r="3.5" /></> },
  { bg: "var(--hw)", g: <path d="m12 16 6 6-6 6M21 29h11" stroke="#ebe5d4" /> },
  { bg: "var(--band)", g: <><rect x="9" y="11" width="26" height="22" rx="4" /><path d="m11 30 8-8 6 6 3-3 5 5" /><circle cx="28" cy="18" r="2.5" /></> },
  { bg: "var(--paper2)", g: <><circle cx="22" cy="22" r="5" /><path d="M22 8v5M22 31v5M8 22h5M31 22h5M12 12l3.5 3.5M28.5 28.5 32 32M12 32l3.5-3.5M28.5 15.5 32 12" /></> },
  { bg: "var(--accent)", g: <><rect x="8" y="12" width="28" height="20" rx="5" /><path d="M17 12v2a3 3 0 0 0 3 3h4a3 3 0 0 0 3-3v-2" fill="currentColor" /></> },
];
const FOLDERS = [
  { name: "Projects", badge: "🚀" },
  { name: "Design", badge: "🎨" },
  { name: "Screenshots", badge: "📸" },
];

export default function Hero() {
  const sec = useRef<HTMLElement>(null);

  useEffect(() => {
    const root = sec.current!;
    const $ = <T extends Element = HTMLElement>(s: string) => root.querySelector(s) as T;
    const $$ = <T extends Element = HTMLElement>(s: string) => [...root.querySelectorAll(s)] as T[];

    const stage = $(".stage"), scene = $(".scene"), rig = $(".rig"), lid = $(".lid");
    const t1 = $(".t1"), t2 = $(".t2"), hint = $(".hint"), sticker = $(".sticker");
    const steam = $$<SVGPathElement>(".steam");
    const waves = $$<SVGPathElement>(".wave");
    const boat = $<SVGGElement>(".boat"), sun = $<SVGCircleElement>(".sun");
    const clouds = $$<SVGGElement>(".cloud");
    const power = $(".power"), notch = $(".hw-notch"), island = $(".island");
    const bars = $$(".vis i"), scrub = $(".scrub i");
    const tint = $(".mb-tint"), dock = $(".dock"), icons = $$(".dk"), iconTint = $$(".dk-tint");
    const folders = $(".folders"), fTint = $$<SVGPathElement>(".f-tint"), badges = $$(".f-badge");
    const clock = $(".mb-clock");

    const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
    const t0 = performance.now();

    // layout state
    let L = LAY.land, S = 1, DW = 1600, DH = 900, DX = 0, DY = 0;
    let end = { x: 0, y: 0, z: 1 };

    const resize = () => {
      const W = stage.clientWidth, H = stage.clientHeight;
      const portrait = H > W * 1.05;
      root.classList.toggle("portrait", portrait);
      L = portrait ? LAY.port : LAY.land;
      S = Math.min(W / L.w, H / L.h);
      DW = W / S; DH = H / S; DX = (DW - L.w) / 2; DY = (DH - L.h) / 2;
      scene.style.width = `${L.w}px`;
      scene.style.height = `${L.h}px`;
      scene.style.transform = `translate(${DX * S}px,${DY * S}px) scale(${S})`;
      sticker.style.transform = `translate(${L.sticker.x}px,${L.sticker.y}px)`;

      // where the camera ends: landscape fills the frame with the screen (top anchored, so the notch shows);
      // portrait fits the screen to the width and leaves room for the copy below.
      const top = -DY + 6 / S;
      if (portrait) {
        const z = (DW * 1.02) / SCR.w;
        end = { z, x: L.w / 2, y: -DY + DH * 0.06 + (SCR.h / 2) * z };
      } else {
        const z = Math.max(DW / SCR.w, DH / SCR.h) * 1.003;
        end = { z, x: L.w / 2, y: top + (SCR.h / 2) * z };
      }
      // the part of the 1440×900 desktop that's visible at the end, so the dock and folders stay on screen
      const k = (end.z * SCR.w) / SW;
      const ox = end.x - (SCR.w / 2) * end.z, oy = end.y - (SCR.h / 2) * end.z;
      const vx1 = clamp((L.w + DX - ox) / k, 0, SW);
      const vy1 = clamp((L.h + DY - oy) / k, 0, SH);
      dock.style.top = `${vy1 - 128}px`;
      folders.style.left = `${vx1 - 170}px`;
    };
    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(stage);

    let lastClock = 0;
    const render = (now: number) => {
      const t = reduced ? 0 : (now - t0) / 1000;
      const box = root.getBoundingClientRect();
      const total = Math.max(root.offsetHeight - innerHeight, 1);
      const p = clamp(-box.top / total);
      heroProgress.set(p);
      heroPast.set(box.bottom < innerHeight * 0.55 ? 1 : 0);

      const intro = reduced ? 1 : out(seg(now, t0 + 150, t0 + 1100));
      const lidK = reduced ? 1 : back(seg(now, t0 + 80, t0 + 1050));
      const on = reduced ? 1 : seg(now, t0 + 900, t0 + 1500);

      /* camera */
      const e = io(seg(p, 0, 0.5));
      const z0 = L.rig.s, z = z0 * Math.pow(end.z / z0, e);
      const fx = mix(L.rig.x, end.x, e), fy = mix(L.rig.y, end.y, e);
      rig.style.transform = `translate(${fx - FOC.x * z}px,${fy - FOC.y * z}px) scale(${z})`;
      rig.style.setProperty("--sw", `${3.2 / z}px`);
      lid.style.transform = `scaleY(${Math.max(lidK, 0.001)})`;

      /* desk props */
      steam.forEach((s, i) => {
        const x = 752 + i * 19;
        let d = `M${x} 530`;
        for (let y = 524; y >= 468; y -= 8) d += `L${(x + Math.sin(y * 0.11 + t * 2.2 + i * 1.9) * 5).toFixed(1)} ${y}`;
        s.setAttribute("d", d);
        s.style.opacity = String((0.5 + 0.5 * Math.sin(t * 1.3 + i * 2)) * (1 - seg(p, 0.1, 0.3)));
      });

      /* copy */
      t1.style.opacity = String(intro * (1 - seg(p, 0.04, 0.2)));
      t1.style.transform = `translateY(${(1 - intro) * 30 - p * 120}px)`;
      t1.style.pointerEvents = p > 0.1 ? "none" : "";
      sticker.style.opacity = String(intro * (1 - seg(p, 0.05, 0.18)));
      hint.style.opacity = String(intro * (1 - seg(p, 0, 0.05)));
      const hk = seg(p, 0.7, 0.9);
      t2.style.opacity = String(hk);
      t2.style.transform = `translateY(${mix(50, 0, out(hk))}px) scale(${mix(0.96, 1, out(hk))})`;
      t2.style.pointerEvents = p > 0.85 ? "" : "none";

      /* screen: wallpaper */
      power.style.opacity = String(1 - on);
      const rise = io(seg(p, 0.12, 0.8));
      const base = mix(700, 560, rise);
      waves.forEach((w, i) => w.setAttribute("d", wavePath(WAVES[i], t, base, rise)));
      const bx = 1010 + Math.sin(t * 0.25) * 40;
      const by = yAt(WAVES[MAIN], bx, t, base, rise);
      const slope = (yAt(WAVES[MAIN], bx + 50, t, base, rise) - yAt(WAVES[MAIN], bx - 50, t, base, rise)) / 100;
      boat.setAttribute("transform", `translate(${bx.toFixed(1)} ${(by + 8).toFixed(1)}) rotate(${(Math.atan(slope) * 57.3 * 0.8).toFixed(2)})`);
      sun.setAttribute("cy", mix(330, 220, rise).toFixed(1));
      clouds.forEach((c, i) => {
        const x = (((SW * (0.25 + i * 0.5) - t * (12 + i * 6)) % (SW + 420)) + SW + 420) % (SW + 420) - 220;
        c.setAttribute("transform", `translate(${x.toFixed(1)} ${110 + i * 90}) scale(${1 - i * 0.3})`);
      });

      /* notch → island */
      const nk = seg(p, 0.3, 0.55);
      const nb = back(nk);
      notch.style.width = `${mix(196, 640, nb)}px`;
      notch.style.height = `${mix(38, 176, nb)}px`;
      notch.style.borderRadius = `0 0 ${mix(16, 48, nk)}px ${mix(16, 48, nk)}px`;
      const ik = seg(p, 0.46, 0.6);
      island.style.opacity = String(ik);
      island.style.transform = `translateY(${mix(-16, 0, out(ik))}px)`;
      if (ik > 0) {
        bars.forEach((b, i) => {
          const v = 0.25 + 0.75 * Math.abs(Math.sin(t * (2.1 + (i % 4) * 0.55) + i * 1.3) * Math.cos(t * 1.3 + i * 0.7));
          b.style.transform = `scaleY(${v.toFixed(3)})`;
        });
        scrub.style.transform = `scaleX(${(0.3 + ((t * 0.012) % 0.65)).toFixed(4)})`;
      }

      /* menu bar + icon retint */
      const ck = seg(p, 0.6, 0.82);
      tint.style.opacity = String(ck * 0.92);
      iconTint.forEach((el, i) => (el.style.opacity = String(seg(ck, i * 0.06, 0.5 + i * 0.06) * 0.55)));
      fTint.forEach((el, i) => (el.style.opacity = String(seg(ck, i * 0.15, 0.6 + i * 0.15))));
      badges.forEach((el, i) => {
        const k = seg(p, 0.7 + i * 0.04, 0.8 + i * 0.04);
        el.style.transform = `scale(${k > 0 ? back(k) : 0}) rotate(${mix(-30, -8, k)}deg)`;
      });

      /* dock */
      const dk = out(seg(p, 0.5, 0.72));
      dock.style.transform = `translateX(-50%) translateY(${mix(260, 0, dk)}px)`;
      if (dk > 0) {
        const mx = (Math.sin(t * 0.6) * 0.5 + 0.5) * 700;
        icons.forEach((ic, i) => {
          const c = 22 + 39 + i * 84;
          const s = 1 + 0.42 * Math.exp(-(((c - mx) / 90) ** 2));
          ic.style.transform = `translateY(${-(s - 1) * 34}px) scale(${s})`;
        });
      }

      if (now - lastClock > 1000 && clock) {
        lastClock = now;
        clock.textContent = new Date().toLocaleString("en-US", { weekday: "short", hour: "numeric", minute: "2-digit" });
      }
    };

    let raf = 0, running = false;
    const loop = (n: number) => { render(n); raf = requestAnimationFrame(loop); };
    const start = () => { if (!running) { running = true; raf = requestAnimationFrame(loop); } };
    const stop = () => { running = false; cancelAnimationFrame(raf); };
    // battery first: only animate while the hero is on screen
    const vis = new IntersectionObserver(([en]) => {
      if (en.isIntersecting) start();
      else { stop(); heroPast.set(en.boundingClientRect.top < 0 ? 1 : 0); heroProgress.set(en.boundingClientRect.top < 0 ? 1 : 0); }
    });
    vis.observe(root);
    render(performance.now());

    return () => { stop(); vis.disconnect(); ro.disconnect(); };
  }, []);

  const toEnd = (e: React.MouseEvent) => {
    e.preventDefault();
    const el = sec.current!;
    scrollTo(el.offsetTop + el.offsetHeight - innerHeight, 4.2);
  };

  return (
    <section className="hero" ref={sec} id="top" data-notch="Hello">
      <div className="hero-sticky">
        <div className="stage">
          <div className="scene">
            {/* ───── rig: desk + MacBook, the camera flies into it ───── */}
            <div className="rig">
              <svg className="ink-svg" viewBox="0 0 1600 900" width={1600} height={900} aria-hidden>
                <path d="M-3200 616H4800V3200H-3200Z" fill="var(--paper2)" stroke="none" />
                <path className="ink" d="M-3200 616H4800" />
                <path className="ink" d="M980 664H1380M240 712H640M1240 772H1720" />
                <ellipse cx="1180" cy="619" rx="370" ry="9" fill="var(--band)" />
                {/* base */}
                <path className="ink" fill="var(--band)" d="M846 597H1514Q1530 597 1526 605L1514 616H846L834 605Q830 597 846 597Z" />
                <path className="ink" d="M1128 597Q1180 609 1232 597" />
                {/* mug */}
                {[0, 1, 2].map((i) => <path key={i} className="ink steam" d="" />)}
                <path className="ink" fill="var(--accent)" d="M730 540H808V594Q808 616 786 616H752Q730 616 730 594Z" />
                <path className="ink" d="M808 556Q838 556 838 576Q838 596 808 596M730 558H808" />
                {/* plant */}
                <path className="ink" fill="var(--paper)" d="M1572 568Q1540 538 1546 500Q1574 520 1572 568ZM1576 568Q1584 520 1620 510Q1616 552 1576 568ZM1574 566Q1556 520 1584 474Q1602 520 1574 566Z" />
                <path className="ink" fill="var(--accent2)" d="M1540 566H1608L1598 616H1550Z" />
                <path className="ink" d="M1544 582H1604" />
              </svg>
              <div className="lid">
                <svg className="ink-svg" viewBox="0 0 1600 900" width={1600} height={900} aria-hidden>
                  <rect className="ink" x="900" y="234" width="560" height={LID_BOTTOM - 234} rx="20" fill="var(--hw)" />
                </svg>
                {/* ───── the screen: a 1440×900 desktop ───── */}
                <div className="screen" style={{ left: SCR.x, top: SCR.y, width: SCR.w, height: SCR.h }}>
                  <div className="desk" style={{ width: SW, height: SH, transform: `scale(${SCR.w / SW})` }}>
                    <svg className="wall" viewBox={`0 0 ${SW} ${SH}`} width={SW} height={SH} aria-hidden>
                      <rect width={SW} height={SH} fill="var(--sky)" />
                      <circle className="sun wl" cx="860" cy="330" r="74" fill="var(--accent2)" />
                      {[0, 1].map((i) => (
                        <g key={i} className="cloud"><path className="wl" d={CLOUD} fill="var(--paper)" /></g>
                      ))}
                      {WAVES.slice(0, MAIN).map((l, i) => <path key={i} className="wave wl" fill={l.fill || "none"} />)}
                      <g className="boat">
                        <path className="wl" fill="var(--paper2)" d="M-14-22V-62L-50-24Z" />
                        <path className="wl" fill="var(--accent)" d="M-6-22V-80L44-24Z" />
                        <path className="wl" fill="var(--paper)" d="M-66-22H66L44 2H-44Z" />
                      </g>
                      {WAVES.slice(MAIN).map((l, i) => <path key={i + MAIN} className="wave wl" fill={l.fill || "none"} />)}
                    </svg>

                    {/* menu bar */}
                    <div className="mbar">
                      <i className="mb-tint" />
                      <div className="mb-l"><LogoMark width={22} height={16} /><b>Notchi</b><span>File</span><span>Edit</span><span>View</span><span>Window</span></div>
                      <div className="mb-r">
                        <svg width="22" height="16" viewBox="0 0 22 16" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round"><path d="M2 6a13 13 0 0 1 18 0M5.5 9.5a8 8 0 0 1 11 0M9 13a3 3 0 0 1 4 0" /></svg>
                        <svg width="30" height="15" viewBox="0 0 30 15" fill="none" stroke="currentColor" strokeWidth="2"><rect x="1" y="1" width="24" height="13" rx="4" /><rect x="4" y="4" width="15" height="7" rx="1.5" fill="currentColor" stroke="none" /><path d="M28 5.5v4" strokeLinecap="round" /></svg>
                        <span className="mb-clock" />
                      </div>
                    </div>

                    {/* the notch, growing into a live activity */}
                    <div className="hw-notch">
                      <div className="island">
                        <div className="art"><i /></div>
                        <div className="meta">
                          <b>Night Drive</b>
                          <span>Notchi Radio · Ink Tide</span>
                          <div className="scrub"><i /></div>
                          <div className="times"><span>1:24</span><span>3:05</span></div>
                        </div>
                        <div className="vis">{Array.from({ length: 9 }, (_, i) => <i key={i} />)}</div>
                      </div>
                    </div>

                    {/* desktop folders with icon-studio badges */}
                    <div className="folders">
                      {FOLDERS.map((f) => (
                        <div className="folder" key={f.name}>
                          <svg viewBox="0 0 100 80" width="100" height="80" aria-hidden>
                            <path d="M6 18a8 8 0 0 1 8-8h22l8 8h42a8 8 0 0 1 8 8v40a8 8 0 0 1-8 8H14a8 8 0 0 1-8-8z" fill="var(--accent3)" stroke="var(--line)" strokeWidth="3.5" strokeLinejoin="round" />
                            <path className="f-tint" d="M6 18a8 8 0 0 1 8-8h22l8 8h42a8 8 0 0 1 8 8v40a8 8 0 0 1-8 8H14a8 8 0 0 1-8-8z" fill="var(--accent)" stroke="var(--line)" strokeWidth="3.5" strokeLinejoin="round" opacity="0" />
                            <path d="M6 30h88" stroke="var(--line)" strokeWidth="3.5" />
                          </svg>
                          <span className="f-badge">{f.badge}</span>
                          <span className="f-name">{f.name}</span>
                        </div>
                      ))}
                    </div>

                    {/* dock */}
                    <div className="dock">
                      {DOCK.map((d, i) => (
                        <div className="dk" key={i} style={{ background: d.bg }}>
                          <i className="dk-tint" />
                          <svg viewBox="0 0 44 44" width="44" height="44" fill="none" stroke="var(--line)" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden>{d.g}</svg>
                        </div>
                      ))}
                    </div>

                    <div className="power" />
                  </div>
                </div>
              </div>
            </div>

            {/* ───── opening copy ───── */}
            <div className="t1">
              <span className="eyebrow">Free &amp; open source · macOS 14+</span>
              <h1 className="display">Your notch<br />comes alive</h1>
              <p className="small-caps">One free app themes your whole Mac.<br />Notch, wallpaper, dock, icons and sounds.</p>
              <div className="t1-cta">
                <a href="#explore" className="pill hot" onClick={toEnd}>Open it up <Down /></a>
                <a href={REPO_URL} className="pill" target="_blank" rel="noreferrer"><Github /> Star on GitHub</a>
              </div>
            </div>

            <div className="sticker" aria-hidden>
              <svg viewBox="0 0 160 160" width="160" height="160">
                <defs><path id="ring" d="M80 80m-56 0a56 56 0 1 1 112 0a56 56 0 1 1-112 0" /></defs>
                <circle cx="80" cy="80" r="76" fill="var(--accent2)" stroke="var(--line)" strokeWidth="3.5" />
                <circle cx="80" cy="80" r="36" fill="var(--paper)" stroke="var(--line)" strokeWidth="3" />
                <g className="spin">
                  <text fontFamily="var(--f-ui)" fontWeight="700" fontSize="14.5" letterSpacing="3.2" fill="var(--line)">
                    <textPath href="#ring">FREE FOREVER ✦ OPEN SOURCE ✦ $0 ✦ NO TRACKING ✦</textPath>
                  </text>
                </g>
                <g transform="translate(62 68)" color="var(--line)"><LogoMark width={36} height={26} /></g>
              </svg>
            </div>
          </div>

          {/* ───── second beat, over the zoomed screen ───── */}
          <div className="t2">
            <span className="eyebrow">One theme</span>
            <h2 className="display">Everything<br />follows along</h2>
            <p>Pick a theme and the notch wakes up, the wallpaper starts moving, icons retint and the dock turns to glass. All at once, in one click.</p>
            <Link href="/themes" className="pill hot sm">Try a theme</Link>
          </div>

          <div className="hint" aria-hidden>
            <span className="mouse"><i /></span>
            <span className="small-caps">Scroll to open</span>
          </div>
        </div>
      </div>
    </section>
  );
}
