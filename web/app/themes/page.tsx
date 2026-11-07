import type { Metadata } from "next";
import { PageHero, PagePager } from "@/components/PageShell";
import ThemeGallery from "@/components/ThemeGallery";
import ThemeStudio from "@/components/ThemeStudio";

export const metadata: Metadata = {
  title: "Themes · Notchi",
  description: "One theme file recolours the notch, wallpaper, icons, dock, sounds and cursor. Five built-in themes, and you can make your own.",
  openGraph: { title: "Themes · Notchi", description: "One theme file recolours the notch, wallpaper, icons, dock, sounds and cursor. Five built-in themes, and you can make your own." },
};

export default function Page() {
  return (
    <>
      <PageHero href="/themes" />
      <ThemeStudio />
      <ThemeGallery />
      <PagePager href="/themes" />
    </>
  );
}
