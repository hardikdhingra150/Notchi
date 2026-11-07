# Notchi — Project Blueprint

> **Name:** Notchi (the notch, with personality)
> **CLI:** `notchi`
> **Budget:** $0. Everything uses free tools and services.
> **One line:** A free, open-source, fully animated macOS desktop suite. The notch, wallpaper, dock, icons, sidebar, menu bar, sounds and cursor all follow one theme.
> **Promise:** Free forever. No paywalls, no subscriptions, no ads, no tracking.

---

## Table of contents
1. [Vision](#1-vision)
2. [Core principles](#2-core-principles)
3. [What macOS allows (technical reality)](#3-what-macos-allows-technical-reality)
4. [Competitors and how we beat them](#4-competitors-and-how-we-beat-them)
5. [Feature list by module](#5-feature-list-by-module)
6. [The notch island (main feature)](#6-the-notch-island-main-feature)
7. [What makes it legendary](#7-what-makes-it-legendary)
8. [Architecture](#8-architecture)
9. [Repo layout](#9-repo-layout)
10. [Theme file format](#10-theme-file-format)
11. [Plugin SDK](#11-plugin-sdk)
12. [Command-line tool (`notchi`)](#12-command-line-tool-notchi)
13. [Keeping it free](#13-keeping-it-free)
14. [Performance and battery targets](#14-performance-and-battery-targets)
15. [Permissions and privacy](#15-permissions-and-privacy)
16. [Design standards](#16-design-standards)
17. [Accessibility and localization](#17-accessibility-and-localization)
18. [Quality and testing](#18-quality-and-testing)
19. [Roadmap](#19-roadmap)
20. [Launch and growth](#20-launch-and-growth)
21. [Community and governance](#21-community-and-governance)
22. [Risks](#22-risks)
23. [Success metrics](#23-success-metrics)
24. [First steps](#24-first-steps)
25. [Prompt for starting a new build session](#25-prompt-for-starting-a-new-build-session)

---

## 1. Vision
Mac users who want a personal, animated desktop currently stack 4–5 separate paid apps (notch, dock, wallpaper, widgets, menu bar). Together they cost $60–100, don't match visually, sometimes conflict, and each one uses battery.

**Notchi replaces all of them with one free app.** Pick a theme and the whole desktop changes with an animation: the notch glows in the accent colour, the wallpaper comes alive, icons are retinted, the dock and sidebar turn to glass, and the sounds change.

It should feel like Apple shipped it, and go further than Apple would.

---

## 2. Core principles
1. **Free forever, open source.** Every feature is free. No "Pro" tier, ever.
2. **One theme controls everything.** Every module follows the active theme.
3. **Battery first.** It must never be the app people uninstall for draining the battery.
4. **Safe.** System Integrity Protection stays on. No code injection, no private hacks that break on macOS updates.
5. **Private.** Everything runs on the Mac. No accounts, no analytics, no tracking.
6. **Modular.** Every module can be turned on or off. Use only what you want.
7. **Extensible.** Anyone can build themes and plugins.
8. **Delightful.** Every interaction has a polished, physics-based animation.

---

## 3. What macOS allows (technical reality)

| Area | Possible? | How |
|---|---|---|
| Folder and app icons | ✅ Yes | `NSWorkspace.shared.setIcon(_:forFile:)`. Apple's built-in apps protected by System Integrity Protection (Safari etc.) are locked. App updates reset custom icons, so a watcher reapplies them. |
| Animated wallpaper | ✅ Yes | A borderless window at desktop level (`kCGDesktopWindowLevel`) playing video, Metal shaders or particles. |
| Notch island | ✅ Yes | A borderless window placed over the notch area. Every competitor does it this way. |
| Dock behaviour | ✅ Partly | `defaults write com.apple.dock …` for size, magnification, position and autohide. For a new look, build a replacement dock. |
| Liquid Glass / transparent look | ✅ In our own UI | SwiftUI `.glassEffect()` on macOS 26; `NSVisualEffectView` on older versions. |
| Desktop widgets | ✅ Yes | Our own windows, plus WidgetKit widgets. |
| Menu bar | ⚠️ Overlay only | A tinted or glass overlay window, and hiding clutter icons. The real menu bar can't be restyled. |
| Apple's Notification Center and Control Center | ❌ No | Would need System Integrity Protection off and code injection. **We build our own glass sidebar instead.** |
| System window animations | ❌ No | We can add overlay effects (for example a glow on app launch) but not replace Apple's animations. |
| Reading other apps' notifications | ❌ No public API | Only partial workarounds. Don't promise it. |

**Conclusion:** shell scripts alone can't animate anything. Notchi is a **native Swift/SwiftUI menu-bar app**, with the `notchi` command-line tool for terminal users.

---

## 4. Competitors and how we beat them

| Category | Apps | Price | Weakness |
|---|---|---|---|
| Notch | NotchNook | ~$25 | Some users report battery drain; reviewers called the price high for unfinished features |
| Notch | Alcove | $14.99 | Visual-focused; no file handling |
| Notch | boring.notch | Free | Mostly music controls and animations |
| Notch | Notchable, Notchly, many clones | ~$25 | Crowded and similar to each other |
| Dock | DockFix, Deskmat, Docky | Paid | Dock only |
| Wallpaper | Backdrop, Wallper, Wallux | Paid | Wallpaper only |
| Widgets | macOS Tahoe built in, Desktop Verse, Übersicht | Free or paid | Basic, or needs coding |
| Menu bar | Ice, Bartender | Free or paid | Menu bar only |

**The gap:** nobody offers one app where everything follows one theme, and nobody offers it all for free.

**How Notchi wins:**
1. **One suite, one theme.** Everything changes together, with an animated transition.
2. **Free and open source.** Beats every paid competitor on price, and beats boring.notch on features.
3. **Battery transparency.** An energy governor plus a visible energy panel.
4. **Liquid Glass design** that looks native on macOS 26.
5. **Works on Macs without a notch.** A virtual island on external monitors and older Macs.
6. **Developer features.** The command-line tool, terminal notifications in the notch, and a plugin SDK.
7. **On-device AI theme generator** with no cost and no cloud.

---

## 5. Feature list by module

### 5.1 Theme engine
- One theme file (JSON) controls every module.
- Apply a whole theme in one click, with an animated crossfade.
- Built-in themes plus a community gallery.
- Import and export themes as `.notchitheme` files.
- Backup and restore, including **one-click "Restore stock macOS"**.

### 5.2 Live wallpaper
- Video wallpapers (MP4/MOV, including HEVC with alpha).
- Metal shader wallpapers (rain, aurora, fluid, starfield, gradients).
- Particle wallpapers that react to the cursor.
- Changes with time of day, weather or the music playing.
- Different wallpaper per display and per Space.
- A built-in wallpaper editor.
- Lock-screen support where macOS allows it.
- Pauses automatically when an app is full screen, the screen is covered, on battery, or in Low Power Mode.

### 5.3 Icon studio
- Icon packs for apps.
- Auto-generated folder icons from an emoji, SF Symbol, colour or gradient.
- Retints all icons to the theme's accent colour.
- A watcher that reapplies icons after app updates.
- One-click restore of original icons.
- Drag-and-drop icon editor.

### 5.4 Glass sidebar (our own Notification Center replacement)
- Opens with a trackpad swipe, a hot corner or a keyboard shortcut.
- Widgets: calendar, reminders and to-dos, now playing, weather, system stats (CPU, RAM, battery, network), clipboard history, quick toggles (Wi-Fi, Bluetooth, Do Not Disturb, dark mode), notes, world clocks.
- Rearranged by drag and drop; spring animations.
- Plugin widgets from the community.

### 5.5 Dock (optional replacement)
- Styles: floating glass, minimal, vertical, centered pill.
- Window previews on hover.
- App groups and folders.
- Launch, bounce and ripple animations.
- Widgets inside the dock.

### 5.6 Menu bar styling
- A tinted or glass overlay bar.
- Custom clock and stats.
- Hiding clutter icons.

### 5.7 Effects
- Cursor trails and click ripples.
- Sound packs for login, screenshots, emptying the trash, and notifications.
- A login animation.
- A glow when an app launches.

### 5.8 Desktop widgets
- Free-floating glass widgets on the desktop, snapped to a grid.
- Clock, calendar, photos, quotes, system stats, music, countdowns.

### 5.9 Profiles
- Work, Gaming, Night, Focus and custom profiles.
- Switch automatically by time, Wi-Fi network, connected display, Focus mode or battery level.

### 5.10 AI theme generator (on-device)
- Pick a wallpaper and get a matching theme (accent colour, icon tint, glass strength, sounds).
- Type a prompt like "cyberpunk rain" and get a complete theme.
- Runs on Apple's on-device Foundation Models (macOS 26) plus local colour extraction. No API costs, no internet needed.

---

## 6. The notch island (main feature)

### Live activities
- **Music:** album art, album-colour glow, an audio visualizer that spills out of the notch, controls and a scrubber.
- **Timers and Pomodoro**, with a progress ring around the notch.
- **Calendar:** a countdown to the next meeting, with a join button.
- **Battery:** a charging animation and low-battery warning.
- **AirPods and Bluetooth:** a connect animation with battery levels.
- **Focus mode changes.**
- **Volume and brightness indicators** that slide out of the notch, replacing the system ones.
- **Progress:** downloads, uploads, exports.
- **Calls and meetings:** microphone and camera status.

### Productivity
- **File shelf:** drag files onto the notch to hold them, then AirDrop or share.
- Clipboard history.
- Quick notes.
- Mini calendar and weather.
- **Mirror:** a quick webcam preview before calls.
- **Screenshot previews** that pop out of the notch.

### Features no competitor has
- **Theme-synced notch:** colour, glow and animation style follow the active theme.
- **Ambient idle animations:** breathing glow, rain, sparks, or a small notch pet that reacts to what you do.
- **Terminal notifications:** `notchi notify "Build done ✅"` shows in the notch. Build progress, git push results and AI-agent status too.
- **Gestures:** swipe for media, scroll for volume, long-press for the sidebar, pinch to expand.
- **Virtual island** on Macs without a notch and on external displays.
- **Notch plugins** through the SDK.
- **Haptic feedback** on Force Touch trackpads.

---

## 7. What makes it legendary
Features get people to install. Polish and personality get them to stay and tell friends.

### 7.1 First launch
- A cinematic onboarding: the screen dims, the notch "wakes up" with a glow, and a guided tour of each module plays.
- Pick a starting theme with a live preview before applying it.
- Ask for each permission only at the moment a feature needs it, with a plain-language explanation.

### 7.2 Details that delight
- Every animation uses spring physics; nothing moves linearly.
- Sound and haptics are paired with visual feedback.
- Theme switching plays a "wave" that sweeps across the screen.
- Easter eggs (for example the notch pet reacting to the Konami code, or a special animation at midnight on New Year's).
- Seasonal and holiday themes released through the year.
- A "Wrapped"-style yearly recap, generated locally: your most-used theme, focus hours, songs played.

### 7.3 Trust
- Open source, so anyone can verify there's no tracking.
- Energy use shown openly in settings.
- One-click full uninstall and "Restore stock macOS".
- Public roadmap and changelog.

### 7.4 Community
- Theme contests, with winners included in the app.
- Creator credits shown inside the app on every theme and plugin.
- A gallery website where people browse and share setups with screenshots.
- "Share my setup": export your full desktop as one file plus a screenshot card for social media.

### 7.5 Quality standards
- Launch in under 1 second; theme switch in under 500 ms.
- No crashes in normal use; every crash fixed in the next release.
- Same-week support for new macOS betas each summer.

---

## 8. Architecture

**Stack:** Swift 6, SwiftUI + AppKit, Metal, AVFoundation, Combine/async-await, Swift Package Manager.
**Supported macOS:** 14 Sonoma and later. Liquid Glass on macOS 26; `NSVisualEffectView` blur on earlier versions.
**Distribution:** outside the Mac App Store (App Store sandboxing would block most features). Signed with a free self-signed certificate and updated with Sparkle (see section 13).

```
Notchi.app (menu-bar app, starts at login via SMAppService)
├── Core
│   ├── ThemeEngine      – loads, validates, applies and animates themes
│   ├── ProfileManager   – automatic profile switching by rules
│   ├── EnergyGovernor   – frame-rate limits, pausing on battery / full screen / covered screens
│   ├── EventBus         – shared events: music, battery, Focus, Bluetooth, displays
│   ├── DisplayManager   – multiple monitors, notch detection, Spaces
│   └── SettingsStore    – settings, backup and restore
├── Modules (each can be turned on or off)
│   ├── NotchIsland
│   ├── LiveWallpaper
│   ├── IconStudio
│   ├── GlassSidebar
│   ├── Dock
│   ├── MenuBarSkin
│   ├── Effects
│   ├── DesktopWidgets
│   └── AIThemeGen
├── PluginHost           – loads community plugins
└── IPC server           – local connection used by notchi
notchi                  – command-line tool
```

**Key design decisions**
- Each module is a separate Swift package, so contributors can work on one without touching the others.
- Modules never talk to each other directly; they use the EventBus and ThemeEngine.
- All rendering of animations goes through Metal or Core Animation, never timers redrawing views.
- The EnergyGovernor has final say over every module's frame rate.

---

## 9. Repo layout
```
notchi/
├── App/                 # menu-bar app, onboarding, settings window
├── Packages/
│   ├── NotchiCore/        # theme engine, energy governor, event bus, display manager
│   ├── NotchiNotch/
│   ├── NotchiWallpaper/
│   ├── NotchiIcons/
│   ├── NotchiSidebar/
│   ├── NotchiDock/
│   ├── NotchiMenuBar/
│   ├── NotchiEffects/
│   ├── NotchiWidgets/
│   ├── NotchiAI/
│   └── NotchiSDK/         # public plugin API (MIT licence)
├── CLI/notchi/
├── Themes/              # built-in themes
├── Resources/           # sounds, shaders, icon packs
├── docs/                # website and docs (GitHub Pages)
├── Tests/
└── .github/             # automated build, self-sign, release
```

---

## 10. Theme file format
```json
{
  "schema": 1,
  "id": "neon-rain",
  "name": "Neon Rain",
  "author": "your-github-name",
  "version": "1.0.0",
  "appearance": "dark",
  "accent": "#7C5CFF",
  "glass": { "blur": 0.8, "tint": 0.25 },
  "wallpaper": { "type": "shader", "src": "rain.metal", "fps": 30 },
  "icons": { "pack": "neon-line", "tintFolders": true },
  "notch": { "glow": "accent", "idle": "breathing", "visualizer": true },
  "sidebar": { "widgets": ["nowPlaying", "calendar", "stats"] },
  "dock": { "style": "floating-glass", "magnify": 1.4 },
  "menuBar": { "tint": "accent", "opacity": 0.4 },
  "sounds": { "pack": "soft-synth" },
  "cursor": { "trail": "spark" }
}
```
A `.notchitheme` file is a zip of this JSON plus its assets (videos, shaders, icons, sounds).

---

## 11. Plugin SDK
- **Language:** Swift (`NotchiSDK` package, MIT licence).
- **Plugin types:** notch activity, sidebar widget, desktop widget, wallpaper effect, sound pack.
- **Safety:** plugins declare the permissions they need; the user approves them. Plugins run with limited access.
- **Publishing:** pull request to the community gallery repo; reviewed before listing.
- **Docs:** a template project, examples, and a "build your first notch widget in 10 minutes" guide.

---

## 12. Command-line tool (`notchi`)
```bash
notchi apply neon-rain              # apply a theme
notchi theme list                   # list installed themes
notchi wallpaper set ~/video.mp4    # set a wallpaper
notchi icon set ~/Projects 🚀       # set a folder icon
notchi icon restore --all           # restore original icons
notchi notify "Deploy ✅"           # show a message in the notch
notchi progress 42 "Exporting"      # show progress in the notch
notchi profile gaming               # switch profile
notchi export ~/my-setup.notchitheme  # export your setup
notchi doctor                       # check permissions and conflicts
```
Installed with Homebrew, or from the app's settings.

---

## 13. Keeping it free (zero-money budget)

**Rule: the project spends $0.** Users pay nothing, and the maintainers pay nothing.

| Need | Free solution |
|---|---|
| Code hosting | GitHub (public repo) |
| Downloads | GitHub Releases |
| Auto-updates | Sparkle, with its own free EdDSA update signing and the update feed on GitHub |
| Website and docs | GitHub Pages at `yourname.github.io/notchi`. No domain purchase. |
| Theme and plugin store | A GitHub repo; creators submit by pull request; the app reads the list. No server. |
| AI theme generator | Apple's on-device Foundation Models plus local colour extraction. No API costs. |
| Automated builds | GitHub Actions (free for public repos) |
| Homebrew | Our own free tap: `brew install yourname/tap/notchi` |
| Crash reports | Optional, opt-in, from macOS crash logs |
| Design | Figma free plan or Penpot (free, open source) |
| Translations | Weblate's free plan for open-source projects |
| Community | GitHub Discussions and Discord |
| Funding (optional) | GitHub Sponsors and Open Collective, donations only |

### App signing without paying Apple
The Apple Developer Program costs $99 a year, so we **skip it**:
- Sign every build with a **free self-signed certificate** (the same one every release, stored as a GitHub Actions secret). This keeps users' permissions (Accessibility etc.) working across updates; unsigned builds lose them on every update.
- On first launch macOS shows a warning. Users approve the app once: open it, then **System Settings → Privacy & Security → Open Anyway**.
- Put a 3-step GIF of this on the website, the README and the download page.
- Advanced users can also build from source with Xcode (free).

**Trade-off:** the extra "Open Anyway" step puts off some non-technical users. Early users (developers, r/macapps) are used to it. If sponsors ever cover the $99, switch to Apple signing and notarization; nothing else in the project has to change.

**Licences**
- App: **GPL-3.0**, so nobody can take it closed-source and sell it.
- Plugin SDK: **MIT**, so plugin makers have no restrictions.
- Built-in themes and assets: **CC BY 4.0**.

---

## 14. Performance and battery targets
| Metric | Target |
|---|---|
| Idle CPU | < 1% |
| RAM | < 150 MB with all modules on |
| Launch time | < 1 second |
| Theme switch | < 500 ms |
| Notch idle animation | 30 fps, dropping to 0 fps when nothing changes |
| Wallpaper on battery | Paused or 15 fps (user choice) |
| Full-screen apps | All desktop animation paused |

- An **energy panel** in settings shows Notchi's own battery impact per module.
- Test battery impact on every release and publish the numbers in the changelog.

---

## 15. Permissions and privacy
| Permission | Used for | When asked |
|---|---|---|
| Accessibility | Gestures, hot corners, dock window previews | When the user turns on those features |
| Calendar / Reminders | Calendar and to-do widgets | When the widget is added |
| Bluetooth | AirPods battery | When the activity is turned on |
| Camera | Mirror in the notch | When the mirror is first opened |
| Automation (Music / Spotify) | Now playing controls | When the music activity is turned on |

- **Never** uses screen recording.
- **No network calls** except update checks and the theme gallery, and both can be turned off.
- A privacy page in the docs lists everything the app does.

---

## 16. Design standards
- Follow Apple's Human Interface Guidelines, with Liquid Glass on macOS 26.
- SF Pro font and SF Symbols throughout.
- Spring animations everywhere (SwiftUI `.spring` / `.smooth`); no linear motion.
- A consistent corner radius, spacing grid and shadow style across all modules.
- Every module works in light mode, dark mode and with tinted icons.
- A design file (Figma or similar, free tier) shared with contributors.

---

## 17. Accessibility and localization
- **Reduce Motion:** respects the system setting; all animations have a calm alternative.
- **Reduce Transparency:** glass falls back to solid colours.
- **Increase Contrast** supported.
- **VoiceOver** labels on every control.
- Full keyboard navigation in settings and the sidebar.
- Translated by the community (String Catalogs + a free translation platform such as Weblate's free plan for open-source projects). Launch languages: English, Hindi, Spanish, German, Japanese, Chinese, Portuguese, French.

---

## 18. Quality and testing
- Unit tests for the theme engine, profiles and command-line tool.
- Snapshot tests for the notch, sidebar and dock.
- Test matrix: Apple silicon and Intel; notched and non-notched screens; single and multiple monitors; macOS 14, 15 and 26.
- Automated builds and tests on every pull request (GitHub Actions).
- Public beta channel through Sparkle and GitHub pre-releases.
- `notchi doctor` checks permissions and conflicts with other apps.

---

## 19. Roadmap
*(Solo developer, part time. Adjust as contributors join.)*

| Phase | Time | What ships |
|---|---|---|
| **0. Setup** | Week 1 | Repo, licences, folder layout, automated builds, free self-signed certificate, Sparkle, GitHub Pages website stub |
| **1. MVP — v0.1** | Weeks 2–6 | Menu-bar app; **notch island** (music, battery, volume/brightness indicators, file shelf); live video wallpaper; icon studio; `notchi` basics; onboarding |
| **2. Themes — v0.5** | Weeks 7–10 | Theme engine and file format; 5 built-in themes; energy governor; backup and restore |
| **3. Launch — v1.0** | Weeks 11–16 | Glass sidebar; profiles; shader wallpapers; virtual island for non-notch screens; community theme gallery; accessibility pass |
| **4. v1.5** | Months 5–6 | Custom dock; menu-bar styling; cursor and sound effects; desktop widgets |
| **5. v2.0** | Months 7–9 | Plugin SDK; AI theme generator; community store in the app; localization |
| **6. Beyond** | Ongoing | Seasonal themes; yearly recap; new notch activities; same-week macOS beta support |

---

## 20. Launch and growth (all free)
- **Before launch:** build in public on X and Reddit with short animated clips; a waitlist via GitHub stars and Watch.
- **Launch day:** "Show HN" on Hacker News, Product Hunt, r/macapps, r/MacOS, r/unixporn.
- **Positioning:** "Free, open-source alternative to NotchNook + DockFix + Backdrop."
- **Listings:** alternativeto.net, Homebrew, "awesome-mac" lists on GitHub.
- **Video:** TikTok, YouTube Shorts and Instagram Reels; desktop animations look great on video.
- **Creators:** invite Mac YouTubers and setup creators to make themes.
- **Ongoing:** monthly theme contests, release notes with GIFs.

---

## 21. Community and governance
- Code of conduct and contributing guide from day one.
- "Good first issue" labels for new contributors.
- A public roadmap on GitHub Projects.
- Feature voting in GitHub Discussions.
- Co-maintainers for each module as the project grows.
- Transparent sponsor spending on Open Collective.

---

## 22. Risks
| Risk | Plan |
|---|---|
| macOS updates break features | Public APIs only; test against macOS betas every summer |
| Battery complaints | Energy governor and a visible energy panel |
| Solo-maintainer burnout | Modular code, clear docs, co-maintainers |
| Gatekeeper warning puts users off (no paid Apple signing) | Clear "Open Anyway" GIF on the site and README; switch to Apple signing only if sponsors ever cover it |
| Another open-source notch app is already called Notchi (by sk-ruban, Claude Code mascot, Homebrew cask `notchi`) | Use our own Homebrew tap (`yourname/tap/notchi`), a distinct logo and tagline ("the whole-desktop suite"), and a clear README line saying we are a different project. Rename if the other developer asks. |
| Conflicts with other customization apps | Every module can be turned off; `notchi doctor` detects conflicts |
| Malicious plugins | Permission declarations, reviews before listing, limited plugin access |
| Name or trademark conflict | Check before launch |

---

## 23. Success metrics
- **v1.0:** 1,000 GitHub stars, 10,000 downloads, 50 community themes.
- **Year 1:** 10,000+ stars, 100,000+ downloads, 500+ themes, 50+ plugins, 20+ contributors.
- **Quality:** crash-free sessions > 99.5%; idle CPU < 1%.
- **Community:** active Discord, monthly contests, sponsors covering all costs.

---

## 24. First steps
1. Confirm the name Notchi is free on GitHub and not used by another Mac app; claim `github.com/<you>/notchi`.
2. Create the GitHub repo with the GPL-3.0 licence and the folder layout above.
3. Create a free self-signed code-signing certificate in Keychain Access and use it for every build.
4. Build the menu-bar app shell and the first notch activity (now playing).
5. Add the live video wallpaper and icon changer.
6. Add basic `notchi` commands.
7. Release v0.1 as a public beta.

---

## 25. Prompt for starting a new build session
Paste this into a new Claude Code session inside the project folder:

> Read `PROJECT_BLUEPRINT.md` in this folder. It is the plan for Notchi, a free, open-source, animated macOS desktop suite. Start Phase 0 and Phase 1: set up the Swift package layout from section 9, create the menu-bar app shell, and build the notch island's first live activity (now playing) following sections 6, 8 and 14. Use Swift 6, SwiftUI + AppKit, macOS 14 minimum, Liquid Glass on macOS 26.
