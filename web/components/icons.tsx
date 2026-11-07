import type { SVGProps } from "react";

type P = SVGProps<SVGSVGElement>;
const base = { fill: "none", stroke: "currentColor", strokeWidth: 2.4, strokeLinecap: "round", strokeLinejoin: "round" } as const;

/** Notchi mark: a screen with a notch bite. */
export const LogoMark = (p: P) => (
  <svg viewBox="0 0 30 22" {...base} strokeWidth={2.6} {...p}>
    <rect x="1.5" y="1.5" width="27" height="19" rx="5" />
    <path d="M10.5 1.5v1.8a3 3 0 0 0 3 3h3a3 3 0 0 0 3-3V1.5" fill="currentColor" />
  </svg>
);

export const Star = (p: P) => (
  <svg viewBox="0 0 24 24" {...base} {...p}>
    <path d="m12 2.8 2.8 5.8 6.3.9-4.6 4.4 1.1 6.3L12 17.2l-5.6 3 1.1-6.3-4.6-4.4 6.3-.9z" />
  </svg>
);

export const Github = (p: P) => (
  <svg viewBox="0 0 24 24" fill="currentColor" {...p}>
    <path d="M12 1.6a10.4 10.4 0 0 0-3.3 20.3c.5.1.7-.2.7-.5v-1.8c-2.9.6-3.5-1.4-3.5-1.4-.5-1.2-1.2-1.5-1.2-1.5-.9-.7.1-.6.1-.6 1 .1 1.6 1.1 1.6 1.1.9 1.6 2.5 1.2 3.1.9.1-.7.4-1.2.7-1.4-2.3-.3-4.8-1.2-4.8-5.2 0-1.1.4-2.1 1.1-2.8-.1-.3-.5-1.4.1-2.8 0 0 .9-.3 2.9 1.1a10 10 0 0 1 5.2 0c2-1.4 2.9-1.1 2.9-1.1.6 1.4.2 2.5.1 2.8.7.7 1.1 1.7 1.1 2.8 0 4-2.5 4.9-4.8 5.2.4.3.7 1 .7 1.9v2.8c0 .3.2.6.7.5A10.4 10.4 0 0 0 12 1.6z" />
  </svg>
);

export const Arrow = (p: P) => (
  <svg viewBox="0 0 24 24" {...base} {...p}>
    <path d="M5 12h14M13 6l6 6-6 6" />
  </svg>
);

export const Down = (p: P) => (
  <svg viewBox="0 0 24 24" {...base} {...p}>
    <path d="M12 5v14M6 13l6 6 6-6" />
  </svg>
);

export const Copy = (p: P) => (
  <svg viewBox="0 0 24 24" {...base} {...p}>
    <rect x="8" y="8" width="12" height="12" rx="3" />
    <path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2" />
  </svg>
);

export const Check = (p: P) => (
  <svg viewBox="0 0 24 24" {...base} {...p}>
    <path d="m5 12.5 4.5 4.5L19 7.5" />
  </svg>
);

/* Module icons (32×32) */
const m = (d: React.ReactNode) => {
  const Icon = (p: P) => (
    <svg viewBox="0 0 32 32" {...base} {...p}>
      {d}
    </svg>
  );
  return Icon;
};

export const ModIcons = {
  notch: m(<><rect x="3" y="6" width="26" height="20" rx="5" /><path d="M11 6v1.5a3 3 0 0 0 3 3h4a3 3 0 0 0 3-3V6" /><path d="M10 19h12" /></>),
  wallpaper: m(<><rect x="3" y="5" width="26" height="22" rx="5" /><path d="M3 20c4-3 7-3 10 0s7 3 10 0 5-2 6-1" /><circle cx="21" cy="12" r="3" /></>),
  icons: m(<><path d="M4 10a3 3 0 0 1 3-3h6l3 3h9a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3z" /><path d="m14 18 2-4 2 4-2 2z" /></>),
  sidebar: m(<><rect x="3" y="4" width="26" height="24" rx="5" /><path d="M19 4v24M22 10h4M22 15h4M22 20h4" /></>),
  dock: m(<><rect x="5" y="20" width="22" height="7" rx="3.5" /><path d="M10 23.5h.01M16 23.5h.01M22 23.5h.01" strokeWidth={3.4} /><path d="M9 14l7-7 7 7" /></>),
  menubar: m(<><rect x="3" y="5" width="26" height="22" rx="5" /><path d="M3 11h26M7 8h.01M20 8h6" /></>),
  effects: m(<><path d="M8 24 24 8M19 6l1-3 1 3 3 1-3 1-1 3-1-3-3-1zM7 9l.6-2 .6 2 2 .6-2 .6-.6 2-.6-2-2-.6z" /><circle cx="22" cy="23" r="3" /></>),
  widgets: m(<><rect x="4" y="4" width="11" height="11" rx="3" /><rect x="17" y="4" width="11" height="11" rx="3" /><rect x="4" y="17" width="24" height="11" rx="3" /></>),
  ai: m(<><path d="M16 4c1.2 5.2 3.8 7.8 9 9-5.2 1.2-7.8 3.8-9 9-1.2-5.2-3.8-7.8-9-9 5.2-1.2 7.8-3.8 9-9z" /><path d="M25 21c.5 2 1.5 3 3.5 3.5-2 .5-3 1.5-3.5 3.5-.5-2-1.5-3-3.5-3.5 2-.5 3-1.5 3.5-3.5z" /></>),
  profiles: m(<><circle cx="12" cy="11" r="4.5" /><path d="M3.5 26c.8-4.5 4-7 8.5-7s7.7 2.5 8.5 7" /><path d="M21 6.5a4.5 4.5 0 0 1 0 9M24 19.5c2.4 1 4 3.2 4.5 6.5" /></>),
};
