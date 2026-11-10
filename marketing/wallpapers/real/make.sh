#!/bin/zsh
# Rebuilds the real-footage wallpapers in web/public/wallpapers. See README.md for sources.
set -e
cd "$(dirname "$0")"
OUT="../../../web/public/wallpapers"
WORK="${TMPDIR:-/tmp}/notchi-real-footage"
mkdir -p "$WORK"
swiftc -O -o "$WORK/clip" clip.swift

NASA="https://images-assets.nasa.gov/video/jsc2021m000138_4K_Earth_Views_Extended_Cut_for_Earth_Day_%202021_210422-4KMP4/jsc2021m000138_4K_Earth_Views_Extended_Cut_for_Earth_Day_%202021_210422-4KMP4~large.mp4"
while read -r id start; do
  "$WORK/clip" loop "$NASA" "$start" 20 "$OUT/$id" --fade 2.5 --bitrate 3000000 --zoom 1.08
done <<LIST
earth-blue-limb 62
earth-desert-coast 186
earth-deep-blue 588
earth-cloud-fields 726
earth-lagoon 852
earth-cloud-deck 1112
earth-desert-ridges 1326
earth-turquoise-bay 1542
earth-thunderheads 1692
earth-from-station 1832
earth-fair-weather 2422
earth-snow-range 2912
LIST

nps() { [[ -f "$WORK/$1.mp4" ]] || curl -sL -o "$WORK/$1.mp4" "https://npgallery.nps.gov/GetAsset/$2/compressed"; }
nps cherry ee24d71b-150d-4238-90b3-d3a1002b2fda
nps greatfalls 897aff45-ed8f-4d1a-97a5-550922629410
nps dunes 36a6afbe-1537-468f-8876-7f3ce7cbc4d0
while read -r id src start len fade; do
  "$WORK/clip" loop "$WORK/$src.mp4" "$start" "$len" "$OUT/$id" --fade "$fade" --bitrate 3000000
done <<LIST
park-cherry-blossom cherry 77 14 2
park-white-blossom cherry 147.5 8 1.5
park-misty-falls greatfalls 52 13 2
park-autumn-falls greatfalls 72.5 8 1.5
park-river-gorge greatfalls 39.5 7 1.5
park-winter-dunes dunes 0.3 8 1.5
LIST
