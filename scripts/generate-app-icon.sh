#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARTWORK_DIR="$ROOT_DIR/Artwork"
BUILD_DIR="$ROOT_DIR/.build/icon-work"
ICONSET_DIR="$BUILD_DIR/SpeakDock.iconset"
ICNS_PATH="$BUILD_DIR/SpeakDock.icns"
TMP_ICNS_PATH="$BUILD_DIR/SpeakDock.generated.icns"
RENDER_SCRIPT="$ROOT_DIR/scripts/render-app-icon.swift"
BASE_PNG="$BUILD_DIR/AppIcon-1024.png"
SWIFT_HOME="$ROOT_DIR/.swift-home"
SWIFT_CACHE="$ROOT_DIR/.swift-cache"
CLANG_MODULE_CACHE="$SWIFT_CACHE/clang/ModuleCache"

mkdir -p "$SWIFT_HOME" "$CLANG_MODULE_CACHE"

export HOME="$SWIFT_HOME"
export XDG_CACHE_HOME="$SWIFT_CACHE"
export CLANG_MODULE_CACHE_PATH="$CLANG_MODULE_CACHE"
export SWIFTPM_MODULECACHE_OVERRIDE="$CLANG_MODULE_CACHE"

if [[ ! -f "$ARTWORK_DIR/AppIcon.svg" ]]; then
  print -u2 -- "Missing icon artwork: $ARTWORK_DIR/AppIcon.svg"
  exit 1
fi

if [[ ! -f "$RENDER_SCRIPT" ]]; then
  print -u2 -- "Missing renderer: $RENDER_SCRIPT"
  exit 1
fi

for tool in swift sips iconutil; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    print -u2 -- "Missing required tool: $tool"
    exit 1
  fi
done

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
swift "$RENDER_SCRIPT" "$BASE_PNG" 1024 >/dev/null

make_icon() {
  local size="$1"
  local name="$2"
  sips -z "$size" "$size" "$BASE_PNG" --out "$ICONSET_DIR/$name" >/dev/null
}

make_icon 16 icon_16x16.png
make_icon 32 icon_16x16@2x.png
make_icon 32 icon_32x32.png
make_icon 64 icon_32x32@2x.png
make_icon 128 icon_128x128.png
make_icon 256 icon_128x128@2x.png
make_icon 256 icon_256x256.png
make_icon 512 icon_256x256@2x.png
make_icon 512 icon_512x512.png
make_icon 1024 icon_512x512@2x.png

rm -f "$TMP_ICNS_PATH"
if iconutil --convert icns --output "$TMP_ICNS_PATH" "$ICONSET_DIR"; then
  mv "$TMP_ICNS_PATH" "$ICNS_PATH"
else
  rm -f "$TMP_ICNS_PATH"
  print -u2 -- "warning: iconutil could not refresh SpeakDock.icns; keeping the existing bundle icon file"
fi

print -- "$ICNS_PATH"
