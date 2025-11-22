# Firebase Setup Guide

This guide will walk you through setting up Firebase for the Beear Cars Wash app.

## Prerequisites

- A Google account
- Access to [Firebase Console](https://console.firebase.google.com/)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: **"Beear Cars Wash"** (or your preferred name)
4. Click **Continue**
5. **Google Analytics**: 
   - You can enable it (recommended for production) or disable it for now
   - If enabled, select or create an Analytics account
6. Click **Create project**
7. Wait for project creation (usually 30-60 seconds)
8. Click **Continue**

## Step 2: Add Android App

1. In the Firebase project overview, click the **Android icon** (or **"Add app"** → Android)
2. Fill in the details:
   - **Android package name**: `com.beear.carswash`
   - **App nickname** (optional): `Beear Cars Wash Android`
   - **Debug signing certificate SHA-1** (optional for now, needed later for release)
3. Click **Register app**
4. Download the `google-services.json` file
5. **Place the file**:
   - For simple setup: `android/app/google-services.json`
   - For dev/prod flavors: 
     - Dev: `android/app/src/dev/google-services.json`
     - Prod: `android/app/src/prod/google-services.json`
6. Click **Next** → **Next** → **Continue to console**

### Getting SHA-1 Certificate (for later)

You'll need this for release builds and some Firebase features (like Dynamic Links).

**Where to run these commands:**
- Open **PowerShell** or **Command Prompt** (CMD)
- Navigate to your project directory: `cd c:\Users\aicoIntern5\beear_cars_wash`
- Or run from any directory (the paths are absolute)

**Commands:**

```bash
# For debug keystore (default - use this for development)
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# For release keystore (after you create it - for production)
keytool -list -v -keystore android/app/keystore.jks -alias beear
```

**What to do with the output:**
1. Look for the line that says `SHA1: XX:XX:XX:...`
2. Copy the SHA-1 fingerprint (the hex string)
3. Go to Firebase Console → **Project Settings** → **Your Android App**
4. Click **"Add fingerprint"** and paste the SHA-1
5. Click **Save**

**Note:** For MVP/development, you can skip this step. It's mainly needed for:
- Release builds on Google Play
- Firebase Dynamic Links
- Some advanced Firebase features

## Step 3: Add iOS App

1. In Firebase project overview, click the **iOS icon** (or **"Add app"** → iOS)
2. Fill in the details:
   - **iOS bundle ID**: `com.beear.carswash`
   - **App nickname** (optional): `Beear Cars Wash iOS`
   - **App Store ID** (optional, leave blank for now)
3. Click **Register app**
4. Download the `GoogleService-Info.plist` file
5. **Place the file**:
   - For simple setup: `ios/Runner/GoogleService-Info.plist`
   - For dev/prod flavors:
     - Dev: `ios/Runner/GoogleService-Info-Dev.plist`
     - Prod: `ios/Runner/GoogleService-Info-Prod.plist`
6. **⚠️ IMPORTANT**: When Firebase Console shows "Add initialization code" step:
   - **SKIP THIS STEP** - You don't need to add the Swift code!
   - Flutter handles Firebase initialization automatically through `firebase_core`
   - Just click **"Continue to console"** or **"Next"** to finish
7. Make sure the file is added to Xcode project (see Step 6 below)

## Step 4: Enable Firebase Services

### 4.1 Authentication

1. In Firebase Console, go to **Build** → **Authentication**
2. Click **Get started**
3. Go to **Sign-in method** tab
4. Enable **Email/Password**:
   - Click on **Email/Password**
   - Toggle **Enable**
   - Click **Save**

### 4.2 Cloud Firestore

1. In Firebase Console, go to **Build** → **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
   - ⚠️ **Important**: We'll set up security rules later
4. Select a **location** (choose closest to Romania, e.g., `europe-west`)
5. Click **Enable**

### 4.3 Cloud Messaging (FCM)

1. In Firebase Console, go to **Run** → **Messaging**
   - **Note**: In newer Firebase Console, it's under "Run" category, not "Build"
2. FCM is **automatically enabled** when you add Android and iOS apps - no action needed!
3. You'll see the Messaging dashboard - this is normal. You don't need to create any campaigns yet.
4. For iOS push notifications (can be done later):
   - Go to **Project Settings** → **Cloud Messaging** tab
   - Under **Apple app configuration**, upload APNs certificate/key
   - This is only needed when you want to send push notifications to iOS devices
   - For MVP/development, you can skip this

## Step 5: Configure Android Build

The `google-services.json` file should be automatically processed by the Gradle plugin.

Verify in `android/app/build.gradle.kts` that you have:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Add this if not present
}
```

If the plugin isn't there, add it to `android/build.gradle.kts`:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

## Step 6: Configure iOS Build

1. Open `ios/Runner.xcworkspace` in Xcode
   - **Note**: Open `.xcworkspace`, NOT `.xcodeproj`
   - You can do this from Android Studio: Right-click `ios/Runner.xcworkspace` → **Open in Xcode**
   - Or from terminal: `open ios/Runner.xcworkspace` (Mac) or double-click the file

2. Verify `GoogleService-Info.plist` is in the project:
   - In Xcode, look in the left sidebar (Project Navigator)
   - You should see `GoogleService-Info.plist` under the `Runner` folder
   - If you DON'T see it:
     - Right-click `Runner` folder → **Add Files to "Runner"**
     - Navigate to and select `GoogleService-Info.plist`
     - **IMPORTANT**: Uncheck **"Copy items if needed"** (file is already in the right place)
     - Check **"Runner"** target
     - Click **Add**

3. Verify it's included in the build:
   - Click on `GoogleService-Info.plist` in Xcode
   - In the right panel, check **"Target Membership"**
   - Make sure **"Runner"** is checked ✅

## Step 7: Test Firebase Connection

1. Run the app:
   ```bash
   flutter run
   ```

2. Check the console logs:
   - ✅ Should see: `✅ Firebase initialized successfully`
   - ❌ If you see an error, check that config files are in the correct locations

## Step 8: Set Up Firestore Security Rules (Important!)

⚠️ **Do this after testing, but before production!**

1. In Firebase Console → **Firestore Database** → **Rules**
2. Replace with these basic rules (we'll refine them later):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read their own data
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Companies - read for admins, write for bee_admin only
    match /companies/{companyId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/users/$(request.auth.uid)).data.role == 'bee_admin';
    }
    
    // Vehicles - company admins can manage their company's vehicles
    match /vehicles/{vehicleId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.companyId == get(/databases/$(database)/users/$(request.auth.uid)).data.companyId ||
         get(/databases/$(database)/users/$(request.auth.uid)).data.role == 'bee_admin');
    }
    
    // Bookings - similar rules
    match /bookings/{bookingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && 
        get(/databases/$(database)/users/$(request.auth.uid)).data.role == 'bee_admin';
    }
  }
}
```

