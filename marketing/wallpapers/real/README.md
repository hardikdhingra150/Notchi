# Real-footage wallpapers

The "Earth from Orbit" and "National Parks" collections are real video in the public
domain, cut into seamless loops. Nothing here is taken from wallpaper or stock sites.

`make.sh` rebuilds every file in `web/public/wallpapers` from the sources below.
`clip.swift` does the work with AVFoundation, so no ffmpeg is needed. For each clip it
writes `<id>.mp4` (1080p), `<id>-preview.mp4` (640x360) and `<id>.jpg`. The loop is
seamless because the footage that follows the clip is faded out over the clip's first
seconds. Sound is dropped.

## Sources

### NASA: 4K Earth Views, Extended Cut for Earth Day 2021
- Filmed from the International Space Station in 2019 and 2020. NASA Johnson Space Center.
- Library page: https://images.nasa.gov/details/jsc2021m000138_4K_Earth_Views_Extended_Cut_for_Earth_Day_%202021_210422-4KMP4
- NASA footage is generally not copyrighted and may be used freely, without implying that
  NASA endorses anything: https://www.nasa.gov/nasa-brand-center/images-and-media/
- Cut from the 1080p "large" file, read over the network (it is 2 GB and isn't downloaded).

| Wallpaper | Starts at | Length |
|---|---|---|
| earth-blue-limb | 1:02 | 20 s |
| earth-desert-coast | 3:06 | 20 s |
| earth-deep-blue | 9:48 | 20 s |
| earth-cloud-fields | 12:06 | 20 s |
| earth-lagoon | 14:12 | 20 s |
| earth-cloud-deck | 18:32 | 20 s |
| earth-desert-ridges | 22:06 | 20 s |
| earth-turquoise-bay | 25:42 | 20 s |
| earth-thunderheads | 28:12 | 20 s |
| earth-from-station | 30:32 | 20 s |
| earth-fair-weather | 40:22 | 20 s |
| earth-snow-range | 48:32 | 20 s |

### U.S. National Park Service: NPGallery b-roll
Each asset is marked "Public domain, Full granting rights" on its NPGallery page. The
NPS asks that its footage isn't used to suggest it endorses a product.

| Wallpaper | NPGallery asset | Starts at | Length |
|---|---|---|---|
| park-cherry-blossom | [Cherry Blossom B-Roll](https://npgallery.nps.gov/AssetDetail/ee24d71b-150d-4238-90b3-d3a1002b2fda) | 1:17 | 14 s |
| park-white-blossom | same | 2:27.5 | 8 s |
| park-misty-falls | [Great Falls Park B-Roll](https://npgallery.nps.gov/AssetDetail/897aff45-ed8f-4d1a-97a5-550922629410) | 0:52 | 13 s |
| park-autumn-falls | same | 1:12.5 | 8 s |
| park-river-gorge | same | 0:39.5 | 7 s |
| park-winter-dunes | [B-Roll Video Indiana Dunes National Park](https://npgallery.nps.gov/AssetDetail/36a6afbe-1537-468f-8876-7f3ce7cbc4d0) | 0:00.3 | 8 s |

## Adding one
1. Find footage whose licence allows redistribution (public domain or CC0 is simplest) and
   note where it says so.
2. Look through it: `swift clip.swift frames <file-or-url> 5 /tmp/frames`
3. Pick a stretch with no cut in it and add a line to `make.sh`.
4. Add the wallpaper, with its credit, to `web/lib/wallpapers.ts` and to the tables above.
