/** Community themes. Each is a real theme file at /public/themes/<id>.json in the
 *  exact format the app loads, paired with a wallpaper from the library. */
export type CommunityTheme = {
  id: string; name: string; vibe: string; appearance: "light" | "dark"; accent: string;
  swatches: [string, string, string, string]; wallpaper: string; idle: string; dock: string; sounds: string; cursor: string;
};

export const COMMUNITY_THEMES: CommunityTheme[] = [
  {
    "id": "ocean-drive",
    "name": "Ocean Drive",
    "vibe": "Night swim, city lights",
    "appearance": "dark",
    "accent": "#3FA9F5",
    "swatches": [
      "#0c1622",
      "#e6f1fa",
      "#3FA9F5",
      "#5ce1c6"
    ],
    "wallpaper": "ocean",
    "idle": "breathing",
    "dock": "floating-glass",
    "sounds": "soft-synth",
    "cursor": "comet"
  },
  {
    "id": "dune",
    "name": "Dune",
    "vibe": "Warm sand, slow afternoons",
    "appearance": "light",
    "accent": "#E07A3F",
    "swatches": [
      "#f3e3cf",
      "#2a1a10",
      "#E07A3F",
      "#f2b45a"
    ],
    "wallpaper": "dunes",
    "idle": "breathing",
    "dock": "centered-pill",
    "sounds": "wood-tap",
    "cursor": "ring"
  },
  {
    "id": "mono",
    "name": "Mono",
    "vibe": "Black ink, nothing else",
    "appearance": "light",
    "accent": "#1F1F1F",
    "swatches": [
      "#f4f4f1",
      "#111111",
      "#1F1F1F",
      "#9a9a9a"
    ],
    "wallpaper": "ink-tide",
    "idle": "breathing",
    "dock": "minimal",
    "sounds": "soft-pencil",
    "cursor": "ring"
  },
  {
    "id": "terminal",
    "name": "Terminal",
    "vibe": "Green on black, always",
    "appearance": "dark",
    "accent": "#39FF14",
    "swatches": [
      "#050806",
      "#c9ffc0",
      "#39FF14",
      "#14b8a6"
    ],
    "wallpaper": "neon-rain",
    "idle": "rain",
    "dock": "vertical",
    "sounds": "low-hum",
    "cursor": "spark"
  },
  {
    "id": "synthwave",
    "name": "Synthwave",
    "vibe": "1985 forever",
    "appearance": "dark",
    "accent": "#FF2E88",
    "swatches": [
      "#140a24",
      "#f8e9ff",
      "#FF2E88",
      "#ffc64a"
    ],
    "wallpaper": "synthwave",
    "idle": "sparks",
    "dock": "vertical",
    "sounds": "soft-synth",
    "cursor": "spark"
  },
  {
    "id": "forest",
    "name": "Forest",
    "vibe": "Moss, pine and fireflies",
    "appearance": "dark",
    "accent": "#5FB36A",
    "swatches": [
      "#0b1610",
      "#e3f0e1",
      "#5FB36A",
      "#e9c46a"
    ],
    "wallpaper": "fireflies",
    "idle": "breathing",
    "dock": "floating-glass",
    "sounds": "wood-tap",
    "cursor": "leaf"
  },
  {
    "id": "latte",
    "name": "Latte",
    "vibe": "Oat milk and morning light",
    "appearance": "light",
    "accent": "#B07A4F",
    "swatches": [
      "#f5ece2",
      "#2b1d14",
      "#B07A4F",
      "#e8b98a"
    ],
    "wallpaper": "liquid",
    "idle": "breathing",
    "dock": "centered-pill",
    "sounds": "soft-pencil",
    "cursor": "ring"
  },
  {
    "id": "fjord",
    "name": "Fjord",
    "vibe": "Cold air, clear water",
    "appearance": "dark",
    "accent": "#88C0D0",
    "swatches": [
      "#1d2330",
      "#e5ecf2",
      "#88C0D0",
      "#a3be8c"
    ],
    "wallpaper": "aurora",
    "idle": "sparks",
    "dock": "minimal",
    "sounds": "low-hum",
    "cursor": "comet"
  },
  {
    "id": "rose",
    "name": "Ros\u00e9",
    "vibe": "Soft pink, golden hour",
    "appearance": "light",
    "accent": "#D7827E",
    "swatches": [
      "#faeeeb",
      "#2d1a1c",
      "#D7827E",
      "#f2b8a0"
    ],
    "wallpaper": "petals",
    "idle": "pet",
    "dock": "floating-glass",
    "sounds": "chimes",
    "cursor": "petal"
  },
  {
    "id": "lavender",
    "name": "Lavender",
    "vibe": "Calm purple haze",
    "appearance": "light",
    "accent": "#9B7BE0",
    "swatches": [
      "#f1edfa",
      "#1e1830",
      "#9B7BE0",
      "#ffb3d1"
    ],
    "wallpaper": "silk",
    "idle": "breathing",
    "dock": "floating-glass",
    "sounds": "chimes",
    "cursor": "comet"
  },
  {
    "id": "ember",
    "name": "Ember",
    "vibe": "Glowing coals at midnight",
    "appearance": "dark",
    "accent": "#FF5A36",
    "swatches": [
      "#1a0b08",
      "#ffe9df",
      "#FF5A36",
      "#ffc64a"
    ],
    "wallpaper": "lava",
    "idle": "sparks",
    "dock": "centered-pill",
    "sounds": "low-hum",
    "cursor": "spark"
  },
  {
    "id": "glacier",
    "name": "Glacier",
    "vibe": "Ice blue and fresh snow",
    "appearance": "light",
    "accent": "#4FB3D9",
    "swatches": [
      "#eef6fa",
      "#0f2430",
      "#4FB3D9",
      "#a6e3f5"
    ],
    "wallpaper": "snowfall",
    "idle": "sparks",
    "dock": "minimal",
    "sounds": "chimes",
    "cursor": "comet"
  }
];
