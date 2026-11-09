/** The wallpaper library. Files live in /public/wallpapers, rendered from
 *  marketing/wallpapers/shaders.js: <id>.mp4 (1080p download), <id>-preview.mp4
 *  (small tile loop) and <id>.jpg (poster). Each is a seamless 6 or 12-second loop. */
export type CollectionId = "golden-hour" | "spellbound" | "deep-space" | "neon-city" | "cozy-nights" | "minimal";

export type Wallpaper = {
  id: string;
  name: string;
  collection: CollectionId;
  kind: "Shader" | "Particles";
  theme: "Paper" | "Midnight" | "Matcha" | "Sakura" | "Neon Rain" | "Any";
  line: string;
};

export const WALLPAPERS: Wallpaper[] = [
  { id: "savanna", collection: "golden-hour", name: "Savanna Sunset", kind: "Shader", theme: "Paper", line: "Acacias and a giraffe against a low sun, grass moving in the warm wind." },
  { id: "palm-beach", collection: "golden-hour", name: "Palm Beach", kind: "Shader", theme: "Neon Rain", line: "Palms over a glittering sea at sunset, waves washing up the sand." },
  { id: "lavender-fields", collection: "golden-hour", name: "Lavender Fields", kind: "Shader", theme: "Sakura", line: "Rows of lavender running toward a lone tree and a setting sun." },
  { id: "desert-mesa", collection: "golden-hour", name: "Desert Mesa", kind: "Shader", theme: "Paper", line: "Buttes and saguaros just after sunset, the first stars over the dunes." },
  { id: "golden-hills", collection: "golden-hour", name: "Golden Hills", kind: "Shader", theme: "Paper", line: "Rolling hills, cypress lanes and a farmhouse in late golden light." },
  { id: "autumn-lake", collection: "golden-hour", name: "Autumn Lake", kind: "Shader", theme: "Paper", line: "A red and gold forest around a mirror lake, leaves drifting down." },
  { id: "misty-pines", collection: "golden-hour", name: "Misty Pines", kind: "Shader", theme: "Midnight", line: "Ridge after ridge of pines in morning mist, mirrored in a still lake." },
  { id: "cloud-sea", collection: "golden-hour", name: "Above the Clouds", kind: "Shader", theme: "Midnight", line: "Snowy peaks rising out of a sea of clouds as the sun comes up." },
  { id: "floating-candles", collection: "spellbound", name: "Floating Candles", kind: "Shader", theme: "Midnight", line: "Hundreds of candles drifting under an enchanted night ceiling." },
  { id: "moonlit-castle", collection: "spellbound", name: "Moonlit Castle", kind: "Shader", theme: "Midnight", line: "Towers on a cliff, lit windows and a full moon over the lake." },
  { id: "spell-trails", collection: "spellbound", name: "Spell Trails", kind: "Particles", theme: "Midnight", line: "Ribbons of light spiralling through the dark like a duel of spells." },
  { id: "black-hole", collection: "deep-space", name: "Black Hole", kind: "Shader", theme: "Midnight", line: "A glowing disc of fire bending around a black hole." },
  { id: "nebula", collection: "deep-space", name: "Nebula", kind: "Shader", theme: "Neon Rain", line: "Clouds of pink and teal gas lit by newborn stars." },
  { id: "ringed-planet", collection: "deep-space", name: "Ringed Planet", kind: "Shader", theme: "Paper", line: "A giant ringed world with its moon, slowly turning." },
  { id: "cyber-city", collection: "neon-city", name: "Cyberpunk Skyline", kind: "Shader", theme: "Neon Rain", line: "Rain, neon signs and flying cars over a city that never sleeps." },
  { id: "code-rain", collection: "neon-city", name: "Code Rain", kind: "Particles", theme: "Matcha", line: "Columns of glowing glyphs pouring down the screen." },
  { id: "rainy-window", collection: "cozy-nights", name: "Rainy Window", kind: "Particles", theme: "Midnight", line: "Raindrops sliding down the glass, city lights blurred behind." },
  { id: "sky-lanterns", collection: "cozy-nights", name: "Sky Lanterns", kind: "Particles", theme: "Paper", line: "Paper lanterns rising slowly from a lake at dusk." },
  { id: "koi-pond", collection: "cozy-nights", name: "Koi Pond", kind: "Particles", theme: "Matcha", line: "Koi circling under lily pads, light dancing on the water." },
  { id: "aurora-peaks", collection: "cozy-nights", name: "Aurora Peaks", kind: "Shader", theme: "Midnight", line: "Northern lights over snowy mountains and a mirror lake." },
  { id: "aurora", collection: "minimal", name: "Aurora", kind: "Shader", theme: "Midnight", line: "Northern lights rippling over a starry sky." },
  { id: "ink-tide", collection: "minimal", name: "Ink Tide", kind: "Shader", theme: "Paper", line: "Hand-inked hills rolling under a tomato sun." },
  { id: "synthwave", collection: "minimal", name: "Synthwave", kind: "Shader", theme: "Neon Rain", line: "A striped sun and a grid that never ends." },
  { id: "neon-rain", collection: "minimal", name: "Neon Rain", kind: "Particles", theme: "Neon Rain", line: "Pink and cyan streaks falling through the dark." },
  { id: "petals", collection: "minimal", name: "Petals", kind: "Particles", theme: "Sakura", line: "Cherry blossoms drifting and spinning down." },
  { id: "ocean", collection: "minimal", name: "Ocean Dusk", kind: "Shader", theme: "Paper", line: "Layered waves catching the last of the sun." },
  { id: "starfield", collection: "minimal", name: "Starfield", kind: "Shader", theme: "Midnight", line: "A slow flight through a violet galaxy." },
  { id: "leaf-drift", collection: "minimal", name: "Leaf Drift", kind: "Particles", theme: "Matcha", line: "Soft green bokeh floating in morning light." },
  { id: "lava", collection: "minimal", name: "Lava Lamp", kind: "Shader", theme: "Paper", line: "Warm blobs melting into each other." },
  { id: "fireflies", collection: "minimal", name: "Fireflies", kind: "Particles", theme: "Matcha", line: "Glowing lights blinking over a dark forest." },
  { id: "dunes", collection: "minimal", name: "Dunes", kind: "Shader", theme: "Paper", line: "Desert ridges with light sliding across the sand." },
  { id: "snowfall", collection: "minimal", name: "Snowfall", kind: "Particles", theme: "Midnight", line: "Quiet snow under a full moon." },
  { id: "liquid", collection: "minimal", name: "Liquid Glass", kind: "Shader", theme: "Any", line: "A mesh gradient that slowly breathes." },
  { id: "silk", collection: "minimal", name: "Silk", kind: "Shader", theme: "Any", line: "Coral, lavender and mint folding like fabric." },
];

