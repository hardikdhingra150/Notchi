import type { Metadata } from "next";
import Changelog from "@/components/Changelog";
import { SimpleHero } from "@/components/PageShell";

export const metadata: Metadata = {
  title: "Changelog · Notchi",
  description: "Everything that changed in Notchi, the free macOS notch and theming app, and its website.",
  openGraph: { title: "Changelog · Notchi", description: "Everything that changed in Notchi." },
};

export default function Page() {
  return (
    <>
      <SimpleHero eyebrow="Changelog" title={"What's\nnew"} line="Every change that landed, newest first. Notchi is built in public, so this moves fast." />
      <Changelog />
    </>
  );
}
