import type { Metadata } from "next";
import { PageHero, PagePager } from "@/components/PageShell";
import IconStudio from "@/components/IconStudio";

export const metadata: Metadata = {
  title: "Icons · Notchi",
  description: "Give macOS folders emoji or image badges, retint them to your theme, and restore the originals in one click.",
  openGraph: { title: "Icons · Notchi", description: "Give macOS folders emoji or image badges, retint them to your theme, and restore the originals in one click." },
};

export default function Page() {
  return (
    <>
      <PageHero href="/icons" />
      <IconStudio />
      <PagePager href="/icons" />
    </>
  );
}
