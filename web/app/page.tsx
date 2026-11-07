import { SiteNotch, TopBar } from "@/components/Chrome";
import Cursor from "@/components/Cursor";
import Battery from "@/components/Battery";
import Hero from "@/components/Hero";
import Marquee from "@/components/Marquee";
import Modules from "@/components/Modules";
import NotchPlayground from "@/components/NotchPlayground";
import Receipt from "@/components/Receipt";
import Shade from "@/components/Shade";
import SmoothScroll from "@/components/SmoothScroll";
import Terminal from "@/components/Terminal";
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
        <Modules />
        <Terminal />
        <Battery />
        <Receipt />
      </main>
      <div className="mat" aria-hidden />
      <Shade />
      <Cursor />
    </>
  );
}
