import { SiteNotch, TopBar } from "@/components/Chrome";
import Cursor from "@/components/Cursor";
import Shade from "@/components/Shade";
import SmoothScroll from "@/components/SmoothScroll";

export default function Home() {
  return (
    <>
      <SmoothScroll />
      <TopBar />
      <SiteNotch />
      <main id="top">
        <section className="section" data-notch="Hello" style={{ minHeight: "200vh" }}>
          <h1 className="display" style={{ fontSize: 96 }}>The notch,<br />with personality</h1>
        </section>
      </main>
      <div className="mat" aria-hidden />
      <Shade />
      <Cursor />
    </>
  );
}
