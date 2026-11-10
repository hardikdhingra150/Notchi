/** The wallpaper library. Files live in /public/wallpapers: <id>.mp4 (1080p download),
 *  <id>-preview.mp4 (small tile loop) and <id>.jpg (poster). Every one loops seamlessly.
 *
 *  "Footage" wallpapers are real video in the public domain, cut and looped with
 *  marketing/wallpapers/real/clip.swift (sources and cut points: marketing/wallpapers/real/README.md).
 *  "Shader" and "Particles" wallpapers are drawn by Notchi (marketing/wallpapers/*.js).
 *  Older animated loops that the community themes use are still in /public/wallpapers
 *  but aren't listed here. */
export type CollectionId = "earth" | "parks" | "animated";

export type Wallpaper = {
  id: string;
  name: string;
  collection: CollectionId;
  kind: "Footage" | "Shader" | "Particles";
  theme: "Paper" | "Midnight" | "Matcha" | "Sakura" | "Neon Rain" | "Any";
  line: string;
  /** Who filmed it, for real footage. */
  credit?: string;
};

export const WALLPAPERS: Wallpaper[] = [
  { id: "earth-cloud-deck", collection: "earth", name: "Cloud Deck", kind: "Footage", theme: "Midnight", line: "A sheet of cloud breaking against a mountain range, with the curve of the Earth below.", credit: "NASA · Johnson Space Center" },
  { id: "earth-blue-limb", collection: "earth", name: "Blue Horizon", kind: "Footage", theme: "Midnight", line: "Bands of cloud over a coastline, and the thin blue line of the atmosphere.", credit: "NASA · Johnson Space Center" },
  { id: "earth-deep-blue", collection: "earth", name: "Deep Blue", kind: "Footage", theme: "Midnight", line: "Open ocean and the edge of the planet against black space. Calm, with room for icons.", credit: "NASA · Johnson Space Center" },
  { id: "earth-from-station", collection: "earth", name: "From the Station", kind: "Footage", theme: "Midnight", line: "Earth turning under the space station's solar panels.", credit: "NASA · Johnson Space Center" },
  { id: "earth-snow-range", collection: "earth", name: "Snow Range", kind: "Footage", theme: "Paper", line: "Snow-capped ridges pushing through cloud, seen at a low angle.", credit: "NASA · Johnson Space Center" },
  { id: "earth-desert-ridges", collection: "earth", name: "Desert Ridges", kind: "Footage", theme: "Paper", line: "Folded desert mountains dusted with snow, out to a hazy horizon.", credit: "NASA · Johnson Space Center" },
  { id: "earth-desert-coast", collection: "earth", name: "Desert Coast", kind: "Footage", theme: "Paper", line: "A river delta where sand-coloured land meets a dark sea.", credit: "NASA · Johnson Space Center" },
  { id: "earth-lagoon", collection: "earth", name: "Salt Lagoon", kind: "Footage", theme: "Matcha", line: "Turquoise shallows and white salt flats on a green coast.", credit: "NASA · Johnson Space Center" },
  { id: "earth-turquoise-bay", collection: "earth", name: "Turquoise Bay", kind: "Footage", theme: "Matcha", line: "Wisps of high cloud drifting over a shallow tropical bay.", credit: "NASA · Johnson Space Center" },
  { id: "earth-thunderheads", collection: "earth", name: "Thunderheads", kind: "Footage", theme: "Midnight", line: "Storm clouds boiling up over the open ocean, lit from the side.", credit: "NASA · Johnson Space Center" },
  { id: "earth-cloud-fields", collection: "earth", name: "Cloud Fields", kind: "Footage", theme: "Midnight", line: "Soft swirls of cloud over a dark sea.", credit: "NASA · Johnson Space Center" },
  { id: "earth-fair-weather", collection: "earth", name: "Fair Weather", kind: "Footage", theme: "Any", line: "Small bright clouds scattered across a pale blue ocean.", credit: "NASA · Johnson Space Center" },
  { id: "park-autumn-falls", collection: "parks", name: "Autumn Falls", kind: "Footage", theme: "Paper", line: "Great Falls of the Potomac in autumn, the river pouring over the rocks.", credit: "National Park Service · Great Falls Park" },
  { id: "park-cherry-blossom", collection: "parks", name: "Cherry Blossom", kind: "Footage", theme: "Sakura", line: "Pink blossoms moving in the breeze against a spring sky.", credit: "National Park Service · National Mall" },
  { id: "park-white-blossom", collection: "parks", name: "White Blossom", kind: "Footage", theme: "Sakura", line: "Branches heavy with white blossom under a clear blue sky.", credit: "National Park Service · National Mall" },
  { id: "park-winter-dunes", collection: "parks", name: "Winter Dunes", kind: "Footage", theme: "Paper", line: "Wind in the dune grass at sunset, with a dusting of snow on the sand.", credit: "National Park Service · Indiana Dunes" },
  { id: "park-misty-falls", collection: "parks", name: "Misty Falls", kind: "Footage", theme: "Midnight", line: "Great Falls on a grey morning, mist hanging over the water.", credit: "National Park Service · Great Falls Park" },
  { id: "park-river-gorge", collection: "parks", name: "River Gorge", kind: "Footage", theme: "Matcha", line: "The Potomac cutting through Mather Gorge under a bright sky.", credit: "National Park Service · Great Falls Park" },
  { id: "savanna", collection: "animated", name: "Savanna Sunset", kind: "Shader", theme: "Paper", line: "Acacias and a giraffe against a low sun, grass moving in the warm wind." },
  { id: "misty-pines", collection: "animated", name: "Misty Pines", kind: "Shader", theme: "Midnight", line: "Ridge after ridge of pines in morning mist, mirrored in a still lake." },
  { id: "cloud-sea", collection: "animated", name: "Above the Clouds", kind: "Shader", theme: "Midnight", line: "Snowy peaks rising out of a sea of clouds as the sun comes up." },
  { id: "black-hole", collection: "animated", name: "Black Hole", kind: "Shader", theme: "Midnight", line: "A glowing disc of fire bending around a black hole." },
  { id: "cyber-city", collection: "animated", name: "Cyberpunk Skyline", kind: "Shader", theme: "Neon Rain", line: "Rain, neon signs and flying cars over a city that never sleeps." },
  { id: "sky-lanterns", collection: "animated", name: "Sky Lanterns", kind: "Particles", theme: "Paper", line: "Paper lanterns rising slowly from a lake at dusk." },
  { id: "ink-tide", collection: "animated", name: "Ink Tide", kind: "Shader", theme: "Paper", line: "Hand-inked hills rolling under a tomato sun." },
  { id: "starfield", collection: "animated", name: "Starfield", kind: "Shader", theme: "Midnight", line: "A slow flight through a violet galaxy." },
  { id: "leaf-drift", collection: "animated", name: "Leaf Drift", kind: "Particles", theme: "Matcha", line: "Soft green bokeh floating in morning light." },
  { id: "petals", collection: "animated", name: "Petals", kind: "Particles", theme: "Sakura", line: "Cherry blossoms drifting and spinning down." },
  { id: "neon-rain", collection: "animated", name: "Neon Rain", kind: "Particles", theme: "Neon Rain", line: "Pink and cyan streaks falling through the dark." },
];

