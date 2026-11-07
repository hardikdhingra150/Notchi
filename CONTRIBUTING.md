# Contributing to Notchi

Thanks for helping make the Mac desktop more fun. Notchi is free forever, and every contribution keeps it that way.

## Ground rules
- **Public APIs only.** System Integrity Protection stays on. No code injection, no private frameworks.
- **Battery first.** Animations go through Core Animation or Metal and respect the `EnergyGovernor`. No timers redrawing views.
- **Private.** No analytics, no network calls except update checks and the theme gallery.
- **Modules don't talk to each other.** They share state through `EventBus` and `ThemeEngine`.

## Repo layout
| Folder | What |
|---|---|
| `App/` | The menu-bar app target (`Notchi.app`) |
| `Packages/NotchiCore` | Theme engine, event bus, energy governor, display manager |
| `Packages/NotchiNotch` | The notch island and its live activities |
| `CLI/notchi` | The `notchi` command-line tool |
| `Themes/` | Built-in themes (`.json`) |
| `web/` | The website (Next.js on Vercel) |

## Build the app
You need macOS 14+ and Swift 6 (Xcode or the Command Line Tools).

```bash
swift build
swift test
./scripts/bundle.sh   # builds dist/Notchi.app
open dist/Notchi.app
```

## Build the website
```bash
cd web && npm install && npm run dev
```

## Pull requests
1. Fork, branch from `main`, keep PRs focused on one thing.
2. `swift build && swift test` must pass (CI checks it).
3. Add a short GIF or screenshot for anything visual.
4. Look for issues labelled **good first issue** to get started.

## Themes
Add a `.json` file to `Themes/` following the format in `PROJECT_BLUEPRINT.md` section 10 and open a PR. Credit yourself in `author`.

## Licence
By contributing you agree that your code is released under GPL-3.0 (app), MIT (`NotchiSDK`) or CC BY 4.0 (themes and assets).
