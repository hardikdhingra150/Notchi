"use client";

import { useSyncExternalStore } from "react";
import { currentTheme, THEME_EVENT } from "./applyTheme";
import type { ThemeId } from "./themes";

const subscribe = (cb: () => void) => {
  addEventListener(THEME_EVENT, cb);
  return () => removeEventListener(THEME_EVENT, cb);
};

/** The page's active theme, kept in sync with applyTheme(). */
export const useTheme = (): ThemeId => useSyncExternalStore(subscribe, currentTheme, () => "paper");
