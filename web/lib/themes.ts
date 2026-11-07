export type ThemeId = "paper" | "midnight" | "matcha" | "sakura" | "neon";

export type ThemeMeta = {
  id: ThemeId;
  name: string;
  vibe: string;
  appearance: "light" | "dark";
  accent: string;
  swatches: string[];
  wallpaper: string;
  idle: string;
  dock: string;
  sounds: string;
  cursor: string;
};

export const THEMES: ThemeMeta[] = [
  { id: "paper", name: "Paper", vibe: "Ink on warm parchment", appearance: "light", accent: "#FF6A3D",
    swatches: ["#ebe5d4", "#16130e", "#ff6a3d", "#ffc64a"], wallpaper: "ink-tide.metal", idle: "breathing", dock: "floating-glass", sounds: "soft-pencil", cursor: "ring" },
  { id: "midnight", name: "Midnight", vibe: "Quiet, late, focused", appearance: "dark", accent: "#8F7CFF",
    swatches: ["#15161c", "#ebe5d4", "#8f7cff", "#5ce1c6"], wallpaper: "starfield.metal", idle: "sparks", dock: "minimal", sounds: "low-hum", cursor: "comet" },
  { id: "matcha", name: "Matcha", vibe: "Calm green mornings", appearance: "light", accent: "#4F9A3A",
    swatches: ["#e0e6d1", "#16200e", "#4f9a3a", "#e9c46a"], wallpaper: "leaf-drift.metal", idle: "breathing", dock: "centered-pill", sounds: "wood-tap", cursor: "leaf" },
  { id: "sakura", name: "Sakura", vibe: "Soft petals, warm light", appearance: "light", accent: "#E2507F",
    swatches: ["#f4e3de", "#2a1417", "#e2507f", "#f2a65a"], wallpaper: "petals.metal", idle: "pet", dock: "floating-glass", sounds: "chimes", cursor: "petal" },
  { id: "neon", name: "Neon Rain", vibe: "Cyberpunk after midnight", appearance: "dark", accent: "#FF3FD8",
    swatches: ["#0f0b1d", "#f1e9ff", "#ff3fd8", "#3ff0ff"], wallpaper: "rain.metal", idle: "rain", dock: "vertical", sounds: "soft-synth", cursor: "spark" },
];

export const THEME_KEY = "notchi-theme";
