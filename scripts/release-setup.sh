#!/bin/zsh
# One-time setup for public releases. Free; no Apple Developer account needed.
#
# Creates two things on this Mac (skipping whatever already exists):
#   1. A Sparkle update key. Every update is signed with it, and the app only
#      installs updates whose signature matches. Lives in your login keychain
#      (account "notchi") with a copy in the folder below.
#   2. A self-signed code-signing certificate ("Notchi Self-Signed"), so every
#      release has the same signature and macOS keeps the permissions people
#      granted (Accessibility) across updates.
# Then stores them as GitHub Actions secrets for .github/workflows/release.yml.
#
# BACK UP THE FOLDER BELOW. If the update key is lost, people on older versions
# can never be auto-updated again; they'd have to download a new build by hand.
set -e
cd "$(dirname "$0")/.."
DIR="$HOME/Library/Application Support/Notchi/ReleaseSigning"
NAME="Notchi Self-Signed"
BIN=".build/artifacts/sparkle/Sparkle/bin"
umask 077
mkdir -p "$DIR" && chmod 700 "$DIR"

[[ -x "$BIN/generate_keys" ]] || swift package resolve
[[ -x "$BIN/generate_keys" ]] || { echo "Sparkle's tools aren't in $BIN. Run: swift build"; exit 1; }

# 1. update key
"$BIN/generate_keys" --account notchi >/dev/null
if [[ ! -f "$DIR/sparkle-private.key" ]]; then
  "$BIN/generate_keys" --account notchi -x "$DIR/sparkle-private.key" >/dev/null
fi
PUBLIC="$("$BIN/generate_keys" --account notchi -p)"

# 2. signing certificate
if [[ ! -f "$DIR/notchi.p12" ]]; then
  print -r -- "$(openssl rand -hex 16)" > "$DIR/p12-password"
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$DIR/key.pem" -out "$DIR/cert.pem" -subj "/CN=$NAME" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null
  openssl pkcs12 -export -legacy -inkey "$DIR/key.pem" -in "$DIR/cert.pem" \
    -name "$NAME" -out "$DIR/notchi.p12" -passout "pass:$(cat "$DIR/p12-password")"
  rm -f "$DIR/key.pem"
fi
chmod 600 "$DIR"/*

# 3. GitHub. Values go to gh on stdin, so they never show up in a process list or on screen.
gh variable set NOTCHI_ED_PUBLIC_KEY --body "$PUBLIC"
printf '%s' "$(cat "$DIR/sparkle-private.key")" | gh secret set SPARKLE_ED_PRIVATE_KEY
base64 -i "$DIR/notchi.p12" | tr -d '\n' | gh secret set NOTCHI_CERT_P12
printf '%s' "$(cat "$DIR/p12-password")" | gh secret set NOTCHI_CERT_PASSWORD
printf '%s' "$NAME" | gh secret set NOTCHI_SIGN_ID

echo
echo "Done. The next tag you push builds a release that is signed and can update itself."
echo "Keys are in: $DIR"
echo "Back that folder up somewhere safe (a password manager or an encrypted drive)."
