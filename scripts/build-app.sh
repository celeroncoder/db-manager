#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="DB Manager"
BUNDLE_NAME="DB Manager.app"
BUILD_DIR="$ROOT_DIR/.build/app"

echo "Building DBManager (release)..."
swift build -c release --package-path "$ROOT_DIR"

echo "Assembling $BUNDLE_NAME..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUILD_DIR/$BUNDLE_NAME/Contents/Resources"

# Copy binary
cp "$ROOT_DIR/.build/release/DBManager" "$BUILD_DIR/$BUNDLE_NAME/Contents/MacOS/DBManager"
chmod +x "$BUILD_DIR/$BUNDLE_NAME/Contents/MacOS/DBManager"

# Copy Info.plist
cp "$ROOT_DIR/DBManager/Info.plist" "$BUILD_DIR/$BUNDLE_NAME/Contents/Info.plist"

# Copy icon
cp "$ROOT_DIR/DBManager/AppIcon.icns" "$BUILD_DIR/$BUNDLE_NAME/Contents/Resources/AppIcon.icns"

echo ""
echo "Built: $BUILD_DIR/$BUNDLE_NAME"
echo ""
echo "To install:"
echo "  cp -r \"$BUILD_DIR/$BUNDLE_NAME\" /Applications/"
echo ""
echo "Or open directly:"
echo "  open \"$BUILD_DIR/$BUNDLE_NAME\""
