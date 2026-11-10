#!/bin/zsh
# Makes dist/Notchi-<version>.dmg from dist/Notchi.app: the usual window with the app
# and a shortcut to Applications, so installing is one drag. Run scripts/bundle.sh first.
set -e
cd "$(dirname "$0")/.."
APP=dist/Notchi.app
[[ -d "$APP" ]] || { echo "No $APP. Run ./scripts/bundle.sh first." >&2; exit 1; }
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")}"
OUT="dist/Notchi-$VERSION.dmg"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

ditto "$APP" "$STAGE/Notchi.app"
ln -s /Applications "$STAGE/Applications"
cat > "$STAGE/Read me first.txt" <<TXT
Installing Notchi

1. Drag Notchi onto the Applications folder in this window.
2. Open Notchi from Applications.
3. macOS will say it can't verify the app. That's because Notchi is free and
   isn't signed with a paid Apple certificate. Open System Settings, go to
   Privacy & Security, scroll down and click "Open Anyway". You do this once.

Notchi then lives in your menu bar and at the notch. Hover the notch to open it.

Help and source code: https://github.com/hardikdhingra150/Notchi
TXT

rm -f "$OUT"
hdiutil create -volname "Notchi $VERSION" -srcfolder "$STAGE" -fs HFS+ -format UDZO -imagekey zlib-level=9 -ov "$OUT" >/dev/null
# sign the image itself with the same identity as the app, when there is one
SIGN="${NOTCHI_SIGN_ID:-}"
if [[ -n "$SIGN" ]]; then
  HASH="$(security find-identity -p codesigning | awk -v n="\"$SIGN\"" 'index($0, n) { print $2; exit }')"
  if [[ -n "$HASH" ]]; then codesign --force --sign "$HASH" "$OUT"; fi
fi
echo "Built $OUT"
