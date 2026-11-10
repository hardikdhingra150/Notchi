# Themes

A theme is one JSON file that every part of Notchi follows: the notch, the wallpaper and
tinted folders today, and the sidebar, dock, menu bar, sounds and cursor as they arrive.
The built-in themes here are licensed CC BY 4.0.

## Make one

```bash
notchi theme new my-theme "My Theme"   # starts from the active theme
notchi apply my-theme                  # try it
notchi theme export my-theme           # my-theme.notchitheme, ready to share
```

`theme new` creates `~/Library/Application Support/Notchi/Themes/my-theme/theme.json`.
Edit it in any editor and apply it again; no restart needed.

## The file

```json
{
  "schema": 1,
  "id": "midnight",
  "name": "Midnight",
  "author": "your-github-name",
  "version": "1.0.0",
  "appearance": "dark",
  "accent": "#8F7CFF",
  "glass": { "blur": 0.85, "tint": 0.3 },
  "wallpaper": { "type": "video", "src": "wallpapers/starfield.mp4", "fps": 30 },
  "icons": { "pack": "default", "tintFolders": true },
  "notch": { "glow": "accent", "idle": "sparks", "visualizer": true },
  "sidebar": { "widgets": ["nowPlaying", "calendar", "stats"] },
  "dock": { "style": "minimal", "magnify": 1.4 },
  "menuBar": { "tint": "accent", "opacity": 0.4 },
  "sounds": { "pack": "low-hum" },
  "cursor": { "trail": "comet" }
}
```

| Field | What it does in v0.5 |
|---|---|
| `schema` | Always `1`. |
| `id` | Lowercase letters, numbers and dashes. This is the name you type in `notchi apply`. |
| `accent` | `#RRGGBB`. The notch, progress bars and accent-tinted folders use it. |
| `notch.glow` | `"accent"`, `"none"` or a colour like `"#00FFAA"`. |
| `notch.idle` | What the closed notch does when nothing is happening: `breathing`, `sparks`, `rain`, `pet` or `none`. |
| `notch.visualizer` | `false` hides the music bars. |
| `wallpaper` | `"type": "video"` with a `src` inside the theme's folder. Applying the theme fades the desktop to it. |
| `icons.tintFolders` | `false` leaves folders alone. Otherwise folders set with `notchi icon set <folder> --tint accent` are recoloured. |
| `appearance`, `glass`, `sidebar`, `dock`, `menuBar`, `sounds`, `cursor` | Read and checked now, used by the modules coming in v1.0 and later. `wallpaper.type` `shader`, `particles` and `image` are also for later. |

`wallpaper`, `icons`, `sidebar`, `dock`, `menuBar`, `sounds` and `cursor` can be left out.
Fields Notchi doesn't know are ignored, so a theme made for a newer version still loads.

## Where files go

A theme is a folder. Paths in the JSON start at that folder and can't leave it.

```
my-theme/
  theme.json
  wallpapers/night.mp4
```

A `.notchitheme` is that folder zipped. Double-click it, or run
`notchi theme install my-theme.notchitheme`. A single `.json` also installs; if its
video sits next to it at the path in `src`, the video is copied too.

Before Notchi unpacks a `.notchitheme` it checks that nothing in it points outside the
package and that it isn't over 500 MB. Themes are data only: they can't run code.

Check a file without installing it:

```bash
notchi theme validate my-theme.notchitheme
```

## Built-in themes

The five themes in this folder ship inside the app. Their videos come from the website's
wallpaper library (`web/public/wallpapers`); `scripts/bundle.sh` copies them in.
To add one, copy a file, change `id`, `name`, `author` and the values, and open a pull request.