export const WALLPAPER_THEME_COLORS: Record<Wallpaper["theme"], string> = {
  Paper: "#FF6A3D", Midnight: "#8F7CFF", Matcha: "#4F9A3A", Sakura: "#E2507F", "Neon Rain": "#FF3FD8", Any: "#5CE1C6",
};

/** `look` picks the banner's typography (the classes in sections.css). */
export type Collection = { id: CollectionId; name: string; tagline: string; hero: string; emoji: string; note?: string; look: "deep-space" | "golden-hour" | "minimal" };

/** Shown in this order, each with its own banner. */
export const COLLECTIONS: Collection[] = [
  { id: "earth", look: "deep-space", name: "Earth from Orbit", emoji: "🌍", hero: "earth-cloud-deck", note: "Real footage · NASA", tagline: "Filmed from the International Space Station, 250 miles up. The planet drifts past slowly behind your windows." },
  { id: "parks", look: "golden-hour", name: "National Parks", emoji: "🏞️", hero: "park-autumn-falls", note: "Real footage · U.S. National Park Service", tagline: "Waterfalls, blossom and dune grass in the wind, filmed in America's national parks." },
  { id: "animated", look: "minimal", name: "Animated", emoji: "◐", hero: "ink-tide", note: "Drawn by Notchi", tagline: "Illustrated loops, including the five that come with Notchi's built-in themes." },
];
