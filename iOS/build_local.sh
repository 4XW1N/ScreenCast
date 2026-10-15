#!/bin/bash
# Local iOS IPA Build Script
# Run this on your Mac to build the IPA locally

set -e

# Configuration
CONFIGURATION="Release"
EXPORT_METHOD="ad-hoc"  # Options: app-store, ad-hoc, enterprise, development
SCHEME="ScreenCast"
BUNDLE_ID="com.screencast.receiver"
DEVELOPMENT_TEAM=""  # Your Team ID (optional for ad-hoc)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== ScreenCast iOS IPA Builder ===${NC}"
echo ""

# Check Xcode
echo -e "${YELLOW}Checking Xcode...${NC}"
xcodebuild -version

# Navigate to iOS directory
cd "$(dirname "$0")"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf ./build

# Resolve dependencies
echo -e "${YELLOW}Resolving Swift Package dependencies...${NC}"
xcodebuild -resolvePackageDependencies \
  -scheme $SCHEME \
  -destination 'generic/platform=iOS' \
  -clonedSourcePackagesDirPath ./Packages

# Create ExportOptions.plist
echo -e "${YELLOW}Creating ExportOptions.plist...${NC}"
cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$EXPORT_METHOD</string>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>$DEVELOPMENT_TEAM</string>
    <key>thinning</key>
    <string><none></string>
</dict>
</plist>
EOF

# Build and Archive
echo -e "${YELLOW}Building and Archiving...${NC}"
xcodebuild clean archive \
  -scheme $SCHEME \
  -configuration $CONFIGURATION \
  -destination 'generic/platform=iOS' \
  -archivePath ./build/$SCHEME.xcarchive \
  -clonedSourcePackagesDirPath ./Packages \
  -derivedDataPath ./build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

# Export IPA
echo -e "${YELLOW}Exporting IPA...${NC}"
xcodebuild -exportArchive \
  -archivePath ./build/$SCHEME.xcarchive \
  -exportPath ./build/ipa \
  -exportOptionsPlist ExportOptions.plist

# Verify
IPA_PATH=$(find ./build/ipa -name "*.ipa" | head -1)
if [ -f "$IPA_PATH" ]; then
  echo -e "${GREEN}=== BUILD SUCCESSFUL ===${NC}"
  echo -e "IPA location: $IPA_PATH"
  echo -e "IPA size: $(du -h "$IPA_PATH" | cut -f1)"
  echo ""
  echo -e "${YELLOW}To install on device:${NC}"
  echo "  1. Connect iPad via USB"
  echo "  2. Open Finder → select iPad"
  echo "  3. Drag $IPA_PATH to the device"
  echo ""
  echo -e "${YELLOW}Or use Apple Configurator 2:${NC}"
  echo "  cfgutil install-app --path $IPA_PATH"
else
  echo -e "${RED}=== BUILD FAILED ===${NC}"
  echo "No IPA found in ./build/ipa/"
  exit 1
fi