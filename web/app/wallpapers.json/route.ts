import { statSync } from "node:fs";
import { join } from "node:path";
import { COLLECTIONS, WALLPAPERS } from "@/lib/wallpapers";
import { SITE_URL } from "@/lib/site";

/** The wallpaper library as JSON, for the app's Wallpapers window and `notchi wallpaper get`.
 *  Prerendered at build time, so it's a static file like the videos. Keep the shape stable:
 *  older versions of the app read it (they ignore fields they don't know). */
const size = (file: string) => {
  try { return statSync(join(process.cwd(), "public/wallpapers", file)).size; } catch { return undefined; }
};

export function GET() {
  const base = `${SITE_URL}/wallpapers`;
  return Response.json({
    schema: 1,
    collections: COLLECTIONS.map(({ id, name, tagline, note }) => ({ id, name, tagline, note })),
    wallpapers: WALLPAPERS.map((w) => ({
      id: w.id,
      name: w.name,
      collection: w.collection,
      kind: w.kind,
      theme: w.theme,
      line: w.line,
      credit: w.credit,
      video: `${base}/${w.id}.mp4`,
      preview: `${base}/${w.id}-preview.mp4`,
      poster: `${base}/${w.id}.jpg`,
      bytes: size(`${w.id}.mp4`),
    })),
  });
}
