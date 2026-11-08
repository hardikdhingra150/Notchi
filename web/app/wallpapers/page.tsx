import type { Metadata } from "next";
import { PageHero, PagePager } from "@/components/PageShell";
import WallpaperGallery from "@/components/WallpaperGallery";
import Wallpapers from "@/components/Wallpapers";

export const metadata: Metadata = {
  title: "Wallpapers · Notchi",
  description: "Video, shader and particle wallpapers for macOS that pause when they are covered and stop in Low Power Mode.",
  openGraph: { title: "Wallpapers · Notchi", description: "Video, shader and particle wallpapers for macOS that pause when they are covered and stop in Low Power Mode." },
};

export default function Page() {
  return (
    <>
      <PageHero href="/wallpapers" />
      <WallpaperGallery />
      <Wallpapers />
      <PagePager href="/wallpapers" />
    </>
  );
}
