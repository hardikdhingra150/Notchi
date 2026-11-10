# Notchi

**The notch, with personality.** A free, open-source, fully animated macOS desktop suite. The notch, wallpaper, dock, icons, sidebar, menu bar, sounds and cursor all follow one theme.

**Website: [notchi-plum.vercel.app](https://notchi-plum.vercel.app)**, with a live notch simulator, the theme builder and 34 free wallpapers.

> Free forever. No paywalls, no subscriptions, no ads, no tracking.

> Not affiliated with the other open-source project named "notchi" (the Claude Code notch mascot). Notchi here is the whole-desktop theming suite.

## The notch island (v0.1)

| Music | Terminal | Progress |
|---|---|---|
| ![Player](docs/snapshots/expanded-player.png) | ![Notify](docs/snapshots/notify.png) | ![Progress](docs/snapshots/progress.png) |
| ![Home](docs/snapshots/expanded-home.png) | ![Battery](docs/snapshots/battery.png) | ![Compact](docs/snapshots/compact-music.png) |
| ![Volume](docs/snapshots/volume.png) | ![Brightness](docs/snapshots/brightness.png) | ![Shelf](docs/snapshots/shelf.png) |
| ![Video](docs/snapshots/expanded-video.png) | ![Home playing](docs/snapshots/expanded-home-playing.png) | |

The open notch has pages: **Home** (time, battery and what's playing), **Now Playing** and
the **File shelf**. Tap the dots or swipe with two fingers to switch; tap the now-playing pill
on Home to open the player. It slides back to Home after 10 seconds or when the notch closes.

### Now playing from any app

The notch shows whatever macOS shows in Control Center: a YouTube tab in Safari or Chrome,
Music, Spotify, Podcasts, VLC, IINA and so on, with artwork (or the app's icon), a live
progress bar and play/pause/skip. Since macOS 15.4 only Apple-signed processes can read
this, so Notchi loads a tiny helper ([Helpers/MediaRemoteBridge](Helpers/MediaRemoteBridge))
into `/usr/bin/perl`, the same approach other open-source notch apps use. Nothing leaves
your Mac. If a future macOS blocks it, Notchi falls back to Music and Spotify only.

### Volume and brightness in the notch

macOS has no setting to hide its own volume and brightness indicator, so Notchi catches
those keys first, changes the level itself and shows it in the notch. The macOS
indicator never appears. This needs **Accessibility** access, which Notchi asks for only
when you turn it on (menu bar → *Volume & Brightness in the Notch*, or Settings).
Shift+Option+key gives fine steps, and Option+key still opens System Settings like before.
Brightness uses DisplayServices, the private framework MonitorControl also uses, because
macOS has no public brightness API. If it's ever missing, the keys go back to macOS.
`notchi doctor` tells you whether it's on.

> **Building it yourself?** Ad hoc builds get a new code signature on every rebuild, and
> macOS silently stops applying the Accessibility grant (the switch still looks on), so the
> macOS indicator comes back. Run `./scripts/dev-signing.sh` once: it makes a local signing
> identity in its own keychain file and `bundle.sh` uses it from then on. Then allow Notchi
> once more. `notchi doctor` tells you if this is the problem.

Regenerate with `dist/Notchi.app/Contents/MacOS/Notchi --snapshot docs/snapshots`.

## Themes (v0.5)

Pick a theme and the desktop changes together: the wallpaper fades to the theme's video,
the notch takes its colour, glow and idle animation, and folders you tinted with the accent
are recoloured. Five themes are built in: Paper, Midnight, Neon Rain, Sakura and Matcha.

```bash
notchi apply midnight                    # switch theme
notchi theme new my-theme "My Theme"     # start your own from the active one
notchi theme export my-theme             # my-theme.notchitheme, ready to share
notchi theme install cool.notchitheme    # or double-click the file
```

A theme is a folder with a `theme.json` and its video; a `.notchitheme` is that folder
zipped. The format is in [Themes/README.md](Themes/README.md). Themes are data only and
can't run code. If you'd rather keep your own wallpaper, turn off *Themes change my
wallpaper* in Settings → Themes.

### Backup, restore and going back to stock macOS

```bash
notchi backup ~/Desktop/setup.notchibackup   # theme, settings, installed themes, icons, wallpaper
notchi restore ~/Desktop/setup.notchibackup  # on this Mac or a new one
notchi reset                                 # wallpaper off, original icons back, macOS volume indicator back
```

The same three are in the menu bar under *Backup*. Before a restore or a reset Notchi saves
your current setup in `~/Library/Application Support/Notchi/Backups` (it keeps the newest five).

### Energy

Animations run at 30 fps when plugged in and at your choice on battery (paused, 15 or 30 fps).
They always pause in Low Power Mode, when the Mac is hot, when the battery is below 20%
(you can turn that one off), and when the wallpaper is covered or the display is asleep.
Settings → Energy shows the current speed and the reason.

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
notchi theme install cool.notchitheme  # install a theme
notchi backup                          # save your whole setup in one file
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

Every push to `main` that changes `web/` deploys to production on Vercel (project root: `web`). Pull requests get a preview link.

## Licence

App: GPL-3.0. Plugin SDK: MIT. Built-in themes and assets: CC BY 4.0.
