import type { Metadata } from "next";
import { PageHero, PagePager } from "@/components/PageShell";
import NotchComponents from "@/components/NotchComponents";
import NotchPlayground from "@/components/NotchPlayground";
import Shipped from "@/components/Shipped";

export const metadata: Metadata = {
  title: "The Notch · Notchi",
  description: "Live activities over your MacBook notch: now playing from any app, volume, brightness, battery, a file shelf and terminal messages.",
  openGraph: { title: "The Notch · Notchi", description: "Live activities over your MacBook notch: now playing from any app, volume, brightness, battery, a file shelf and terminal messages." },
};

export default function Page() {
  return (
    <>
      <PageHero href="/notch" />
      <NotchPlayground />
      <Shipped />
      <NotchComponents />
      <PagePager href="/notch" />
    </>
  );
}
