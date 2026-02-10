#!/bin/bash

# Hogwarts iOS - TestFlight Distribution Build Script
# This script creates a signed archive ready for TestFlight distribution
# Usage: ./scripts/archive-for-testflight.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCHEME="Hogwarts"
CONFIGURATION="Release"
ARCHIVE_PATH="build/Hogwarts.xcarchive"
EXPORT_PATH="build/TestFlight"
IPA_NAME="Hogwarts-TestFlight.ipa"

echo -e "${YELLOW}🏗️  Hogwarts TestFlight Build${NC}"
echo "========================================"

# Step 1: Clean previous builds
echo -e "${YELLOW}📦 Cleaning previous builds...${NC}"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
mkdir -p "$(dirname "$ARCHIVE_PATH")"

# Step 2: Archive for App Store
echo -e "${YELLOW}🔨 Building archive...${NC}"
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    -verbose \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="Hogwarts Distribution"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}❌ Archive failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archive created successfully${NC}"

# Step 3: Export for TestFlight
echo -e "${YELLOW}📱 Exporting for TestFlight...${NC}"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "ExportOptions.plist" \
    -allowProvisioningUpdates \
    -verbose

if [ ! -f "$EXPORT_PATH/$IPA_NAME" ]; then
    echo -e "${RED}❌ Export failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ IPA exported successfully${NC}"

# Step 4: Verify the IPA
echo -e "${YELLOW}🔍 Verifying IPA...${NC}"
IPA_FILE="$EXPORT_PATH/$IPA_NAME"
IPA_SIZE=$(du -sh "$IPA_FILE" | cut -f1)

if [ -f "$IPA_FILE" ]; then
    echo -e "${GREEN}✅ IPA ready for TestFlight${NC}"
    echo "📄 File: $IPA_FILE"
    echo "📊 Size: $IPA_SIZE"
    echo ""
    echo "Next steps:"
    echo "1. Open App Store Connect (https://appstoreconnect.apple.com)"
    echo "2. Select your app and navigate to TestFlight"
    echo "3. Use Transporter or Xcode to upload the IPA"
    echo "4. Add internal testers and submit for review"
else
    echo -e "${RED}❌ IPA file not found!${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Build complete!${NC}"
