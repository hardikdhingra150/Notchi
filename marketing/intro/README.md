# Notchi intro film

A 24-second, 1920×1080 intro for sharing Notchi (X, YouTube, the README).
Everything is drawn by `render(t)` in `index.html`, so every frame is exact
and the film re-renders identically.

```bash
open "index.html?play"                     # watch it live in a browser
node render.mjs out/frames 30              # 720 JPEG frames via headless Chrome
swift encode.swift out/frames out/notchi-intro.mp4 30   # H.264 MP4, no ffmpeg needed
```

Needs Google Chrome, Node 22+ (built-in WebSocket) and Swift (Xcode or the
Command Line Tools). Fonts load from Google Fonts, so render with a network
connection. Output goes to `out/`, which git ignores.

Scenes: the notch that does nothing → now playing from any app → volume,
brightness and a terminal ping → one theme sweeping through all five →
wallpaper and emoji folder icons → logo, "free & open source", the repo URL.
