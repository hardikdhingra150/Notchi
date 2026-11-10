"use client";

import { AnimatePresence, motion } from "motion/react";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState } from "react";
import { applyTheme } from "@/lib/applyTheme";
import { EXTRA_PAGES, PAGES } from "@/lib/pages";
import { APP_VERSION, DOWNLOAD_URL, REPO_URL, RELEASES_URL } from "@/lib/site";
import { THEMES } from "@/lib/themes";
import { setScrollLocked } from "./SmoothScroll";

export const PALETTE_EVENT = "notchi:palette";

type Item = { id: string; group: string; label: string; hint?: string; keys?: string; run: () => void; swatch?: string };

/** Fuzzy match: every typed character appears in order. Lower score is better. */
function score(text: string, q: string) {
  if (!q) return 0;
  const t = text.toLowerCase();
  const direct = t.indexOf(q);
  if (direct >= 0) return direct;
  let i = 0, gaps = 0;
  for (const c of q) {
    const j = t.indexOf(c, i);
    if (j < 0) return -1;
    gaps += j - i;
    i = j + 1;
  }
  return 100 + gaps;
}

export default function CommandPalette() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  const [sel, setSel] = useState(0);
  const [toast, setToast] = useState<string | null>(null);
  const input = useRef<HTMLInputElement>(null);
  const list = useRef<HTMLUListElement>(null);

  const show = () => { setQ(""); setSel(0); setOpen(true); };
  const close = () => setOpen(false);

  useEffect(() => {
    const key = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        if (open) close(); else show();
      }
    };
    const evt = () => show();
    addEventListener("keydown", key);
    addEventListener(PALETTE_EVENT, evt);
    return () => { removeEventListener("keydown", key); removeEventListener(PALETTE_EVENT, evt); };
  }, [open]);

  useEffect(() => {
    setScrollLocked(open);
    if (open) requestAnimationFrame(() => input.current?.focus());
  }, [open]);

  const flash = (msg: string) => { setToast(msg); setTimeout(() => setToast(null), 1800); };

  const items = useMemo<Item[]>(() => [
    { id: "home", group: "Go to", label: "Home", hint: "Overview, install and why", run: () => router.push("/") },
    ...PAGES.map((p) => ({ id: p.href, group: "Go to", label: p.title, hint: p.card, keys: p.no, run: () => router.push(p.href) })),
    ...EXTRA_PAGES.map((p) => ({ id: p.href, group: "Go to", label: p.title, hint: p.card, run: () => router.push(p.href) })),
    ...THEMES.map((t) => ({ id: `theme-${t.id}`, group: "Apply theme", label: t.name, hint: t.vibe, swatch: t.accent, run: () => applyTheme(t.id) })),
    { id: "download", group: "Actions", label: "Download Notchi", hint: `v${APP_VERSION} for macOS 14 or later`, run: () => { location.href = DOWNLOAD_URL; flash("Downloading Notchi"); } },
    { id: "star", group: "Actions", label: "Star Notchi on GitHub", hint: "github.com/hardikdhingra150/Notchi", run: () => open_(REPO_URL) },
    { id: "releases", group: "Actions", label: "See all releases", hint: "GitHub Releases", run: () => open_(RELEASES_URL) },
    { id: "issue", group: "Actions", label: "Report a bug or request a feature", hint: "GitHub Issues", run: () => open_(`${REPO_URL}/issues/new/choose`) },
  ], [router]);

  const query = q.trim().toLowerCase();
  const results = items
    .map((it) => ({ it, s: Math.min(...[it.label, `${it.group} ${it.label}`, it.hint ?? ""].map((t) => score(t, query)).map((s) => (s < 0 ? Infinity : s))) }))
    .filter((r) => r.s !== Infinity)
    .sort((a, b) => (query ? a.s - b.s : 0))
    .map((r) => r.it);
  const active = Math.min(sel, Math.max(results.length - 1, 0));

  const run = (it: Item) => { close(); it.run(); };

  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowDown") { e.preventDefault(); setSel((s) => Math.min(s + 1, results.length - 1)); }
    else if (e.key === "ArrowUp") { e.preventDefault(); setSel((s) => Math.max(s - 1, 0)); }
    else if (e.key === "Enter" && results[active]) { e.preventDefault(); run(results[active]); }
    else if (e.key === "Escape") { e.preventDefault(); close(); }
  };

  useEffect(() => {
    list.current?.querySelector<HTMLElement>(`[data-i="${active}"]`)?.scrollIntoView({ block: "nearest" });
  }, [active]);

  return (
    <>
      <AnimatePresence>
        {open && (
          <motion.div className="cp-backdrop" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onMouseDown={close}>
            <motion.div
              className="cp"
              role="dialog"
              aria-modal="true"
              aria-label="Command palette"
              initial={{ y: -30, scale: 0.96, opacity: 0 }}
              animate={{ y: 0, scale: 1, opacity: 1 }}
              exit={{ y: -16, scale: 0.98, opacity: 0 }}
              transition={{ type: "spring", stiffness: 420, damping: 32 }}
              onMouseDown={(e) => e.stopPropagation()}
            >
              <div className="cp-top">
                <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden><circle cx="11" cy="11" r="7" fill="none" stroke="currentColor" strokeWidth="2.4" /><path d="m20 20-4-4" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" /></svg>
                <input
                  ref={input}
                  value={q}
                  onChange={(e) => { setQ(e.target.value); setSel(0); }}
                  onKeyDown={onKey}
                  placeholder="Jump to a page, apply a theme, copy the install command…"
                  aria-label="Search"
                  aria-controls="cp-list"
                  aria-activedescendant={results[active] ? `cp-${results[active].id}` : undefined}
                />
                <kbd>esc</kbd>
              </div>
              <ul className="cp-list" id="cp-list" role="listbox" ref={list}>
                {results.length === 0 && <li className="cp-empty">Nothing matches “{q}”.</li>}
                {results.map((it, i) => {
                  const head = !query && (i === 0 || results[i - 1].group !== it.group);
                  return (
                    <li key={it.id} role="presentation">
                      {head && <span className="cp-group">{it.group}</span>}
                      <button
                        id={`cp-${it.id}`}
                        role="option"
                        aria-selected={i === active}
                        data-i={i}
                        className={i === active ? "on" : ""}
                        onMouseMove={() => setSel(i)}
                        onClick={() => run(it)}
                      >
                        {it.swatch ? <i className="cp-sw" style={{ background: it.swatch }} /> : <i className="cp-dot" />}
                        <b>{it.label}</b>
                        {it.hint && <span>{it.hint}</span>}
                        {query && <em>{it.group}</em>}
                        {it.keys && !query && <em>{it.keys}</em>}
                      </button>
                    </li>
                  );
                })}
              </ul>
              <div className="cp-foot"><span><kbd>↑</kbd><kbd>↓</kbd> move</span><span><kbd>↵</kbd> open</span><span><kbd>⌘</kbd><kbd>K</kbd> toggle</span></div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
      <AnimatePresence>
        {toast && (
          <motion.div className="cp-toast" role="status" initial={{ y: 30, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: 20, opacity: 0 }}>
            {toast}
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}

function open_(url: string) {
  window.open(url, "_blank", "noopener,noreferrer");
}
