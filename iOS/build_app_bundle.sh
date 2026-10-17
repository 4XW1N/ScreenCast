#!/bin/bash
# Build iOS app bundle and IPA from SwiftPM output
set -e

CONFIGURATION="${1:-Release}"
IOS_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$IOS_DIR"

echo "=== Step 1: Build with xcodebuild (iOS device) ==="
xcodebuild build \
  -scheme ScreenCast \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$IOS_DIR/build/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

echo ""
echo "=== Step 2: Find built binary ==="
BINARY=$(find build/DerivedData -name "ScreenCast" -type f -executable | head -1)
if [ -z "$BINARY" ]; then
  echo "ERROR: Binary not found in DerivedData!"
  find build/DerivedData -type f -executable 2>/dev/null | head -20
  exit 1
fi
echo "Found binary: $BINARY"

echo ""
echo "=== Step 3: Verify binary architecture ==="
lipo -info "$BINARY"

echo ""
echo "=== Step 4: Create iOS app bundle ==="
APP_DIR="$IOS_DIR/build/ScreenCast.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/_CodeSignature"

# Copy binary
cp "$BINARY" "$APP_DIR/ScreenCast"
chmod +x "$APP_DIR/ScreenCast"

# Copy Info.plist from source
cp "$IOS_DIR/Sources/ScreenCast/Info.plist" "$APP_DIR/Info.plist"

# Create PkgInfo
echo "APPL????" > "$APP_DIR/PkgInfo"

echo "--- App bundle contents ---"
ls -la "$APP_DIR"

echo ""
echo "=== Step 5: Package IPA ==="
rm -rf "$IOS_DIR/build/ipa"
mkdir -p "$IOS_DIR/build/ipa/Payload"
cp -R "$APP_DIR" "$IOS_DIR/build/ipa/Payload/"
cd "$IOS_DIR/build/ipa"
zip -qr "$IOS_DIR/build/ScreenCast.ipa" Payload
echo "IPA created:"
unzip -l "$IOS_DIR/build/ScreenCast.ipa" | head -25
ls -la "$IOS_DIR/build/ScreenCast.ipa"

echo ""
echo "=== BUILD COMPLETE ==="
echo "IPA: $IOS_DIR/build/ScreenCast.ipa"
