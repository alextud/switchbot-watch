#!/bin/bash

# ------------------------------------------
# Paths
# ------------------------------------------
PROJECT_DIR="$(pwd)"
IOS_DIR="$PROJECT_DIR"
ARCHIVE_PATH="$IOS_DIR/build/Switchbot WatchKit App.xcarchive"
EXPORT_PATH="$IOS_DIR/build/ipa"
EXPORT_OPTIONS_PLIST="$IOS_DIR/ExportOptions.plist"
LOG_PATH="$IOS_DIR/build/export_full.log"

# ------------------------------------------
# App Store Connect API Key info (from environment)
# ------------------------------------------
AUTH_KEY_ID="${APPSTORE_API_KEY_ID}"
AUTH_ISSUER_ID="${APPSTORE_ISSUER_ID}"
# AUTH_KEY_ID=QJNA476PS9
# AUTH_ISSUER_ID=69a6de80-81b6-47e3-e053-5b8c7c11a4d1
# AUTH_KEY_PATH="$PROJECT_DIR/AuthKey_${AUTH_KEY_ID}.p8"

echo "AUTH_KEY_ID: $AUTH_KEY_ID"
echo "AUTH_ISSUER_ID: $AUTH_ISSUER_ID"
echo "AUTH_KEY_PATH: $AUTH_KEY_PATH"

# ------------------------------------------
# Create API key from secret
# ------------------------------------------
# echo "🔑 Setting up API key..."
# echo "${APPSTORE_API_PRIVATE_KEY}" > "$AUTH_KEY_PATH"

# ------------------------------------------
# Create export directory
# ------------------------------------------
mkdir -p "$EXPORT_PATH"
echo "📝 Starting archive and export..."
echo "Logs will be saved to $LOG_PATH"
echo "Archive will be saved to $ARCHIVE_PATH"

echo "Available code signing identities:"
security find-identity -p codesigning || true

# # ------------------------------------------
# # Archive the WatchKit app
# # ------------------------------------------
xcodebuild -project "$IOS_DIR/Switchbot.xcodeproj" \
           -scheme "Switchbot WatchKit App" \
           -destination "generic/platform=watchOS" \
           -configuration Release \
           -archivePath "$ARCHIVE_PATH" \
           -authenticationKeyID "$AUTH_KEY_ID" \
           -authenticationKeyIssuerID "$AUTH_ISSUER_ID" \
           -authenticationKeyPath "$AUTH_KEY_PATH" \
           -allowProvisioningUpdates \
           clean archive 2>&1 | tee -a "$LOG_PATH"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "❌ Failed to archive the app"
  exit 1
fi

# ------------------------------------------
# Export IPA using cloud signing
# ------------------------------------------
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  -authenticationKeyID "$AUTH_KEY_ID" \
  -authenticationKeyIssuerID "$AUTH_ISSUER_ID" \
  -authenticationKeyPath "$AUTH_KEY_PATH" \
  -allowProvisioningUpdates 2>&1 | tee -a "$LOG_PATH"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
  echo "✅ IPA exported successfully to $EXPORT_PATH"
else
  echo "❌ Failed to export IPA"
  echo "Check full logs in $LOG_PATH for details"
  exit 1
fi

# ------------------------------------------
# Prepare API key for altool (auto-rename)
# ------------------------------------------
echo "🔑 Preparing API key for altool..."
mkdir -p ~/.appstoreconnect/private_keys
DEST_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${AUTH_KEY_ID}.p8"
cp -f "$AUTH_KEY_PATH" "$DEST_KEY_PATH"

# ------------------------------------------
# Upload IPA to TestFlight
# ------------------------------------------
IPA_FILE="$EXPORT_PATH/Switchbot.ipa"
echo "📤 Uploading to TestFlight..."

if xcrun --find upload-app >/dev/null 2>&1; then
  echo "➡️ Using upload-app"
  xcrun upload-app \
    -f "$IPA_FILE" \
    -t ios \
    --apiKey "$AUTH_KEY_ID" \
    --apiIssuer "$AUTH_ISSUER_ID" 2>&1 | tee -a "$LOG_PATH"
  UPLOAD_STATUS=${PIPESTATUS[0]}
else
  echo "⚠️ upload-app not found, falling back to altool"
  xcrun altool --upload-app \
    -f "$IPA_FILE" \
    -t ios \
    --apiKey "$AUTH_KEY_ID" \
    --apiIssuer "$AUTH_ISSUER_ID" \
    --verbose 2>&1 | tee -a "$LOG_PATH"
  UPLOAD_STATUS=${PIPESTATUS[0]}
fi

if [ $UPLOAD_STATUS -eq 0 ]; then
  echo "🚀 Upload successful! Check TestFlight in App Store Connect."
else
  echo "❌ Upload failed. Check $LOG_PATH for details."
  exit 1
fi

# Cleanup
rm -f "$AUTH_KEY_PATH"