export const WALLPAPER_THEME_COLORS: Record<Wallpaper["theme"], string> = {
  Paper: "#FF6A3D", Midnight: "#8F7CFF", Matcha: "#4F9A3A", Sakura: "#E2507F", "Neon Rain": "#FF3FD8", Any: "#5CE1C6",
};

export type Collection = { id: CollectionId; name: string; tagline: string; hero: string; emoji: string; note?: string };

/** Shown in this order, each with its own themed banner. */
export const COLLECTIONS: Collection[] = [
  { id: "golden-hour", name: "Golden Hour", emoji: "🌅", hero: "savanna", note: "Made to sit behind your icons", tagline: "Painted landscapes at sunrise and sunset. Calm sky where your icons sit, the detail low on the horizon." },
  { id: "spellbound", name: "Spellbound", emoji: "✨", hero: "floating-candles", tagline: "Magic-school nights: floating candles, a castle on the lake and spells in the dark." },
  { id: "deep-space", name: "Deep Space", emoji: "🪐", hero: "black-hole", tagline: "A black hole, a nebula and a ringed giant, slowly turning on your desktop." },
  { id: "neon-city", name: "Neon City", emoji: "🌃", hero: "cyber-city", tagline: "Rain-soaked neon and falling code for late-night work." },
  { id: "cozy-nights", name: "Cozy Nights", emoji: "🕯️", hero: "sky-lanterns", tagline: "Rain on the window, lanterns on the lake, koi under the lily pads." },
  { id: "minimal", name: "Minimal", emoji: "◐", hero: "liquid", tagline: "Calm gradients, gentle particles and soft landscapes that stay out of the way." },
];
