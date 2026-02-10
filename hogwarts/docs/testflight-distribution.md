# TestFlight Distribution Guide - Hogwarts iOS

> **Goal**: Enable TestFlight distribution to share app progress with clients and testers before App Store release.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setup Instructions](#setup-instructions)
3. [Building & Archiving](#building--archiving)
4. [Uploading to TestFlight](#uploading-to-testflight)
5. [Managing Testers](#managing-testers)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you can distribute via TestFlight, you'll need:

### 1. Apple Developer Program Membership
- **Cost**: $99 USD/year
- **Link**: [developer.apple.com/programs](https://developer.apple.com/programs)
- **Status**: Grants access to provisioning profiles and code signing

### 2. App Store Connect Account
- **Link**: [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- **Required to**: Create app record, manage TestFlight builds, add testers

### 3. Code Signing Certificates & Provisioning Profiles

You'll need:
- **Apple Distribution Certificate** (for code signing)
- **App ID** (e.g., `org.databayt.hogwarts`)
- **Distribution Provisioning Profile** (links certificate + App ID + team)

#### How to Create Certificates

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Certificates** → **+**
4. Select "Apple Distribution" certificate type
5. Follow the wizard to create your certificate
6. Download and add to your Keychain

#### How to Create App ID

1. In Developer Account → **Identifiers**
2. Click **+** → **App IDs**
3. **Description**: "Hogwarts"
4. **Bundle ID**: `org.databayt.hogwarts` (must match Xcode)
5. Check capabilities needed (contacts, health, etc.)
6. Click **Register**

#### How to Create Distribution Provisioning Profile

1. In Developer Account → **Profiles**
2. Click **+** → **App Store**
3. Select the `org.databayt.hogwarts` App ID
4. Select your Distribution certificate
5. Name it "Hogwarts Distribution"
6. Download and add to Xcode or Keychain

### 4. Team ID

Found in Developer Account → **Membership**

Update your `ExportOptions.plist`:
```xml
<key>teamID</key>
<string>YOUR_TEAM_ID_HERE</string>
```

---

## Setup Instructions

### Step 1: Create App Store Connect Record

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **Apps** → **+** (Create New App)
3. **Platform**: iOS
4. **Name**: Hogwarts
5. **Bundle ID**: Select `org.databayt.hogwarts` from dropdown
6. **SKU**: `HOGWARTS-001` (internal identifier)
7. **Supported Languages**: English
8. Click **Create**

### Step 2: Update App Information

In App Store Connect, fill in basic app details:

- **App Name**: Hogwarts
- **Subtitle**: School Management Platform
- **Category**: Education
- **Privacy Policy URL**: `https://ed.databayt.org/privacy`
- **Support URL**: `https://ed.databayt.org/support`

### Step 3: Update Xcode Build Settings

In your Xcode project:

```
Build Settings → Code Signing:
- Development Team: [YOUR_TEAM_ID]
- Code Sign Identity: Apple Distribution
- Provisioning Profile: Hogwarts Distribution
```

Or edit directly in `project.yml`:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: "YOUR_TEAM_ID"
    CODE_SIGN_STYLE: Manual
    CODE_SIGN_IDENTITY: "Apple Distribution"
    PROVISIONING_PROFILE_SPECIFIER: "Hogwarts Distribution"
```

### Step 4: Update ExportOptions.plist

Edit `/hogwarts/ExportOptions.plist`:

```xml
<key>teamID</key>
<string>YOUR_TEAM_ID</string>
<key>provisioningProfiles</key>
<dict>
    <key>org.databayt.hogwarts</key>
    <string>Hogwarts Distribution</string>
</dict>
```

---

## Building & Archiving

### Option A: Using Build Script (Recommended)

```bash
cd /Users/abdout/swift-app/hogwarts

# Make sure script is executable
chmod +x scripts/archive-for-testflight.sh

# Run the script
./scripts/archive-for-testflight.sh
```

**What it does**:
1. ✅ Cleans previous builds
2. ✅ Archives for App Store
3. ✅ Exports IPA for TestFlight
4. ✅ Verifies the IPA file
5. ✅ Prints next steps

**Output**: `build/TestFlight/Hogwarts-TestFlight.ipa`

### Option B: Using Xcode UI

1. **Product** → **Archive**
2. Wait for archive to complete
3. In **Archives** window, select your build
4. Click **Distribute App**
5. Select **TestFlight**
6. Choose **Upload**
7. Sign in with Apple ID
8. Wait for upload to complete

### Option C: Using Xcode Command Line

```bash
# Create archive
xcodebuild archive \
    -scheme Hogwarts \
    -configuration Release \
    -archivePath build/Hogwarts.xcarchive \
    -allowProvisioningUpdates

# Export for TestFlight
xcodebuild -exportArchive \
    -archivePath build/Hogwarts.xcarchive \
    -exportPath build/TestFlight \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates
```

---

## Uploading to TestFlight

### Option A: Using Transporter (Apple's Official Tool)

1. Download **Transporter** from App Store
2. Open Transporter
3. Click **+** and select `Hogwarts-TestFlight.ipa`
4. Review package details
5. Click **Deliver**
6. Sign in with Apple ID (requires 2FA)
7. Wait for upload confirmation

### Option B: Using Xcode

1. Open **Organizer** (Window → Organizer)
2. Select your archive
3. Click **Distribute App**
4. Select **App Store Connect**
5. Choose **Upload**
6. Sign in and follow prompts

### Option C: Using Command Line (Advanced)

```bash
# First, get your app's ID
xcrun altool --list-apps \
    -u "your-apple-id@example.com" \
    -p "your-app-specific-password"

# Upload IPA
xcrun altool --upload-app \
    -f build/TestFlight/Hogwarts-TestFlight.ipa \
    -t ios \
    -u "your-apple-id@example.com" \
    -p "your-app-specific-password"
```

### Post-Upload Checklist

- ✅ Confirm upload completed in Transporter
- ✅ Check App Store Connect for new build
- ✅ Wait for processing (usually 5-10 minutes)
- ✅ View build details → **TestFlight**

---

## Managing Testers

### Adding Internal Testers

**Internal Testers** = Your team (up to 100 people)

1. In App Store Connect, go to **TestFlight**
2. Click **Internal Testing**
3. Click **+** under "Testers"
4. Enter tester email address
5. Select groups (or leave default)
6. Send invite via email

### Adding External Testers

**External Testers** = Beta testers outside your team (up to 10,000 people)

1. In **TestFlight** → **External Testing**
2. Click **Create a New Group** or select existing
3. Add tester emails
4. **Submit for Review** (Apple reviews the build)
5. Once approved, testers get TestFlight invite

### Tester Onboarding

Testers will:
1. Receive email invite to TestFlight app
2. Install **TestFlight** app from App Store
3. Accept invite in TestFlight
4. Download & install your app beta
5. Send feedback through TestFlight

### Monitoring Tester Feedback

1. In **TestFlight** → **Feedback**
2. View crash reports and tester comments
3. Respond to feedback in the dashboard

---

## Beta Versioning

### Version Numbers

Format: `MAJOR.MINOR.PATCH`

| Stage | Version | Example |
|-------|---------|---------|
| Alpha | 0.1.x | 0.1.0, 0.1.1 |
| Beta | 1.0.0-beta.x | 1.0.0-beta.1 |
| Release Candidate | 1.0.0-rc.x | 1.0.0-rc.1 |
| Production | 1.0.0 | 1.0.0 |

### Updating Version in Xcode

**Project Settings** → **General**:
- **Version**: `1.0` (marketing version)
- **Build**: `1` (build number, increment for each beta)

Or edit `Info.plist`:
```xml
<key>CFBundleShortVersionString</key>
<string>1.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### Release Notes

For each build, add release notes:

1. In **TestFlight** → Select build
2. Click **What to Test**
3. Enter release notes:

```
### Version 1.0.0-beta.1

**New Features**
- Redesigned dashboard with glass morphism aesthetic
- New context menus for quick actions
- Improved form handling with sheet presentations

**Improvements**
- SF Symbols now use hierarchical rendering
- Better spacing and typography consistency
- Enhanced offline synchronization

**Bug Fixes**
- Fixed blank screen on low network
- Resolved sync conflicts in attendance
```

---

## Troubleshooting

### Build Fails

**Error**: `Code Sign Error "Signing Identity "Apple Distribution" is not valid"`

**Solution**:
1. Check your provisioning profile is installed
2. Verify team ID in ExportOptions.plist
3. Clean build folder (Cmd+Shift+K)
4. Restart Xcode

### Archive Won't Export

**Error**: `ExportOptions.plist validation failed`

**Solution**:
1. Check XML syntax in ExportOptions.plist
2. Verify bundle ID matches your App ID
3. Ensure provisioning profile name is correct
4. Run: `plutil -lint ExportOptions.plist`

### Upload Rejected

**Error**: `Build validation failed with: Invalid Code Signing Entitlements`

**Solution**:
1. Check your Entitlements.plist
2. Ensure all entitlements are supported by your team
3. Remove unused entitlements
4. Rebuild and re-archive

### Transporter Issues

**Error**: `Failed to upload app`

**Solution**:
1. Check internet connection
2. Try uploading with app-specific password instead of regular Apple ID password
3. Create app-specific password: [appleid.apple.com/account/security](https://appleid.apple.com/account/security)
4. Retry upload

### Testers Not Receiving Invites

**Issue**: Testers don't get TestFlight email

**Solution**:
1. Check email addresses for typos
2. Ensure testers have Apple ID
3. Check spam folder for invite email
4. Resend invite from TestFlight dashboard
5. Verify tester region matches app region

---

## Important Considerations

### Before Going to Production

- [ ] Test on multiple devices
- [ ] Verify all features work offline
- [ ] Check all localizations (Arabic + English)
- [ ] Test with slow internet
- [ ] Gather tester feedback from TestFlight
- [ ] Fix critical bugs
- [ ] Update version numbers
- [ ] Update App Store listing

### App Store Review

Before submitting for App Store review, ensure:

- [ ] All 305 unit tests pass
- [ ] No console warnings or errors
- [ ] Accessibility labels on all interactive elements
- [ ] Privacy policy linked and accurate
- [ ] No hardcoded test data or credentials
- [ ] Uses native iOS UI patterns
- [ ] Complies with App Store guidelines

### After Release

- [ ] Monitor crash reports
- [ ] Respond to user reviews
- [ ] Track analytics
- [ ] Plan updates and features
- [ ] Maintain TestFlight for beta testing new versions

---

## Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [Provisioning Profiles Guide](https://developer.apple.com/support/certificates/)
- [Apple Code Signing](https://developer.apple.com/support/code-signing/)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Feb 2025 | Initial TestFlight distribution guide |
