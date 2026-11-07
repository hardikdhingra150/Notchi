#!/bin/zsh
# Creates a local code-signing identity for development builds, once.
#
# Why: ad hoc builds get a new signature on every rebuild, and macOS ties
# Accessibility permission to the signature. So after each rebuild the
# permission silently stops applying (the switch still looks on), the
# volume/brightness key tap can't start, and the macOS HUD shows again.
# Signing every build with the same identity keeps the permission.
#
# The identity lives in its own keychain file (not your login keychain) and
# nothing is added to your trust settings. bundle.sh uses it automatically.
# Delete the folder below to remove it.
set -e
DIR="$HOME/Library/Application Support/Notchi/DevSigning"
KC="$DIR/notchi-dev.keychain-db"
NAME="Notchi Local Dev"

if [[ -f "$KC" ]]; then
  echo "Already set up: $KC"
  exit 0
fi

mkdir -p "$DIR"
chmod 700 "$DIR"
PW="$(openssl rand -hex 16)"
print -r -- "$PW" > "$DIR/password"
chmod 600 "$DIR/password"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -subj "/CN=$NAME" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null
openssl pkcs12 -export -legacy -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -name "$NAME" -out "$TMP/id.p12" -passout "pass:$PW"

security create-keychain -p "$PW" "$KC"
security set-keychain-settings "$KC"          # don't auto-lock
security unlock-keychain -p "$PW" "$KC"
security import "$TMP/id.p12" -k "$KC" -P "$PW" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple: -s -k "$PW" "$KC" >/dev/null
echo "Created \"$NAME\" in $KC"