3. Click **Publish**

## Step 9: Environment Setup (Optional - for Dev/Prod)

If you want separate Firebase projects for dev and prod:

1. Create two Firebase projects:
   - `beear-cars-wash-dev`
   - `beear-cars-wash-prod`

2. Add both Android and iOS apps to each project

3. Download config files:
   - Dev: `google-services.json` → `android/app/src/dev/`
   - Prod: `google-services.json` → `android/app/src/prod/`
   - Dev: `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info-Dev.plist`
   - Prod: `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info-Prod.plist`

4. Update `firebase_config.dart` to select the right config based on build flavor

## Troubleshooting

### Android: "google-services.json not found"
- Make sure the file is in `android/app/google-services.json`
- Or in `android/app/src/dev/` or `android/app/src/prod/` for flavors
- Run `flutter clean` and rebuild

### iOS: "GoogleService-Info.plist not found"
- Make sure the file is added to the Xcode project
- Check that it's included in the Runner target
- Clean build folder in Xcode (Cmd+Shift+K)

### Firebase initialization fails
- Check that config files are in correct locations
- Verify package names/bundle IDs match exactly
- Check Firebase Console that apps are registered
- Run `flutter clean` and rebuild

### Authentication not working
- Verify Email/Password is enabled in Firebase Console
- Check that Firestore rules allow authentication
- Check app logs for specific error messages

## Next Steps

After Firebase is set up:
1. ✅ Test authentication (Phase 3)
2. ✅ Create data models (Phase 4)
3. ✅ Implement features (Phase 5-6)
4. ✅ Set up push notifications (Phase 7)

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

