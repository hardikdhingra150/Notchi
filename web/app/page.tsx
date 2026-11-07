import { SiteNotch, TopBar } from "@/components/Chrome";
import Cursor from "@/components/Cursor";
import Hero from "@/components/Hero";
import Marquee from "@/components/Marquee";
import NotchPlayground from "@/components/NotchPlayground";
import Shade from "@/components/Shade";
import SmoothScroll from "@/components/SmoothScroll";
import ThemeStudio from "@/components/ThemeStudio";

export default function Home() {
  return (
    <>
      <SmoothScroll />
      <TopBar />
      <SiteNotch />
      <main>
        <Hero />
        <Marquee />
        <NotchPlayground />
        <ThemeStudio />
      </main>
      <div className="mat" aria-hidden />
      <Shade />
      <Cursor />
    </>
  );
}
