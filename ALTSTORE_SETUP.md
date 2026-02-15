# AltStore PAL Setup Guide

This guide walks you through publishing your SwitchBot Watch app on AltStore PAL for EU users.

## Prerequisites

✅ **You have:**
- Xcode project with automatic code signing
- Apple Developer Team ID: `NF6484JE8F`
- GitHub repo: https://github.com/alextud/switchbot-watch

❌ **You need to get:**
- App Store Connect API Key (for notarization)
- A web server to host the IPA and source.json
- (Optional) A custom domain/CDN

---

## Step 1: Get an App Store Connect API Key

1. Go to https://appstoreconnect.apple.com/access/users
2. Click the **API Keys** tab
3. Click **Generate API Key**
4. Set Role: **Team Member**
5. Download the `.p8` file
6. Save it as: `~/projects/switchbot-watch/AuthKey_QJNA476PS9.p8`

> Replace `QJNA476PS9` with the actual Key ID if different

---

## Step 2: Build & Notarize

Update the build script with your Apple ID:

```bash
# Edit build-for-altstore.sh
# Change this line with your actual Apple ID email:
--apple-id "your-apple-id@example.com" \
```

Then run:

```bash
cd ~/projects/switchbot-watch
./build-for-altstore.sh
```

**What it does:**
1. ✅ Builds a Release archive
2. ✅ Exports as `.ipa`
3. ✅ Notarizes with Apple (fully automatic)
4. ✅ Outputs to `altstore-release/`

**Output:**
- `Switchbot-notarized.ipa` — Ready for distribution
- Log file in `build/altstore-build.log`

---

## Step 3: Host the IPA & Source

You have a few options:

### Option A: GitHub Releases (Easiest)

```bash
# In your switchbot-watch repo:
gh release create v1.0.0 altstore-release/Switchbot-notarized.ipa --title "v1.0.0 for AltStore"
```

Your IPA will be at:
```
https://github.com/alextud/switchbot-watch/releases/download/v1.0.0/Switchbot-notarized.ipa
```

### Option B: Web Server

Upload to any CDN (Netlify, Vercel, AWS S3, etc):
```
https://your-domain.com/switchbot-watch/Switchbot.ipa
```

### Option C: Gist or Raw GitHub

Raw GitHub URL:
```
https://raw.githubusercontent.com/alextud/switchbot-watch/main/releases/Switchbot.ipa
```

---

## Step 4: Create source.json

Edit `altstore-release/source-template.json` and replace:

```json
"downloadURL": "https://YOUR_HOST_URL/switchbot-watch/releases/Switchbot.ipa",
```

With your actual URL. Then rename to `source.json`.

**Example:**
```json
"downloadURL": "https://github.com/alextud/switchbot-watch/releases/download/v1.0.0/Switchbot-notarized.ipa",
```

Save the `source.json` somewhere accessible (also on GitHub, your server, etc).

---

## Step 5: Share with Users

Users in the EU can now add your source to AltStore PAL:

1. Open **AltStore PAL** on their iPhone
2. Go to **Browse** → **Sources**
3. Tap **+** and paste your source URL:
   ```
   https://raw.githubusercontent.com/alextud/switchbot-watch/main/altstore-release/source.json
   ```
4. Your app appears in AltStore
5. Install with one tap
6. **App never expires** ✨

---

## Step 6: Updates

To push updates:

1. Bump version in `source.json`
2. Update `versionDate` to today
3. Rebuild and notarize:
   ```bash
   ./build-for-altstore.sh
   ```
4. Upload new IPA to your host
5. Users get automatic update notifications in AltStore

---

## Troubleshooting

### Notarization fails
- Check API key file exists at the path above
- Verify Apple ID email is correct
- Check logs in `build/altstore-build.log`

### IPA not uploading
- Test URL in browser — should download the IPA directly
- Check Content-Type headers (should be `application/octet-stream`)

### App doesn't appear in AltStore
- Validate `source.json` syntax at https://jsonlint.com/
- Check `bundleIdentifier` matches your Xcode project
- Verify download URL is accessible

---

## What's Next?

- 📱 Test on your own watch first
- 👥 Share with beta testers
- 🔄 Set up CI/CD to auto-notarize on each release
- 🎯 List on https://explore.alt.store (optional, for discovery)

---

## Resources

- [AltStore PAL Docs](https://faq.altstore.io/altstore-pal)
- [AltStore Source Format](https://faq.altstore.io/developers/make-a-source)
- [Apple Notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

Good luck! 🚀
