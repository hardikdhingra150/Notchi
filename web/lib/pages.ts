/** Every product page, in reading order. Drives the nav, landing cards and the prev/next pager. */
export const PAGES = [
  {
    href: "/notch", no: "01", title: "The Notch", short: "Notch",
    line: "The island over your notch: what's playing in any app, volume, brightness, battery, files and messages from your terminal.",
    card: "Live activities, pages you swipe through, and 15 components.",
    items: ["Any-app now playing", "Volume & brightness", "File shelf", "15 components"],
  },
  {
    href: "/themes", no: "02", title: "Themes", short: "Themes",
    line: "One small theme file recolours everything Notchi touches, with a sweep across the whole screen.",
    card: "Five built-in themes and a file format you can share.",
    items: ["Theme studio", "5 built-in themes", "JSON theme files"],
  },
  {
    href: "/wallpapers", no: "03", title: "Wallpapers", short: "Wallpapers",
    line: "Video, shader and particle wallpapers that pause the moment you can't see them.",
    card: "34 cinematic loops: sunsets, castles, black holes, neon cities.",
    items: ["34 wallpapers", "6 collections", "Free downloads", "Battery aware"],
  },
  {
    href: "/icons", no: "04", title: "Icons", short: "Icons",
    line: "Emoji and image badges for your folders, retinted to your theme, and always undoable.",
    card: "Folder badges, accent tints and one-click restore.",
    items: ["Folder badges", "Accent tint", "One-click restore"],
  },
  {
    href: "/cli", no: "05", title: "Terminal", short: "CLI",
    line: "Everything in the menu bar is a command too, so your scripts, builds and AI agents can talk to the notch.",
    card: "notchi notify, progress, themes and a doctor.",
    items: ["notchi notify", "progress", "apply", "doctor"],
  },
  {
    href: "/roadmap", no: "06", title: "Roadmap", short: "Roadmap",
    line: "What's shipped, what's next, and the rest of the suite that's on its way. Every phase ships free.",
    card: "The notch and themes are built. Sidebar, dock and plugins are next.",
    items: ["v0.5 themes built", "v1.0 sidebar next", "9 modules"],
  },
] as const;

export type PageInfo = (typeof PAGES)[number];
export type PageHref = PageInfo["href"];

export const pageFor = (href: PageHref) => PAGES.find((p) => p.href === href)!;

/** Pages outside the product tour: linked from the footer and the command palette. */
export const EXTRA_PAGES = [
  { href: "/changelog", title: "Changelog", card: "What changed in every version." },
  { href: "/faq", title: "FAQ", card: "Privacy, permissions and how it works." },
] as const;
