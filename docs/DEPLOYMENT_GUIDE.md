# Deployment Guide - Beear Cars Wash

This guide explains how to deploy the Beear Cars Wash Flutter application for direct distribution (not through app stores).

## Prerequisites

Before deploying, ensure you have:

- ✅ Flutter SDK installed and configured
- ✅ Android Studio / Xcode installed
- ✅ Firebase project configured with all services
- ✅ All environment variables and API keys set up
- ✅ App icons and splash screens configured
- ✅ All features tested and working

## Step 1: Update App Version

1. Open `pubspec.yaml`
2. Update the version number:
   ```yaml
   version: 1.0.0+1  # Format: version_name+build_number
   ```
   - Increment the version name (e.g., 1.0.0 → 1.0.1) for new features
   - Increment the build number (+1 → +2) for each build

## Step 2: Build Configuration

### Android Configuration

1. **Update `android/app/build.gradle`:**
   - Set `minSdkVersion` (recommended: 21 or higher)
   - Set `targetSdkVersion` (latest stable)
   - Configure signing configs for release builds

2. **Create/Update Keystore:**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

3. **Create `android/key.properties`:**
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=upload
   storeFile=<path-to-your-keystore>
   ```

4. **Update `android/app/build.gradle`** to use the keystore:
   ```gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }

   android {
       ...
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

### iOS Configuration

1. **Update `ios/Runner.xcodeproj`:**
   - Set Bundle Identifier (e.g., `ro.beearcarswash.app`)
   - Configure signing & capabilities
   - Set deployment target (iOS 12.0 or higher recommended)

2. **Update `ios/Runner/Info.plist`:**
   - Set app display name
   - Configure permissions descriptions
   - Set minimum iOS version

## Step 3: Build Release APK (Android)

1. **Clean the project:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Build APK:**
   ```bash
   flutter build apk --release
   ```
   The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

3. **Build App Bundle (Optional, for better optimization):**
   ```bash
   flutter build appbundle --release
   ```
   The AAB will be at: `build/app/outputs/bundle/release/app-release.aab`

4. **Build Split APKs (Optional, for smaller file sizes):**
   ```bash
   flutter build apk --split-per-abi --release
   ```
   This creates separate APKs for different architectures (arm64-v8a, armeabi-v7a, x86_64)

## Step 4: Build Release IPA (iOS)

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configure Signing:**
   - Select your development team
   - Ensure "Automatically manage signing" is enabled
   - Or manually configure certificates and provisioning profiles

3. **Build Archive:**
   - In Xcode, select "Any iOS Device" as target
   - Go to Product → Archive
   - Wait for the archive to complete

4. **Export IPA:**
   - In Organizer window, select your archive
   - Click "Distribute App"
   - Choose "Ad Hoc" or "Enterprise" distribution
   - Select your team and provisioning profile
   - Export the IPA file

5. **Alternative: Build via Command Line:**
   ```bash
   flutter build ipa --release
   ```
   The IPA will be at: `build/ios/ipa/beear_cars_wash.ipa`

## Step 5: Test the Builds

### Android Testing:
1. Install the APK on a test device:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```
2. Test all features thoroughly
3. Check Firebase connectivity
4. Verify notifications work
5. Test on different Android versions if possible

### iOS Testing:
1. Install via TestFlight (recommended) or direct installation
2. Test on different iOS devices
3. Verify all features work correctly
4. Test Firebase services
5. Check notifications

## Step 6: Prepare Distribution Files

### For Direct Download:

1. **Create a distribution folder structure:**
   ```
   distribution/
   ├── android/
   │   ├── app-release.apk
   │   └── app-release.aab (optional)
   ├── ios/
   │   └── beear_cars_wash.ipa
   └── README.txt
   ```

2. **Create README.txt with installation instructions:**
   ```
   Beear Cars Wash - Installation Instructions
   
   Android:
   1. Enable "Install from Unknown Sources" in Settings
   2. Download the APK file
   3. Open the downloaded file
   4. Tap "Install"
   
   iOS:
   1. Download the IPA file
   2. Install via iTunes or Apple Configurator
   3. Trust the developer certificate in Settings → General → Device Management
   ```

## Step 7: Hosting Options

### Option 1: Firebase Hosting (Recommended)
1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Initialize Firebase Hosting:
   ```bash
   firebase init hosting
   ```

3. Create a simple download page (see website specification)

4. Deploy:
   ```bash
   firebase deploy --only hosting
   ```

### Option 2: GitHub Releases
1. Create a new release on GitHub
2. Upload APK and IPA files as release assets
3. Share the release URL

### Option 3: Direct Server Hosting
1. Upload files to your web server
2. Create download links on your website
3. Ensure proper MIME types are set:
   - APK: `application/vnd.android.package-archive`
   - IPA: `application/octet-stream`

## Step 8: Security Considerations

1. **Enable App Signing:**
   - Always sign your Android APK/AAB
   - Use proper iOS code signing

2. **Obfuscate Code (Android):**
   Add to `android/app/build.gradle`:
   ```gradle
   buildTypes {
       release {
           minifyEnabled true
           shrinkResources true
           proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
       }
   }
   ```

3. **Firebase Security Rules:**
   - Review and tighten Firestore security rules
   - Ensure proper authentication requirements
   - Test rules thoroughly

4. **API Keys:**
   - Never commit API keys to version control
   - Use environment variables or secure storage
   - Rotate keys if exposed

## Step 9: Update Firebase Configuration

1. **Verify Firebase Project Settings:**
   - Check Android package name matches
   - Verify iOS bundle ID
   - Ensure all services are enabled

2. **Update OAuth Redirect URLs:**
   - Add your website domain to authorized domains
   - Configure OAuth consent screen if using Google Sign-In

## Step 10: Create Update Mechanism

Consider implementing:

1. **Version Check API:**
   - Create an endpoint that returns current app version
   - Check on app startup
   - Prompt user to download new version if available

2. **In-App Update Notification:**
   - Show a banner when a new version is available
   - Link to download page

## Step 11: Documentation

Create user documentation:

1. **Installation Guide** (for end users)
2. **User Manual** (how to use the app)
3. **Troubleshooting Guide** (common issues and solutions)

## Step 12: Monitoring & Analytics

1. **Firebase Analytics:**
   - Enable Firebase Analytics
   - Set up custom events
   - Monitor app usage

2. **Crash Reporting:**
   - Enable Firebase Crashlytics
   - Monitor crashes and errors
   - Set up alerts

3. **Performance Monitoring:**
   - Enable Firebase Performance Monitoring
   - Track app performance metrics

## Troubleshooting

### Android Build Issues:
- **Gradle errors:** Run `flutter clean` and `flutter pub get`
- **Signing errors:** Verify keystore configuration
- **Size too large:** Use split APKs or App Bundle

### iOS Build Issues:
- **Code signing errors:** Check certificates and provisioning profiles
- **Archive fails:** Clean build folder in Xcode
- **IPA not installing:** Verify provisioning profile includes device UDID

## Post-Deployment Checklist

- [ ] APK/IPA files built and tested
- [ ] Files uploaded to hosting location
- [ ] Download links working
- [ ] QR codes generated and tested
- [ ] Website updated with download links
- [ ] Firebase security rules reviewed
- [ ] Analytics and monitoring enabled
- [ ] User documentation created
- [ ] Support contact information available
- [ ] Version update mechanism in place

## Notes

- **APK Size:** Typically 20-50 MB for Flutter apps
- **IPA Size:** Typically 30-60 MB for Flutter apps
- **Update Frequency:** Plan for regular updates and bug fixes
- **Distribution:** Consider using a CDN for faster downloads
- **Legal:** Ensure compliance with data protection regulations (GDPR, etc.)

## Support

For issues during deployment, check:
- Flutter documentation: https://flutter.dev/docs/deployment
- Firebase documentation: https://firebase.google.com/docs
- Stack Overflow: Search for specific error messages

