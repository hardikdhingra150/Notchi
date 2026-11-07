import { THEME_KEY, type ThemeId } from "./themes";

type VTDoc = Document & {
  startViewTransition?: (cb: () => void) => { ready: Promise<void> };
};

export const THEME_EVENT = "notchi:theme";

export function currentTheme(): ThemeId {
  return (document.documentElement.dataset.theme as ThemeId) || "paper";
}

/** Apply a theme to the whole page with a circular "wave" sweep from (x, y). */
export function applyTheme(id: ThemeId, x = innerWidth / 2, y = innerHeight / 2) {
  const root = document.documentElement;
  if (root.dataset.theme === id) return;
  const set = () => {
    root.dataset.theme = id;
    try { localStorage.setItem(THEME_KEY, id); } catch {}
    window.dispatchEvent(new CustomEvent(THEME_EVENT, { detail: id }));
  };
  const doc = document as VTDoc;
  const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (!doc.startViewTransition || reduced) return set();
  const r = Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y));
  const vt = doc.startViewTransition(set);
  vt.ready.then(() => {
    root.animate(
      { clipPath: [`circle(0px at ${x}px ${y}px)`, `circle(${r}px at ${x}px ${y}px)`] },
      { duration: 1000, easing: "cubic-bezier(.7,0,.2,1)", pseudoElement: "::view-transition-new(root)" },
    );
  }).catch(() => {});
}
