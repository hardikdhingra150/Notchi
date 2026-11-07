"use client";

import { motion, type HTMLMotionProps } from "motion/react";
import { Fragment, type ReactNode } from "react";

export const spring = { type: "spring", stiffness: 260, damping: 26 } as const;
const ease = [0.2, 0.9, 0.2, 1] as const;

/** Headline whose words rise out of a mask when it scrolls into view. Use "\n" for line breaks. */
export function SplitHeading({ text, className = "", as = "h2", delay = 0 }: { text: string; className?: string; as?: "h1" | "h2" | "h3"; delay?: number }) {
  const Tag = motion[as];
  let i = 0;
  return (
    <Tag className={`display ${className}`} initial="hide" whileInView="show" viewport={{ once: true, amount: 0.5 }} aria-label={text.replace(/\n/g, " ")}>
      {text.split("\n").map((line, li) => (
        <Fragment key={li}>
          {li > 0 && <br />}
          {line.split(" ").map((w, wi) => {
            const n = i++;
            return (
              <Fragment key={wi}>
                {wi > 0 && " "}
                <span className="split-word" aria-hidden>
                  <motion.span
                    variants={{ hide: { y: "110%", rotate: 6 }, show: { y: "0%", rotate: 0, transition: { duration: 0.9, ease, delay: delay + n * 0.07 } } }}
                  >
                    {w}
                  </motion.span>
                </span>
              </Fragment>
            );
          })}
        </Fragment>
      ))}
    </Tag>
  );
}

/** Fade + rise into view. */
export function Reveal({ children, delay = 0, y = 40, className, ...rest }: { children: ReactNode; delay?: number; y?: number; className?: string } & HTMLMotionProps<"div">) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.25 }}
      transition={{ duration: 0.9, ease, delay }}
      {...rest}
    >
      {children}
    </motion.div>
  );
}

export function SectionHead({ eyebrow, title, sub, center }: { eyebrow: string; title: string; sub?: string; center?: boolean }) {
  return (
    <div className={`shead${center ? " center" : ""}`}>
      <Reveal y={16}><span className="eyebrow">{eyebrow}</span></Reveal>
      <SplitHeading text={title} className="shead-title" />
      {sub && <Reveal delay={0.25} y={20}><p className="shead-sub">{sub}</p></Reveal>}
    </div>
  );
}
