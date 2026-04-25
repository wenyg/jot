#!/usr/bin/env bash
# Local one-shot build: produces a Universal Jot.app and a zip ready for sharing.
#
# Usage:
#   ./scripts/build.sh           # builds Release, output -> ./dist/
#   ./scripts/build.sh debug     # builds Debug (host arch only, faster)

set -euo pipefail

CONFIG="${1:-Release}"
case "$CONFIG" in
  release|Release) CONFIG=Release ;;
  debug|Debug)     CONFIG=Debug   ;;
  *)
    echo "Unknown configuration: $CONFIG (expected 'release' or 'debug')" >&2
    exit 1
    ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Tooling check
command -v xcodegen >/dev/null 2>&1 || {
  echo "xcodegen not found. Install with: brew install xcodegen" >&2
  exit 1
}

echo "==> Generating Xcode project"
xcodegen generate

DERIVED="$ROOT/.build/derived"
DIST="$ROOT/dist"
rm -rf "$DIST"
mkdir -p "$DIST"

echo "==> Building $CONFIG"
ARCHS_ARG=()
if [ "$CONFIG" = "Release" ]; then
  ARCHS_ARG=(ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO)
fi

xcodebuild \
  -project Dogbody.xcodeproj \
  -scheme Dogbody \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  "${ARCHS_ARG[@]}" \
  build

SRC_APP="$DERIVED/Build/Products/$CONFIG/Dogbody.app"
if [ ! -d "$SRC_APP" ]; then
  echo "Build did not produce $SRC_APP" >&2
  exit 1
fi

cp -R "$SRC_APP" "$DIST/Jot.app"
codesign --force --deep --sign - "$DIST/Jot.app"
codesign --verify --deep --strict --verbose=2 "$DIST/Jot.app"

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$DIST/Jot.app/Contents/Info.plist")
ZIP_NAME="Jot-v${VERSION}-macOS-universal.zip"
[ "$CONFIG" = "Debug" ] && ZIP_NAME="Jot-v${VERSION}-macOS-debug.zip"

(cd "$DIST" && ditto -c -k --sequesterRsrc --keepParent "Jot.app" "$ZIP_NAME")
(cd "$DIST" && shasum -a 256 "$ZIP_NAME" | tee "$ZIP_NAME.sha256")

echo
echo "==> Done"
echo "    App:  $DIST/Jot.app"
echo "    Zip:  $DIST/$ZIP_NAME"
echo
file "$DIST/Jot.app/Contents/MacOS/Dogbody"
lipo -archs "$DIST/Jot.app/Contents/MacOS/Dogbody" || true
