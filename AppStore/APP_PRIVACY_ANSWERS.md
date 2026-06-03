# App Privacy questionnaire answers (App Store Connect → App Privacy)

Use these answers when filling in the "App Privacy" section in App Store Connect.
They match the bundled `PrivacyInfo.xcprivacy`.

## Data collection
**Do you or your third-party partners collect data from this app?**
→ **No, we do not collect data from this app.**

Rationale: Aligner Tracker is fully offline. All wear logs, diary photos/notes,
and settings are stored only on the device (and the user's own device backup).
Nothing is transmitted to us or any third party. The "Export" and "Share"
features only move data when the user explicitly initiates it, which does not
count as collection by the developer.

## Tracking
**Does this app track users (ATT)?** → No. (`NSPrivacyTracking = false`.)

## Required-reason API declared in PrivacyInfo.xcprivacy
- `NSPrivacyAccessedAPICategoryUserDefaults` → reason `1C8F.1`
  (the app and its widget share data through an App Group's UserDefaults).

## Content rights / Age rating (App Store Connect → Age Rating)
All questions → **None / No**. Expected rating: **4+**.

## Export compliance
`ITSAppUsesNonExemptEncryption = NO` is set in both Info.plist files, so the app
uses no non-exempt encryption and no annual self-classification report is needed.
