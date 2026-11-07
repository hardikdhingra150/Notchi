import Battery from "@/components/Battery";
import Explore from "@/components/Explore";
import Hero from "@/components/Hero";
import Install from "@/components/Install";
import Marquee from "@/components/Marquee";
import Receipt from "@/components/Receipt";

export default function Home() {
  return (
    <>
      <Hero />
      <Marquee />
      <Explore />
      <Battery />
      <Receipt />
      <Install />
    </>
  );
}
