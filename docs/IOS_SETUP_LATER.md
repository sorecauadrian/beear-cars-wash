# iOS Setup - For Later (When You Have Mac/Xcode Access)

This document contains iOS-specific setup steps that were skipped during initial Firebase setup.

## Prerequisites

- Mac computer with Xcode installed
- iOS device or simulator for testing

## Step 1: Verify GoogleService-Info.plist in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
   - **Important**: Open `.xcworkspace`, NOT `.xcodeproj`
   - You can do this from terminal: `open ios/Runner.xcworkspace`

2. In Xcode, check the left sidebar (Project Navigator):
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

## Step 2: iOS Push Notifications Setup (APNs)

To enable push notifications on iOS devices, you need to configure Apple Push Notification service (APNs).

### 2.1 Create APNs Key in Apple Developer Account

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Sign in with your Apple Developer account
3. Go to **Certificates, Identifiers & Profiles**
4. Click **Keys** → **+** (Create a new key)
5. Enter a name (e.g., "Beear Cars Wash Push Key")
6. Check **Apple Push Notifications service (APNs)**
7. Click **Continue** → **Register**
8. **Download the key** (`.p8` file) - you can only download it once!
9. **Note the Key ID** - you'll need it

### 2.2 Upload APNs Key to Firebase

1. Go to Firebase Console → Your project
2. Go to **Project Settings** (gear icon)
3. Click **Cloud Messaging** tab
4. Scroll to **Apple app configuration**
5. Under **APNs Authentication Key**:
   - Click **Upload**
   - Select the `.p8` key file you downloaded
   - Enter the **Key ID** (from Apple Developer Portal)
   - Enter your **Team ID** (found in Apple Developer Portal → Membership)
6. Click **Upload**

### 2.3 Alternative: APNs Certificate (Older Method)

If you prefer using certificates instead of keys:

1. In Apple Developer Portal → **Certificates**
2. Create a new certificate for **Apple Push Notification service SSL**
3. Download the certificate
4. Convert to `.p12` format (if needed)
5. Upload to Firebase Console → Project Settings → Cloud Messaging → APNs Certificates

## Step 3: Configure iOS Capabilities in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project in the left sidebar
3. Select **Runner** target
4. Go to **Signing & Capabilities** tab
5. Click **+ Capability**
6. Add **Push Notifications**
7. Add **Background Modes** and check:
   - ✅ Remote notifications

## Step 4: Update Info.plist (if needed)

Usually not needed, but verify:
- Open `ios/Runner/Info.plist`
- Make sure it has proper bundle identifier: `com.beear.carswash`

## Step 5: Test iOS Push Notifications

1. Build and run on a physical iOS device (push notifications don't work on simulator)
2. The app should register for push notifications automatically
3. You can test sending notifications from:
   - Firebase Console → Cloud Messaging → Send test message
   - Or through your app's notification implementation

## Troubleshooting

### "No valid 'aps-environment' entitlement"
- Make sure Push Notifications capability is added in Xcode
- Check that your provisioning profile includes push notifications

### Notifications not received
- Verify APNs key/certificate is uploaded to Firebase
- Check that device token is being registered
- Ensure app has notification permissions

### Build errors
- Make sure you're opening `.xcworkspace`, not `.xcodeproj`
- Clean build folder: Product → Clean Build Folder (Shift+Cmd+K)
- Delete DerivedData if needed

## Notes

- Push notifications require a **physical iOS device** - they don't work on simulator
- APNs key (`.p8`) can only be downloaded once - keep it secure!
- You need an Apple Developer account ($99/year) for production push notifications
- For development, you can use a free Apple Developer account with limitations

## When to Do This

- When you're ready to test on iOS devices
- When you need to implement push notifications for iOS
- Before publishing to App Store

