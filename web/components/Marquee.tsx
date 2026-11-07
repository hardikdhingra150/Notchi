"use client";

import { motion, useAnimationFrame, useMotionValue, useScroll, useSpring, useTransform, useVelocity } from "motion/react";
import { useRef } from "react";

const wrap = (min: number, max: number, v: number) => {
  const r = max - min;
  return ((((v - min) % r) + r) % r) + min;
};

/** A tilted ribbon of text that drifts on its own and speeds up with your scroll. */
function Ribbon({ items, speed, tilt, tone }: { items: string[]; speed: number; tilt: number; tone: "hot" | "calm" }) {
  const base = useMotionValue(0);
  const { scrollY } = useScroll();
  const vel = useSpring(useVelocity(scrollY), { damping: 50, stiffness: 400 });
  const boost = useTransform(vel, [-1500, 0, 1500], [-4, 0, 4], { clamp: false });
  const x = useTransform(base, (v) => `${wrap(-25, 0, v)}%`);
  const dir = useRef(1);

  useAnimationFrame((_, delta) => {
    let m = dir.current * speed * (delta / 1000);
    const b = boost.get();
    if (b < 0) dir.current = -1;
    else if (b > 0) dir.current = 1;
    m += dir.current * m * Math.abs(b);
    base.set(base.get() + m);
  });

  const row = [...items, ...items];
  return (
    <div className={`ribbon ${tone}`} style={{ rotate: `${tilt}deg` }}>
      <motion.div className="ribbon-track" style={{ x }}>
        {[0, 1, 2, 3].map((k) => (
          <span key={k} className="ribbon-set" aria-hidden={k > 0}>
            {row.map((t, i) => (
              <span key={i} className="ribbon-item">{t}<i>✦</i></span>
            ))}
          </span>
        ))}
      </motion.div>
    </div>
  );
}

export default function Marquee() {
  return (
    <div className="marquee" aria-label="Notchi replaces a stack of paid apps">
      <Ribbon tone="hot" speed={-2.2} tilt={-3} items={["NotchNook ~$25", "Alcove $14.99", "A wallpaper app", "A dock app", "A menu bar app", "A widgets app", "Notchi: $0"]} />
      <Ribbon tone="calm" speed={1.6} tilt={2.2} items={["No accounts", "No analytics", "No tracking", "SIP stays on", "Open source", "Battery first", "Free forever"]} />
    </div>
  );
}
