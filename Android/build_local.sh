#!/bin/bash
# Local Android APK/AAB Build Script

set -e

# Configuration
BUILD_TYPE="Release"  # Debug or Release
OUTPUT_DIR="./build/outputs"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== ScreenCast Android Builder ===${NC}"
echo ""

cd "$(dirname "$0")"

# Check for gradlew
if [ ! -f "./gradlew" ]; then
    echo -e "${RED}gradlew not found!${NC}"
    exit 1
fi

chmod +x ./gradlew

# Clean
echo -e "${YELLOW}Cleaning...${NC}"
./gradlew clean

# Build
if [ "$BUILD_TYPE" = "Release" ]; then
    echo -e "${YELLOW}Building Release APK...${NC}"
    ./gradlew assembleRelease
    
    echo -e "${YELLOW}Building Release AAB (for Play Store)...${NC}"
    ./gradlew bundleRelease
    
    APK_PATH=$(find ./app/build/outputs/apk/release -name "*.apk" | head -1)
    AAB_PATH=$(find ./app/build/outputs/bundle/release -name "*.aab" | head -1)
else
    echo -e "${YELLOW}Building Debug APK...${NC}"
    ./gradlew assembleDebug
    
    APK_PATH=$(find ./app/build/outputs/apk/debug -name "*.apk" | head -1)
fi

# Verify
if [ -f "$APK_PATH" ]; then
    echo -e "${GREEN}=== BUILD SUCCESSFUL ===${NC}"
    echo -e "APK: $APK_PATH"
    echo -e "Size: $(du -h "$APK_PATH" | cut -f1)"
    
    if [ -n "$AAB_PATH" ] && [ -f "$AAB_PATH" ]; then
        echo -e "AAB: $AAB_PATH"
        echo -e "Size: $(du -h "$AAB_PATH" | cut -f1)"
    fi
    
    echo ""
    echo -e "${YELLOW}To install on device:${NC}"
    echo "  adb install -r $APK_PATH"
else
    echo -e "${RED}=== BUILD FAILED ===${NC}"
    exit 1
fi