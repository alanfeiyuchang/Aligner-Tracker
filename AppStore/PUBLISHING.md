# Publishing Aligner Tracker to the App Store

This guide covers everything from a clean checkout to a build sitting in App
Store Connect, ready for review.

What's already prepared in this repo:
- ✅ App icon (1024×1024) in the asset catalog
- ✅ `PrivacyInfo.xcprivacy` for the app and the widget (required-reason APIs declared)
- ✅ `ITSAppUsesNonExemptEncryption = NO` in both Info.plist files (no encryption prompt)
- ✅ English + Simplified Chinese localization (`Localizable.xcstrings`)
- ✅ Versioning: `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`
- ✅ Listing copy, privacy policy, privacy-questionnaire answers, `ExportOptions.plist` (this folder)

What only **you** can do (needs your Apple account) is in **steps 1, 2, 6, 7, 8**.

---

## 1. Prerequisites (one-time)
- Enroll in the **Apple Developer Program** ($99/year): https://developer.apple.com/programs/
- In Xcode → Settings → Accounts, sign in with that Apple ID.
- Decide on a **bundle identifier**. The project currently uses:
  - App:    `ACM.Aligner-Tracker`
  - Widget: `ACM.Aligner-Tracker.AlignerTrackerWidget`
  - App Store accepts these, but reverse-DNS (e.g. `com.yourname.alignertracker`)
    is the convention. If you change it, update it in **both** target build
    settings and keep the widget as `<app-id>.AlignerTrackerWidget`, and update
    the App Group below if you rename it.

## 2. Register identifiers & capabilities (developer.apple.com → Certificates, IDs & Profiles)
- **App ID** for `ACM.Aligner-Tracker` with **App Groups** capability.
- **App ID** for the widget `ACM.Aligner-Tracker.AlignerTrackerWidget` with **App Groups**.
- An **App Group**: `group.ACM.Aligner-Tracker`, and assign both App IDs to it.
  (This matches the `.entitlements` files already in the repo.)
- With **Automatic signing** in Xcode (already enabled, Team `5V3HM8L9GT`), Xcode
  will create/download the provisioning profiles for you when you archive.

## 3. Final pre-flight checks (local)
```bash
# Clean release build of app + embedded widget
xcodebuild -project "Aligner Tracker.xcodeproj" -scheme "Aligner Tracker" \
  -destination 'generic/platform=iOS' -configuration Release clean build
```
- Bump `CURRENT_PROJECT_VERSION` (build number) for every new upload; bump
  `MARKETING_VERSION` for each public version.

## 4. Create the app record (App Store Connect → My Apps → ➕)
- Platform: iOS · Name: **Aligner Tracker** · Primary language: English (or 简体中文)
- Bundle ID: select `ACM.Aligner-Tracker` · SKU: `aligner-tracker-1`
- Fill the listing from `metadata/en-US/listing.md` and add a **Simplified
  Chinese** localization from `metadata/zh-Hans/listing.md`.
- Paste the **Privacy Policy URL** (host `PRIVACY_POLICY.md` somewhere public,
  e.g. GitHub Pages) and complete **App Privacy** using `APP_PRIVACY_ANSWERS.md`.
- Set **Age Rating** to 4+ (all questions "None"), pick a **Category**
  (suggested: Health & Fitness; secondary: Medical).

## 5. Screenshots (required)
Apple currently requires at least one set; the **6.9"** iPhone set is the one
everything else can be scaled from. Capture from the simulator:
```bash
# Boot a 6.9" device (iPhone 16 Pro Max / 15 Pro Max → 1320×2868 or 1290×2796)
xcrun simctl boot "iPhone 16 Pro Max"
# build/install/launch, navigate, then:
xcrun simctl io booted screenshot screenshot-1.png
```
Take 3–5 shots (Home timer, History calendar, Diary, Settings, a widget). Upload
them under both English and Chinese localizations. A 6.5" set is also accepted.

## 6. Archive & upload
**Option A — Xcode (simplest):**
1. Set the run destination to **Any iOS Device (arm64)**.
2. Product → **Archive**.
3. In the Organizer: **Distribute App → App Store Connect → Upload**.

**Option B — command line:**
```bash
xcodebuild -project "Aligner Tracker.xcodeproj" -scheme "Aligner Tracker" \
  -configuration Release -archivePath build/AlignerTracker.xcarchive \
  -destination 'generic/platform=iOS' archive

xcodebuild -exportArchive \
  -archivePath build/AlignerTracker.xcarchive \
  -exportOptionsPlist AppStore/ExportOptions.plist \
  -exportPath build/export
# (this uploads because ExportOptions sets destination = upload)
```

## 7. Submit for review (App Store Connect)
- Under your 1.0 version, select the uploaded **Build** (appears after Apple
  finishes processing — a few minutes to an hour).
- Confirm Export Compliance ("No" is pre-answered by the Info.plist key).
- Add review notes if needed (the app needs no login; notifications/camera are
  optional). Click **Add for Review → Submit**.

## 8. After approval
- Release manually or automatically.
- For updates: bump versions (step 3), archive, upload, add a new version in
  App Store Connect with "What's New" text, submit.

---

### Quick reference
| Item | Value |
| --- | --- |
| App bundle ID | `ACM.Aligner-Tracker` |
| Widget bundle ID | `ACM.Aligner-Tracker.AlignerTrackerWidget` |
| App Group | `group.ACM.Aligner-Tracker` |
| Team ID | `5V3HM8L9GT` |
| Min iOS | 17.0 |
| Version / Build | 1.0 / 1 |
| Encryption | None (`ITSAppUsesNonExemptEncryption = NO`) |
| Data collection | None (offline) |
