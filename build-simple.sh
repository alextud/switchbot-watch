#!/bin/bash

set -e

PROJECT_DIR="$(pwd)"
ARCHIVE_PATH="$PROJECT_DIR/build/Switchbot.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/ipa"

mkdir -p "$EXPORT_PATH"

echo "🔨 Building SwitchBot Watch for AltStore PAL..."
echo ""

# Build with Release configuration
echo "📦 Archiving (this may take 2-3 minutes)..."
xcodebuild \
  -project "$PROJECT_DIR/Switchbot.xcodeproj" \
  -scheme "Switchbot WatchKit App" \
  -destination "generic/platform=watchOS" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  clean archive

if [ ! -d "$ARCHIVE_PATH" ]; then
  echo "❌ Archive failed"
  exit 1
fi

echo "✅ Archive successful"
echo ""

echo "📤 Exporting to IPA..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "ExportOptions-AltStore.plist"

if [ $? -ne 0 ]; then
  echo "❌ Export failed"
  exit 1
fi

IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" -type f | head -1)

if [ -z "$IPA_FILE" ]; then
  echo "❌ No IPA found"
  exit 1
fi

echo "✅ IPA created: $IPA_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Build Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Ready to upload to GitHub!"
echo ""
