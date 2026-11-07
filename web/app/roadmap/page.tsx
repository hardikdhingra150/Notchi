import type { Metadata } from "next";
import { PageHero, PagePager } from "@/components/PageShell";
import Modules from "@/components/Modules";
import Roadmap from "@/components/Roadmap";

export const metadata: Metadata = {
  title: "Roadmap · Notchi",
  description: "What is shipped in Notchi, what is next, and every module on the way. Every phase ships free.",
  openGraph: { title: "Roadmap · Notchi", description: "What is shipped in Notchi, what is next, and every module on the way. Every phase ships free." },
};

export default function Page() {
  return (
    <>
      <PageHero href="/roadmap" />
      <Roadmap />
      <Modules />
      <PagePager href="/roadmap" />
    </>
  );
}
