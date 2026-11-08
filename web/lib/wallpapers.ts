/** The wallpaper library. Files live in /public/wallpapers, rendered from
 *  marketing/wallpapers/shaders.js: <id>.mp4 (1080p download), <id>-preview.mp4
 *  (small tile loop) and <id>.jpg (poster). Each is a seamless 6-second loop. */
export type Wallpaper = {
  id: string;
  name: string;
  kind: "Shader" | "Particles";
  theme: "Paper" | "Midnight" | "Matcha" | "Sakura" | "Neon Rain" | "Any";
  line: string;
};

export const WALLPAPERS: Wallpaper[] = [
  { id: "aurora", name: "Aurora", kind: "Shader", theme: "Midnight", line: "Northern lights rippling over a starry sky." },
  { id: "ink-tide", name: "Ink Tide", kind: "Shader", theme: "Paper", line: "Hand-inked hills rolling under a tomato sun." },
  { id: "synthwave", name: "Synthwave", kind: "Shader", theme: "Neon Rain", line: "A striped sun and a grid that never ends." },
  { id: "neon-rain", name: "Neon Rain", kind: "Particles", theme: "Neon Rain", line: "Pink and cyan streaks falling through the dark." },
  { id: "petals", name: "Petals", kind: "Particles", theme: "Sakura", line: "Cherry blossoms drifting and spinning down." },
  { id: "ocean", name: "Ocean Dusk", kind: "Shader", theme: "Paper", line: "Layered waves catching the last of the sun." },
  { id: "starfield", name: "Starfield", kind: "Shader", theme: "Midnight", line: "A slow flight through a violet galaxy." },
  { id: "leaf-drift", name: "Leaf Drift", kind: "Particles", theme: "Matcha", line: "Soft green bokeh floating in morning light." },
  { id: "lava", name: "Lava Lamp", kind: "Shader", theme: "Paper", line: "Warm blobs melting into each other." },
  { id: "fireflies", name: "Fireflies", kind: "Particles", theme: "Matcha", line: "Glowing lights blinking over a dark forest." },
  { id: "dunes", name: "Dunes", kind: "Shader", theme: "Paper", line: "Desert ridges with light sliding across the sand." },
  { id: "snowfall", name: "Snowfall", kind: "Particles", theme: "Midnight", line: "Quiet snow under a full moon." },
  { id: "liquid", name: "Liquid Glass", kind: "Shader", theme: "Any", line: "A mesh gradient that slowly breathes." },
  { id: "silk", name: "Silk", kind: "Shader", theme: "Any", line: "Coral, lavender and mint folding like fabric." },
];

export const WALLPAPER_THEME_COLORS: Record<Wallpaper["theme"], string> = {
  Paper: "#FF6A3D", Midnight: "#8F7CFF", Matcha: "#4F9A3A", Sakura: "#E2507F", "Neon Rain": "#FF3FD8", Any: "#5CE1C6",
};
