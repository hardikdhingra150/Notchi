#!/bin/zsh
# Builds dist/Notchi.app and dist/notchi (the CLI).
# Signing: set NOTCHI_SIGN_ID to your self-signed certificate's name to keep
# permissions across updates (blueprint section 13). Without it, signs ad hoc.
set -e
cd "$(dirname "$0")/.."
CONFIG="${CONFIG:-release}"
VERSION="${VERSION:-0.1.0}"
swift build -c "$CONFIG" --product NotchiApp
swift build -c "$CONFIG" --product notchi
BIN="$(swift build -c "$CONFIG" --show-bin-path)"

APP=dist/Notchi.app
rm -rf "$APP" && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/NotchiApp" "$APP/Contents/MacOS/Notchi"
cp Themes/*.json "$APP/Contents/Resources/" 2>/dev/null || true
mkdir -p "$APP/Contents/Resources/Themes" && mv "$APP"/Contents/Resources/*.json "$APP/Contents/Resources/Themes/"
cp "$BIN/notchi" dist/notchi

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
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSAppleEventsUsageDescription</key><string>Notchi shows what's playing in Music or Spotify and lets you control it from the notch.</string>
  <key>NSHumanReadableCopyright</key><string>Free and open source under GPL-3.0.</string>
</dict></plist>
PLIST

SIGN="${NOTCHI_SIGN_ID:--}"
codesign --force --deep --options runtime --sign "$SIGN" "$APP" >/dev/null 2>&1 || codesign --force --deep --sign "$SIGN" "$APP"
codesign --force --sign "$SIGN" dist/notchi
echo "Built $APP and dist/notchi (signed with: ${NOTCHI_SIGN_ID:-ad hoc})"
