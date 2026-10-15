#!/bin/bash
# Generate Xcode project from Swift Package Manager
# Usage: ./generate_xcodeproj.sh

set -e

cd "$(dirname "$0")"

echo "Generating Xcode project from Package.swift..."

# Generate Xcode project
xcodebuild -createPackageProject \
  -scheme ScreenCast \
  -destination 'generic/platform=iOS' \
  -clonedSourcePackagesDirPath ./Packages \
  -derivedDataPath ./build/DerivedData

echo "Xcode project generated successfully!"
echo "Open ScreenCast.xcodeproj in Xcode"