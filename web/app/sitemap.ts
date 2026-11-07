import type { MetadataRoute } from "next";
import { EXTRA_PAGES, PAGES } from "@/lib/pages";
import { SITE_URL } from "@/lib/site";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: SITE_URL, changeFrequency: "weekly", priority: 1 },
    ...PAGES.map((p) => ({ url: `${SITE_URL}${p.href}`, changeFrequency: "weekly" as const, priority: 0.8 })),
    ...EXTRA_PAGES.map((p) => ({ url: `${SITE_URL}${p.href}`, changeFrequency: "weekly" as const, priority: 0.5 })),
  ];
}
