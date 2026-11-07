# Notchi

**The notch, with personality.** A free, open-source, fully animated macOS desktop suite. The notch, wallpaper, dock, icons, sidebar, menu bar, sounds and cursor all follow one theme.

> Free forever. No paywalls, no subscriptions, no ads, no tracking.

> Not affiliated with the other open-source project named "notchi" (the Claude Code notch mascot). Notchi here is the whole-desktop theming suite.

## The notch island (v0.1 in progress)

| Music | Terminal | Progress |
|---|---|---|
| ![Player](docs/snapshots/expanded-player.png) | ![Notify](docs/snapshots/notify.png) | ![Progress](docs/snapshots/progress.png) |
| ![Home](docs/snapshots/expanded-home.png) | ![Battery](docs/snapshots/battery.png) | ![Compact](docs/snapshots/compact-music.png) |

Regenerate with `dist/Notchi.app/Contents/MacOS/Notchi --snapshot docs/snapshots`.

## Repo layout

| Folder | What it is |
|---|---|
| `web/` | The website (Next.js, deployed on Vercel) |
| `App/` | The menu-bar app (`Notchi.app`) |
| `Packages/NotchiCore` | Theme engine, event bus, energy governor, notch detection, Now Playing, battery |
| `Packages/NotchiNotch` | The notch island and its live activities |
| `CLI/notchi` | The `notchi` command-line tool |
| `Themes/` | Built-in themes |
| `PROJECT_BLUEPRINT.md` | The full product plan |

## Build and run the app

macOS 14+ and Swift 6 (Xcode or just the Command Line Tools).

```bash
./scripts/bundle.sh        # builds dist/Notchi.app and dist/notchi
open dist/Notchi.app       # hover the notch to open it
./scripts/test.sh          # run the tests
```

## The `notchi` command

```bash
notchi notify "Build done ✅"          # show a message in the notch
notchi progress 42 "Exporting"         # show progress (100 hides it)
notchi apply midnight                  # apply a theme
notchi theme list                      # list themes
notchi status                          # what the notch is showing
notchi doctor                          # check setup and conflicts
```

Use it in scripts: `npm run build && notchi notify "Build done ✅" || notchi notify "Build failed ❌"`

## Run the website

```bash
cd web
npm install
npm run dev
```

## Licence

App: GPL-3.0. Plugin SDK: MIT. Built-in themes and assets: CC BY 4.0.
