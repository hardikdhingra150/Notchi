import { ImageResponse } from "next/og";

export const alt = "Notchi: the notch, with personality. A free, open-source macOS desktop suite.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OG() {
  const ink = "#16130e";
  return new ImageResponse(
    (
      <div style={{ width: "100%", height: "100%", display: "flex", background: "#ebe5d4", padding: 22 }}>
        <div style={{ flex: 1, display: "flex", position: "relative", border: `10px solid ${ink}`, borderRadius: 48, padding: "70px 80px", flexDirection: "column", justifyContent: "center" }}>
          <div style={{ position: "absolute", top: -10, left: 430, width: 300, height: 74, background: ink, borderRadius: "0 0 34px 34px", display: "flex", alignItems: "center", justifyContent: "center", gap: 22 }}>
            <div style={{ width: 24, height: 24, borderRadius: 12, background: "#ebe5d4" }} />
            <div style={{ width: 24, height: 24, borderRadius: 12, background: "#ebe5d4" }} />
          </div>
          <div style={{ display: "flex", fontSize: 26, letterSpacing: 8, color: ink, fontWeight: 700 }}>FREE · OPEN SOURCE · macOS 14+</div>
          <div style={{ display: "flex", flexDirection: "column", fontSize: 118, lineHeight: 0.95, color: ink, fontWeight: 800, letterSpacing: -5, marginTop: 26 }}>
            <span>YOUR NOTCH</span>
            <span>COMES ALIVE</span>
          </div>
          <div style={{ display: "flex", fontSize: 30, color: "#615a4b", marginTop: 30 }}>One free app themes your whole Mac. The notch, with personality.</div>
          <div style={{ display: "flex", gap: 18, marginTop: 40 }}>
            {["#ff6a3d", "#8f7cff", "#4f9a3a", "#e2507f", "#ff3fd8"].map((c) => (
              <div key={c} style={{ width: 46, height: 46, borderRadius: 23, background: c, border: `5px solid ${ink}` }} />
            ))}
            <div style={{ display: "flex", alignItems: "center", marginLeft: 20, padding: "0 30px", height: 56, borderRadius: 28, background: "#ff6a3d", border: `5px solid ${ink}`, fontSize: 26, fontWeight: 700, color: ink }}>NOTCHI · $0 FOREVER</div>
          </div>
        </div>
      </div>
    ),
    size,
  );
}
