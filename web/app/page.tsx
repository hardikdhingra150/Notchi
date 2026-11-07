import { SiteNotch, TopBar } from "@/components/Chrome";
import Cursor from "@/components/Cursor";
import Battery from "@/components/Battery";
import { Chapter, ChapterRail } from "@/components/Chapter";
import IconStudio from "@/components/IconStudio";
import NotchComponents from "@/components/NotchComponents";
import ThemeGallery from "@/components/ThemeGallery";
import Wallpapers from "@/components/Wallpapers";
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

        <Chapter id="notch" line="The island over your notch: what's playing, volume, brightness, battery, files and messages from your terminal." items={["Live playground", "Real screenshots", "15 components"]} />
        <NotchPlayground />
        <Shipped />
        <NotchComponents />

        <Chapter id="theming" line="One theme file recolours everything Notchi touches, with a sweep across the screen." items={["Theme studio", "5 built-in themes", "Theme file format"]} />
        <ThemeStudio />
        <ThemeGallery />

        <Chapter id="wallpapers" line="Video, shader and particle wallpapers that pause the moment you can't see them." items={["Video", "Shaders", "Particles", "Battery aware"]} />
        <Wallpapers />

        <Chapter id="icons" line="Emoji and image badges for your folders, retinted to your theme, always undoable." items={["Folder badges", "Accent tint", "One-click restore"]} />
        <IconStudio />

        <Chapter id="terminal" line="Everything in the menu bar is a command too, so scripts and AI agents can use the notch." items={["notchi notify", "progress", "apply", "doctor"]} />
        <Terminal />

        <Chapter id="more" line="The rest of the suite, how light it is on your battery, and how it compares." items={["9 modules", "Battery first", "Compare"]} />
        <Modules />
        <Battery />
        <Receipt />

        <Install />
        <Roadmap />
        <Footer />
      </main>
      <div className="mat" aria-hidden />
      <ChapterRail />
      <Shade />
      <Cursor />
    </>
  );
}
