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
BINARY=$(find build/DerivedData -name "ScreenCast" -type f -perm -111 | head -1)
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

# Write Info.plist with literal values (no build variables)
cat > "$APP_DIR/Info.plist" << 'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ScreenCast</string>
    <key>CFBundleDisplayName</key>
    <string>ScreenCast</string>
    <key>CFBundleIdentifier</key>
    <string>com.screencast.receiver</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ScreenCast</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.2</string>
    <key>CFBundleVersion</key>
    <string>5</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
    <key>UIRequiresFullScreen</key>
    <true/>
</dict>
</plist>
PLISTEOF

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
