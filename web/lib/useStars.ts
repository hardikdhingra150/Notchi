"use client";

import { useEffect, useState } from "react";
import { REPO } from "./site";

let cache: Promise<number | null> | null = null;

/** Live GitHub star count (null until loaded or if the repo isn't public yet). */
export function useStars() {
  const [stars, setStars] = useState<number | null>(null);
  useEffect(() => {
    cache ??= fetch(`https://api.github.com/repos/${REPO}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((j) => (typeof j?.stargazers_count === "number" ? j.stargazers_count : null))
      .catch(() => null);
    let alive = true;
    cache.then((n) => alive && setStars(n));
    return () => { alive = false; };
  }, []);
  return stars;
}

export const fmtStars = (n: number) => (n >= 1000 ? `${(n / 1000).toFixed(n >= 10000 ? 0 : 1)}k` : String(n));
