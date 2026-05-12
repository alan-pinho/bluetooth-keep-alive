#!/usr/bin/env bash
#
# Build BluetoothKeepAlive Release as a universal binary (arm64 + x86_64) and
# package it as a .dmg with a drag-to-Applications shortcut.
#
# Output: <repo-root>/dist/BluetoothKeepAlive-<version>.dmg
#
# Usage: ./scripts/make-dmg.sh
#
# Notes:
#   - Signing uses whatever identity is configured in the Xcode project (today:
#     Apple Development). Recipients on a different Mac will need to right-click
#     -> Open the first time, or run:
#       xattr -d com.apple.quarantine /Applications/BluetoothKeepAlive.app
#   - For wider distribution (no Gatekeeper warning), switch to a Developer ID
#     identity and add a notarytool submit + stapler staple step.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
PROJECT="$REPO_ROOT/BluetoothKeepAlive/BluetoothKeepAlive.xcodeproj"
SCHEME="BluetoothKeepAlive"
BUILD_DIR=$(mktemp -d -t bluetooth-keep-alive-build)
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "==> Building Release (universal arm64 + x86_64)"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    clean build \
    >/dev/null

APP="$BUILD_DIR/Build/Products/Release/BluetoothKeepAlive.app"
if [[ ! -d "$APP" ]]; then
    echo "Build did not produce expected .app at $APP" >&2
    exit 1
fi

echo "==> Verifying architectures"
EXEC="$APP/Contents/MacOS/BluetoothKeepAlive"
ARCHES=$(lipo -archs "$EXEC" 2>/dev/null || echo "")
echo "    $ARCHES"
if [[ "$ARCHES" != *"arm64"* ]] || [[ "$ARCHES" != *"x86_64"* ]]; then
    echo "Expected universal binary, got: $ARCHES" >&2
    exit 1
fi

# Xcode signs with the Apple Development provisioning profile, which injects
# entitlements we don't want in a distribution build (get-task-allow lets a
# debugger attach; network.client is unused). Re-sign the main bundle with
# ONLY the entitlements declared in BluetoothKeepAliveRelease.entitlements.
# Embedded frameworks keep their existing signatures (they don't carry these
# entitlements anyway).
echo "==> Re-signing main bundle with explicit Release entitlements"
RELEASE_ENTITLEMENTS="$REPO_ROOT/BluetoothKeepAlive/BluetoothKeepAlive/BluetoothKeepAliveRelease.entitlements"
SIGN_INFO=$(codesign -dv --verbose=2 "$APP" 2>&1)
IDENTITY=""
while IFS= read -r line; do
    if [[ "$line" == Authority=Apple\ Development* ]]; then
        IDENTITY="${line#Authority=}"
        break
    fi
done <<< "$SIGN_INFO"
if [[ -z "$IDENTITY" ]]; then
    echo "Could not detect Apple Development signing identity on $APP" >&2
    exit 1
fi
codesign --force --options runtime --sign "$IDENTITY" \
    --entitlements "$RELEASE_ENTITLEMENTS" \
    "$APP"

echo "==> Verifying re-sign"
codesign --verify --deep --strict "$APP"
REMAINING=$(codesign -d --entitlements :- "$APP" 2>/dev/null | \
    grep -oE 'com\.apple\.security\.(get-task-allow|network\.client)' || true)
if [[ -n "$REMAINING" ]]; then
    echo "Unexpected entitlements still present: $REMAINING" >&2
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist" 2>/dev/null || echo "0.0")
DIST_DIR="$REPO_ROOT/dist"
DMG_OUT="$DIST_DIR/BluetoothKeepAlive-${VERSION}.dmg"
STAGE="$BUILD_DIR/dmg-stage"

mkdir -p "$DIST_DIR" "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "==> Creating $DMG_OUT"
rm -f "$DMG_OUT"
hdiutil create \
    -volname "Bluetooth Keep Alive" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    "$DMG_OUT" \
    >/dev/null

SIZE=$(ls -lh "$DMG_OUT" | awk '{print $5}')
echo "==> Done: $DMG_OUT ($SIZE)"
