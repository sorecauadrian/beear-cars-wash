# Store Setup Guide - Google Play & App Store

This guide covers how to build release versions of the app for publishing to Google Play Store and Apple App Store.

## Prerequisites

- ✅ App icons generated (already done via `flutter_launcher_icons`)
- ✅ Splash screen configured (already done via `flutter_native_splash`)
- ✅ Firebase configured and working
- ✅ App tested on real devices

---

## Android: Google Play Store

### Step 1: Generate a Signing Key

1. **Create a keystore file** (one-time setup):
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   
   You'll be prompted for:
   - Password (remember this!)
   - Name, organization, city, state, country
   - Confirm password

2. **Create `android/key.properties`** file:
   ```properties
   storePassword=<your-keystore-password>
   keyPassword=<your-key-password>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

3. **Update `.gitignore`** (already done - `android/key.properties` is excluded)

### Step 2: Configure Signing in build.gradle.kts

The signing configuration should be added to `android/app/build.gradle.kts`:

```kotlin
android {
    // ... existing config ...
    
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = java.util.Properties()
            keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
            
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Optional: Enable code shrinking and obfuscation
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### Step 3: Build Release APK

For testing or direct distribution:
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Step 4: Build App Bundle (AAB) - Recommended for Play Store

Google Play requires AAB format:
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Step 5: Test the Release Build

Before uploading to Play Store:
```bash
flutter install --release
```

Or manually install the APK on a device:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Step 6: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app (if first time)
3. Fill in app details:
   - App name: "Beear Cars Wash"
   - Default language: English (or Romanian)
   - App or game: App
   - Free or paid: Free
4. Go to **Production** → **Create new release**
5. Upload the `.aab` file from Step 4
6. Fill in release notes
7. Review and publish

### Step 7: Required Store Assets

You'll need to provide:
- **App icon**: 512x512px (already generated)
- **Feature graphic**: 1024x500px
- **Screenshots**: At least 2, up to 8
  - Phone: 16:9 or 9:16, min 320px, max 3840px
  - Tablet: 16:9 or 9:16, min 320px, max 3840px
- **Privacy Policy URL**: Required for apps that collect user data

---

## iOS: Apple App Store

### Step 1: Apple Developer Account

1. Enroll in [Apple Developer Program](https://developer.apple.com/programs/) ($99/year)
2. Wait for approval (usually 24-48 hours)

### Step 2: Configure Xcode

1. **Open the project in Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```
   ⚠️ **Important**: Open `.xcworkspace`, NOT `.xcodeproj`

2. **Configure Signing & Capabilities**:
   - Select **Runner** in project navigator
   - Go to **Signing & Capabilities** tab
   - Select your **Team** (Apple Developer account)
   - Xcode will automatically create/select provisioning profiles

3. **Set Bundle Identifier**:
   - Should be: `com.beear.carswash`
   - Verify it matches your Firebase iOS app configuration

4. **Configure App Icons**:
   - Icons should already be set (generated via `flutter_launcher_icons`)
   - Verify in `Runner/Assets.xcassets/AppIcon.appiconset`

### Step 3: Update Version and Build Number

In `pubspec.yaml`:
```yaml
version: 1.0.0+1
# Format: <version-name>+<build-number>
# version-name: shown to users (1.0.0)
# build-number: internal build number (1)
```

For each release, increment:
- **version-name**: 1.0.0 → 1.0.1 (patch), 1.1.0 (minor), 2.0.0 (major)
- **build-number**: Must always increase (1 → 2 → 3...)

### Step 4: Build for App Store

1. **Archive the app**:
   - In Xcode: **Product** → **Archive**
   - Wait for build to complete
   - Xcode Organizer will open automatically

2. **Validate the archive**:
   - In Organizer, select your archive
   - Click **Validate App**
   - Fix any issues if found

3. **Distribute to App Store**:
   - In Organizer, select your archive
   - Click **Distribute App**
   - Choose **App Store Connect**
   - Follow the wizard
   - Upload will take several minutes

### Step 5: Configure App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create a new app:
   - **Platform**: iOS
   - **Name**: Beear Cars Wash
   - **Primary Language**: English (or Romanian)
   - **Bundle ID**: com.beear.carswash
   - **SKU**: Unique identifier (e.g., `beear-cars-wash-001`)

3. **Fill in App Information**:
   - Category: Business or Utilities
   - Privacy Policy URL: Required
   - Support URL: Your website/support page

4. **Prepare for Submission**:
   - **App Preview/Screenshots**: Required
     - iPhone 6.7": 1290x2796px
     - iPhone 6.5": 1284x2778px
     - iPhone 5.5": 1242x2208px
   - **Description**: App description
   - **Keywords**: Search keywords
   - **Support URL**: Your support page
   - **Marketing URL**: Optional
   - **Version Information**: Release notes

5. **Submit for Review**:
   - Once build is processed (can take 1-2 hours)
   - Complete all required fields
   - Submit for review
   - Review typically takes 24-48 hours

### Step 6: iOS-Specific Requirements

- **Privacy Policy**: Required for apps that collect user data
- **App Transport Security**: Already configured for Firebase
- **Push Notifications**: Requires APNs certificate (see `docs/IOS_SETUP_LATER.md`)
- **Camera Permission**: Already configured in `Info.plist`

---

## Version Management

### Semantic Versioning

Use semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Example: `1.0.0` → `1.0.1` (bug fix) → `1.1.0` (new feature) → `2.0.0` (breaking change)

### Updating Version

1. Update `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2
   ```

2. For Android, also update `android/app/build.gradle.kts` (if needed):
   ```kotlin
   defaultConfig {
       versionCode = 2
       versionName = "1.0.1"
   }
   ```

3. For iOS, version is read from `pubspec.yaml` automatically

---

## Testing Release Builds

### Android

1. **Build release APK**:
   ```bash
   flutter build apk --release
   ```

2. **Install on device**:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Test thoroughly**:
   - All features work
   - Firebase connections work
   - Notifications work
   - No crashes

### iOS

1. **Build for device**:
   ```bash
   flutter build ios --release
   ```

2. **Test on device via Xcode**:
   - Connect device
   - Select device in Xcode
   - Click Run (or Product → Run)

---

## Common Issues & Solutions

### Android

**Issue**: "Execution failed for task ':app:signReleaseBundle'"
- **Solution**: Make sure `key.properties` exists and has correct passwords

**Issue**: "Keystore file not found"
- **Solution**: Check path in `key.properties` is correct (relative to `android/`)

**Issue**: APK too large
- **Solution**: Use App Bundle (AAB) instead, or enable code shrinking

### iOS

**Issue**: "No signing certificate found"
- **Solution**: Select your team in Xcode → Signing & Capabilities

**Issue**: "Provisioning profile doesn't match"
- **Solution**: Let Xcode automatically manage profiles

**Issue**: Build fails with Firebase errors
- **Solution**: Make sure `GoogleService-Info.plist` is in Xcode project

---

## Checklist Before Publishing

### Android
- [ ] Release build tested on real device
- [ ] All features working
- [ ] Firebase configured correctly
- [ ] App icon and splash screen look good
- [ ] Version number updated
- [ ] Signing key created and secured
- [ ] AAB file built successfully
- [ ] Store listing assets prepared
- [ ] Privacy policy URL ready

### iOS
- [ ] Apple Developer account active
- [ ] App tested on real iOS device
- [ ] All features working
- [ ] Firebase configured correctly
- [ ] App icon and splash screen look good
- [ ] Version number updated
- [ ] Archive created and validated
- [ ] App Store Connect app created
- [ ] Store listing assets prepared
- [ ] Privacy policy URL ready
- [ ] APNs certificate configured (for push notifications)

---

## Post-Publishing

### Monitor
- **Google Play Console**: Track downloads, ratings, crashes
- **App Store Connect**: Track downloads, ratings, crashes
- **Firebase Console**: Monitor app performance, crashes, analytics

### Updates
- Follow same process for updates
- Increment version number
- Test thoroughly before releasing
- Update release notes

---

## Resources

- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

---

**Good luck with your app launch! 🚀**

