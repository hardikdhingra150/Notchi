#!/bin/zsh
# Builds dist/Notchi.app and dist/notchi (the CLI).
# Signing: set NOTCHI_SIGN_ID to your self-signed certificate's name to keep
# permissions across updates (blueprint section 13). Without it, signs ad hoc.
set -e
cd "$(dirname "$0")/.."
CONFIG="${CONFIG:-release}"
VERSION="${VERSION:-0.1.0}"
BUILD="${BUILD:-1}"
# ARCHS="arm64 x86_64" builds a universal app (needs Xcode); default is this Mac's arch.
ARCH_FLAGS=()
for a in ${=ARCHS:-}; do ARCH_FLAGS+=(--arch "$a"); done
swift build -c "$CONFIG" "${ARCH_FLAGS[@]}" --product NotchiApp
swift build -c "$CONFIG" "${ARCH_FLAGS[@]}" --product notchi
BIN="$(swift build -c "$CONFIG" "${ARCH_FLAGS[@]}" --show-bin-path)"

APP=dist/Notchi.app
rm -rf "$APP" && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Helpers" "$APP/Contents/Frameworks"
cp "$BIN/NotchiApp" "$APP/Contents/MacOS/Notchi"
cp Themes/*.json "$APP/Contents/Resources/" 2>/dev/null || true
mkdir -p "$APP/Contents/Resources/Themes" && mv "$APP"/Contents/Resources/*.json "$APP/Contents/Resources/Themes/"
cp "$BIN/notchi" dist/notchi
# the CLI ships inside the app too (Helpers/, since MacOS/ already has "Notchi" and the disk is case-insensitive)
cp "$BIN/notchi" "$APP/Contents/Helpers/notchi"
# Sparkle (auto-updates)
SPARKLE="$(find "$BIN" .build/artifacts -name Sparkle.framework -type d -prune 2>/dev/null | grep -v dSYM | head -1)"
[[ -n "$SPARKLE" ]] && ditto "$SPARKLE" "$APP/Contents/Frameworks/Sparkle.framework"
# system-wide Now Playing helper: loaded into /usr/bin/perl (see Helpers/MediaRemoteBridge)
MR_ARCHS=()
for a in ${=ARCHS:-$(uname -m)}; do MR_ARCHS+=(-arch "$a"); done
clang -dynamiclib -fobjc-arc -O2 "${MR_ARCHS[@]}" -mmacosx-version-min=14.0 -framework Foundation \
  Helpers/MediaRemoteBridge/MediaRemoteBridge.m -o "$APP/Contents/Resources/MediaRemoteBridge.dylib"
cp Helpers/MediaRemoteBridge/notchi-nowplaying.pl "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Notchi</string>
  <key>CFBundleDisplayName</key><string>Notchi</string>
  <key>CFBundleIdentifier</key><string>app.notchi.Notchi</string>
  <key>CFBundleExecutable</key><string>Notchi</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$BUILD</string>
  <key>SUFeedURL</key><string>${NOTCHI_FEED_URL:-https://github.com/hardikdhingra150/Notchi/releases/latest/download/appcast.xml}</string>
  <key>SUPublicEDKey</key><string>${NOTCHI_ED_PUBLIC_KEY:-}</string>
  <key>SUEnableAutomaticChecks</key><true/>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSAppleEventsUsageDescription</key><string>Notchi shows what's playing in Music or Spotify and lets you control it from the notch.</string>
  <key>NSHumanReadableCopyright</key><string>Free and open source under GPL-3.0.</string>
</dict></plist>
PLIST

SIGN="${NOTCHI_SIGN_ID:--}"
# Hardened runtime turns on library validation, which only accepts frameworks
# signed by the same Apple Team ID. Ad hoc and self-signed builds have no team,
# so the embedded Sparkle.framework would be rejected at launch. Only opt in
# when signing with a real Developer ID (NOTCHI_HARDENED=1).
RUNTIME=()
[[ "${NOTCHI_HARDENED:-0}" == "1" ]] && RUNTIME=(--options runtime)
codesign --force "${RUNTIME[@]}" --sign "$SIGN" "$APP/Contents/Helpers/notchi"
codesign --force --sign "$SIGN" "$APP/Contents/Resources/MediaRemoteBridge.dylib"
if [[ -d "$APP/Contents/Frameworks/Sparkle.framework" ]]; then
  codesign --force --deep "${RUNTIME[@]}" --sign "$SIGN" "$APP/Contents/Frameworks/Sparkle.framework"
fi
codesign --force "${RUNTIME[@]}" --sign "$SIGN" "$APP"
codesign --force --sign "$SIGN" dist/notchi
echo "Built $APP and dist/notchi (signed with: ${NOTCHI_SIGN_ID:-ad hoc})"
