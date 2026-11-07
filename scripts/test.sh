#!/bin/zsh
# Runs the Swift tests. With only the Command Line Tools (no Xcode), Swift Testing's
# macro plugin isn't on the default search path, so point the compiler at it.
set -e
cd "$(dirname "$0")/.."
PLUGINS="$(xcode-select -p)/usr/lib/swift/host/plugins/testing"
if [[ -d "$PLUGINS" ]]; then
  swift test -Xswiftc -plugin-path -Xswiftc "$PLUGINS" "$@"
else
  swift test "$@"
fi
