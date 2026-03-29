# MuseMac — Launch Checklist

## Pre-Launch

### Code & Build
- [ ] `xcodegen generate` succeeds
- [ ] `xcodebuild -scheme MuseMac -configuration Release` builds with zero errors
- [ ] No hardcoded color values outside `Theme.swift` (dark mode audit: ✅ all views use Theme tokens)
- [ ] `Marketing/APPSTORE.md` screenshot specs confirmed
- [ ] `project.yml` version matches planned release (e.g. `1.0.0`)

### App Store Connect
- [ ] App record created in App Store Connect
- [ ] Bundle ID registered: `com.musemac.app`
- [ ] Team ID set in Xcode signing
- [ ] App Store listing drafted (tagline, description, keywords, screenshots)
- [ ] Screenshots generated at 1280×800 PNG (see `Marketing/APPSTORE.md`)
- [ ] Preview video generated (optional)
- [ ] Age Rating questionnaire completed
- [ ] Pricing & Availability set
- [ ] Privacy Policy URL live
- [ ] Support URL live

### Entitlements & Capabilities
- [ ] `com.apple.security.app-sandbox` enabled
- [ ] `com.apple.security.network.client` (if streaming features call external APIs)
- [ ] `com.apple.security.files.user-selected.read-only` (if importing local files)
- [ ] No wildcard provisioning profiles

### Legal
- [ ] Privacy Policy published
- [ ] Terms of Service published
- [ ] Apple Developer Agreement accepted

---

## Submission

- [ ] Archive build: `xcodebuild -scheme MuseMac -configuration Release -archivePath ./build/MuseMac.xcarchive archive`
- [ ] Validate: `xcrun altool --validate-app -f ./build/MuseMac.xcarchive`
- [ ] Upload: `xcrun altool --upload-app -f ./build/MuseMac.xcarchive`
- [ ] Select build in App Store Connect
- [ ] Submit for review

---

## Post-Launch

- [ ] Confirm build appears in "My Apps" → "App Store" tab
- [ ] Monitor App Store Connect for "In Review" → "Ready for Sale"
- [ ] Verify App Store page renders correctly with screenshots
- [ ] Test on a clean macOS machine (fresh install)
- [ ] Announce launch (if applicable)
- [ ] Monitor for crash reports in Xcode Organizer

---

## Build Commands Reference

```bash
# Generate Xcode project
cd MuseMac && xcodegen generate

# Build Release
xcodebuild -scheme MuseMac \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  build CODE_SIGN_IDENTITY="-" 2>&1 | grep -E "error:|BUILD"

# Archive for submission
xcodebuild -scheme MuseMac \
  -configuration Release \
  -archivePath ./build/MuseMac.xcarchive \
  archive
```
