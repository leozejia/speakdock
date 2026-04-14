#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
APP_DIR="$ROOT_DIR/.build/$CONFIGURATION/SpeakDock.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SWIFT_HOME="$ROOT_DIR/.swift-home"
SWIFT_CACHE="$ROOT_DIR/.swift-cache"
CLANG_MODULE_CACHE="$SWIFT_CACHE/clang/ModuleCache"

mkdir -p "$SWIFT_HOME" "$CLANG_MODULE_CACHE"

export HOME="$SWIFT_HOME"
export XDG_CACHE_HOME="$SWIFT_CACHE"
export CLANG_MODULE_CACHE_PATH="$CLANG_MODULE_CACHE"
export SWIFTPM_MODULECACHE_OVERRIDE="$CLANG_MODULE_CACHE"

print -u2 -- "Building SpeakDockMac ($CONFIGURATION)..."
swift build --package-path "$ROOT_DIR" -c "$CONFIGURATION" --product SpeakDockMac >&2

BUILD_BIN_DIR="$(swift build --package-path "$ROOT_DIR" -c "$CONFIGURATION" --show-bin-path 2>/dev/null)"
EXECUTABLE_PATH="$BUILD_BIN_DIR/SpeakDockMac"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/Sources/SpeakDockMac/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$EXECUTABLE_PATH" "$MACOS_DIR/SpeakDock"

if command -v codesign >/dev/null 2>&1; then
  BUNDLE_IDENTIFIER="$(plutil -extract CFBundleIdentifier raw -o - "$CONTENTS_DIR/Info.plist")"
  DESIGNATED_REQUIREMENT="=designated => identifier \"$BUNDLE_IDENTIFIER\""
  codesign --force --deep --sign - --requirements "$DESIGNATED_REQUIREMENT" "$APP_DIR" >/dev/null 2>&1 || true
fi

print -u2 -- "App bundle ready: $APP_DIR"
print -- "$APP_DIR"
