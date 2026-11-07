import type { Metadata } from "next";
import { PageHero, PagePager } from "@/components/PageShell";
import CommandReference from "@/components/CommandReference";
import Terminal from "@/components/Terminal";

export const metadata: Metadata = {
  title: "Terminal · Notchi",
  description: "The notchi command: show build results, progress and AI agent status in your MacBook notch from any script.",
  openGraph: { title: "Terminal · Notchi", description: "The notchi command: show build results, progress and AI agent status in your MacBook notch from any script." },
};

export default function Page() {
  return (
    <>
      <PageHero href="/cli" />
      <Terminal />
      <CommandReference />
      <PagePager href="/cli" />
    </>
  );
}
