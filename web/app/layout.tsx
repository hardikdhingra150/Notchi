import type { Metadata, Viewport } from "next";
import { Fraunces, JetBrains_Mono, Space_Grotesk } from "next/font/google";
import "lenis/dist/lenis.css";
import "./globals.css";
import "./sections.css";
import { SITE_URL } from "@/lib/site";
import { THEME_KEY } from "@/lib/themes";

const fraunces = Fraunces({ subsets: ["latin"], axes: ["SOFT", "opsz"], variable: "--font-fraunces" });
const grotesk = Space_Grotesk({ subsets: ["latin"], weight: ["500", "600", "700"], variable: "--font-grotesk" });
const mono = JetBrains_Mono({ subsets: ["latin"], weight: ["400", "600"], variable: "--font-mono" });

const description =
  "A free, open-source, fully animated macOS desktop suite. The notch, wallpaper, dock, icons, sidebar, menu bar, sounds and cursor all follow one theme.";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: "Notchi: the notch, with personality",
  description,
  openGraph: { title: "Notchi: the notch, with personality", description, type: "website", url: SITE_URL },
  twitter: { card: "summary_large_image", title: "Notchi: the notch, with personality", description },
};

export const viewport: Viewport = {
  themeColor: "#ebe5d4",
};

// Set the saved theme before first paint, so there is no flash.
const themeInit = `try{var t=localStorage.getItem("${THEME_KEY}");if(t)document.documentElement.dataset.theme=t}catch(e){}`;

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" data-theme="paper" className={`${fraunces.variable} ${grotesk.variable} ${mono.variable}`} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInit }} />
      </head>
      <body>{children}</body>
    </html>
  );
}
