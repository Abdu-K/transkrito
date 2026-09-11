#!/usr/bin/env bash
# Builds Transkrito.app from the SwiftPM package (no Xcode project needed).
#   cd macos && ./scripts/make-app.sh            # release build → build/Transkrito.app
#   ./scripts/make-app.sh --install              # also copies to /Applications
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG=release
swift build -c "$CONFIG" 2>&1 | tail -3
BIN=".build/$CONFIG/Transkrito"
BUNDLE_RES=".build/$CONFIG/Transkrito_Transkrito.bundle"
APP="build/Transkrito.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Transkrito"
cp Info.plist "$APP/Contents/Info.plist"
[ -d "$BUNDLE_RES" ] && cp -R "$BUNDLE_RES" "$APP/Contents/Resources/"

# App icon: PNG → .icns via iconutil
ICONSET="build/AppIcon.iconset"
rm -rf "$ICONSET"; mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s Assets/AppIcon.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) Assets/AppIcon.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc signature so TCC (microphone, speech) remembers the grant across launches.
codesign --force --deep --sign - --entitlements Transkrito.entitlements "$APP"
echo "built $APP"

if [[ "${1:-}" == "--install" ]]; then
  rm -rf "/Applications/Transkrito.app"
  cp -R "$APP" /Applications/
  echo "installed to /Applications/Transkrito.app"
fi
