#!/bin/bash

set -e  # Exit on error

# ------------------------------------------
# Configuration
# ------------------------------------------
PROJECT_DIR="$(pwd)"
ARCHIVE_PATH="$PROJECT_DIR/build/Switchbot.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/ipa"
EXPORT_OPTIONS_PLIST="$PROJECT_DIR/ExportOptions-AltStore.plist"
LOG_PATH="$PROJECT_DIR/build/altstore-build.log"
ALTSTORE_DIR="$PROJECT_DIR/altstore-release"

# App Store Connect API Key (for notarization)
AUTH_KEY_ID=QJNA476PS9
AUTH_ISSUER_ID=69a6de80-81b6-47e3-e053-5b8c7c11a4d1
AUTH_KEY_PATH="$PROJECT_DIR/AuthKey_${AUTH_KEY_ID}.p8"

# ------------------------------------------
# Setup directories
# ------------------------------------------
mkdir -p "$EXPORT_PATH"
mkdir -p "$ALTSTORE_DIR"

echo "🔨 Building SwitchBot app for AltStore PAL..."
echo "Log: $LOG_PATH"
echo ""

# ------------------------------------------
# Archive the WatchKit app
# ------------------------------------------
echo "📦 Creating archive..."
xcodebuild -project "$PROJECT_DIR/Switchbot.xcodeproj" \
           -scheme "Switchbot WatchKit App" \
           -destination "generic/platform=watchOS" \
           -configuration Release \
           -archivePath "$ARCHIVE_PATH" \
           -allowProvisioningUpdates \
           clean archive 2>&1 | tee -a "$LOG_PATH"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "❌ Failed to archive the app"
  exit 1
fi

# ------------------------------------------
# Export as IPA
# ------------------------------------------
echo ""
echo "📤 Exporting IPA..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  -allowProvisioningUpdates 2>&1 | tee -a "$LOG_PATH"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "❌ Failed to export IPA"
  exit 1
fi

# Find the exported IPA
IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" -type f | head -1)

if [ -z "$IPA_FILE" ]; then
  echo "❌ No IPA file found in $EXPORT_PATH"
  exit 1
fi

echo "✅ IPA built: $IPA_FILE"
echo ""

# ------------------------------------------
# Notarize the app
# ------------------------------------------
echo "🔐 Notarizing app with Apple..."
echo "⚠️  Make sure you have your App Store Connect API key file:"
echo "   $AUTH_KEY_PATH"
echo ""
echo "To generate one:"
echo "  1. Go to https://appstoreconnect.apple.com/access/users"
echo "  2. Create API Key (Team Member)"
echo "  3. Download and save as: $AUTH_KEY_PATH"
echo ""

if [ ! -f "$AUTH_KEY_PATH" ]; then
  echo "⚠️  API key file not found. Skipping notarization for now."
  echo "   You can notarize manually later."
  cp "$IPA_FILE" "$ALTSTORE_DIR/Switchbot-unsigned.ipa"
else
  # Notarize using xcrun
  echo "Submitting for notarization..."
  xcrun notarytool submit "$IPA_FILE" \
    --apple-id "alex.tudose@tapp.work" \
    --team-id "NF6484JE8F" \
    --key-id "$AUTH_KEY_ID" \
    --key "$AUTH_KEY_PATH" \
    --wait 2>&1 | tee -a "$LOG_PATH"
  
  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Notarization successful!"
    cp "$IPA_FILE" "$ALTSTORE_DIR/Switchbot-notarized.ipa"
  else
    echo "❌ Notarization failed"
    exit 1
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Build Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Output location: $ALTSTORE_DIR"
echo "📱 IPA ready for AltStore PAL"
echo ""
echo "Next steps:"
echo "  1. Create AltStore source.json"
echo "  2. Host on a web server"
echo "  3. Share source URL with users"
echo ""
