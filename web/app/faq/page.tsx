import type { Metadata } from "next";
import Faq from "@/components/Faq";
import { SimpleHero } from "@/components/PageShell";

export const metadata: Metadata = {
  title: "FAQ · Notchi",
  description: "Is Notchi free? What does it do with my data? Why does it ask for Accessibility? Straight answers about the free macOS notch app.",
  openGraph: { title: "FAQ · Notchi", description: "Straight answers about privacy, permissions and how Notchi works." },
};

export default function Page() {
  return (
    <>
      <SimpleHero eyebrow="FAQ" title={"Straight\nanswers"} line="Privacy, permissions, installing and undoing. If something isn't here, ask on GitHub." />
      <Faq />
    </>
  );
}
