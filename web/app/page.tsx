import { SiteNotch, TopBar } from "@/components/Chrome";
import Cursor from "@/components/Cursor";
import Battery from "@/components/Battery";
import Footer from "@/components/Footer";
import Hero from "@/components/Hero";
import Install from "@/components/Install";
import Marquee from "@/components/Marquee";
import Modules from "@/components/Modules";
import NotchPlayground from "@/components/NotchPlayground";
import Receipt from "@/components/Receipt";
import Roadmap from "@/components/Roadmap";
import Shade from "@/components/Shade";
import Shipped from "@/components/Shipped";
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
        <Shipped />
        <ThemeStudio />
        <Modules />
        <Terminal />
        <Battery />
        <Receipt />
        <Install />
        <Roadmap />
        <Footer />
      </main>
      <div className="mat" aria-hidden />
      <Shade />
      <Cursor />
    </>
  );
}
