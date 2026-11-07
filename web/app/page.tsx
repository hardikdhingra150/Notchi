import { SiteNotch, TopBar } from "@/components/Chrome";
import Cursor from "@/components/Cursor";
import Hero from "@/components/Hero";
import Shade from "@/components/Shade";
import SmoothScroll from "@/components/SmoothScroll";

export default function Home() {
  return (
    <>
      <SmoothScroll />
      <TopBar />
      <SiteNotch />
      <main>
        <Hero />
        <section className="section" id="live" data-notch="Live activities" style={{ minHeight: "100vh" }} />
      </main>
      <div className="mat" aria-hidden />
      <Shade />
      <Cursor />
    </>
  );
}
