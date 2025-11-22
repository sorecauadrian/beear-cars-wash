# Android Testing Guide for Beear Cars Wash

This guide will help you test the app on an Android device using Android Studio and USB debugging.

## Prerequisites

1. **Android Studio** installed and configured
2. **Android device** (phone/tablet) with USB debugging enabled
3. **USB cable** to connect your device to your computer
4. **Firebase project** set up (see `FIREBASE_SETUP.md`)

## Step 1: Enable USB Debugging on Your Android Device

1. On your Android device, go to **Settings** → **About phone**
2. Tap **Build number** 7 times (you'll see "You are now a developer!")
3. Go back to **Settings** → **Developer options**
4. Enable **USB debugging**
5. Connect your device to your computer via USB
6. When prompted on your device, allow USB debugging and check "Always allow from this computer"

## Step 2: Verify Device Connection

1. Open **Android Studio**
2. Open a terminal in Android Studio (or use PowerShell/Command Prompt)
3. Run:
   ```bash
   flutter devices
   ```
4. You should see your device listed (e.g., `sdk gphone64 arm64` or similar)

If your device is not listed:
- Make sure USB debugging is enabled
- Try a different USB cable
- On your device, check the USB connection notification and select "File Transfer" or "MTP"
- Restart ADB: `adb kill-server` then `adb start-server`

## Step 3: Run the App

### Option A: Using Android Studio

1. Open the project in Android Studio
2. Select your device from the device dropdown (top toolbar)
3. Click the **Run** button (green play icon) or press `Shift + F10`
4. The app will build and install on your device

### Option B: Using Command Line

1. Open terminal in the project root
2. Run:
   ```bash
   flutter run
   ```
3. If multiple devices are connected, select your Android device when prompted

## Step 4: Testing Workflow

### 4.1 Test Admin Login

1. **Create an admin user** (if not already created):
   - Go to Firebase Console → Authentication
   - Add user with email/password
   - Go to Firestore → `users` collection
   - Create document with UID as document ID
   - Add fields: `name`, `email`, `role: "admin"` (no `companyId`)

2. **Login as admin**:
   - Enter email and password
   - Should redirect to "All Bookings" screen
   - Verify logo appears in AppBar

### 4.2 Test Company Management (Admin)

1. **View Companies**:
   - Click the business icon (🏢) in the AppBar
   - Should see list of companies (or empty state)

2. **Add a Company**:
   - Click the "+" floating action button
   - Fill in:
     - Company Name: `Test Company`
     - Contract Number: `CONTRACT-001`
     - City: `Bistrița`
     - Active: `true`
   - Click "Save Company"
   - Verify company appears in the list

3. **Edit a Company**:
   - Tap on a company in the list
   - Modify fields
   - Click "Save"
   - Verify changes are saved

### 4.3 Test Company Admin Login

1. **Create a Company Admin user** (see `CREATE_COMPANY_ADMIN.md`):
   - Create a company first (as above)
   - Create user in Authentication
   - Create user document in Firestore with:
     - Document ID: Firebase Auth UID
     - Fields: `name`, `email`, `role: "company_admin"`, `companyId: <company_id>`

2. **Login as Company Admin**:
   - Logout from admin account
   - Login with company admin credentials
   - Should redirect to "My Vehicles" screen

### 4.4 Test Vehicle Management (Company Admin)

1. **View Vehicles**:
   - Should see empty list or existing vehicles
   - Verify logo appears in AppBar

2. **Add a Vehicle**:
   - Click "+" floating action button
   - Fill in:
     - Plate Number: `AB-12-CDE` (or scan with camera)
     - Description: `Company Car 1`
   - Click "Save"
   - Verify vehicle appears in list

3. **Edit a Vehicle**:
   - Tap on a vehicle
   - Modify fields
   - Click "Save"
   - Verify changes are saved

4. **Delete a Vehicle**:
   - Long press on a vehicle
   - Confirm deletion
   - Verify vehicle is removed

### 4.5 Test Booking Creation (Company Admin)

1. **Create a Booking**:
   - Click "Create Booking" floating action button
   - **Scan License Plate** (optional):
     - Click camera icon
     - Grant camera permission if prompted
     - Point camera at license plate
     - Tap to capture
     - Verify plate number is auto-filled
   - **Select Vehicle**: Choose from dropdown
   - **Select Wash Type**: Choose interior/exterior/cosmetic/all
   - **Enter Address**: Type address text
   - **Select Date**: Tap date field, choose a date
   - **Select Time Slot**: Tap time field, choose a slot (08:00-18:00)
   - Click "Create Booking"
   - Verify success message
   - Verify booking appears in admin's booking list

### 4.6 Test Booking Management (Admin)

1. **View All Bookings**:
   - Login as admin
   - Should see "All Bookings" screen
   - Verify each booking card shows:
     - **Company name** (bold, top)
     - **Date and time** (with calendar icon)
     - **Location/Address** (with location icon)
     - **Wash type**
     - **Status chip** (requested/accepted/rejected/in_progress/done)

2. **Filter Bookings**:
   - Click filter icon (🔍) in AppBar
   - Filter by:
     - Company (dropdown)
     - Date (date picker)
     - Status (dropdown)
   - Click "Apply"
   - Verify filtered results
   - Clear filters to see all bookings

3. **Change Booking Status**:
   - Tap on a booking card
   - Select new status:
     - `requested` → `accepted` or `rejected`
     - `accepted` → `in_progress`
     - `in_progress` → `done`
   - Click "Update Status"
   - Verify status chip updates
   - Verify status change is saved

## Step 5: Common Issues and Solutions

### Issue: App crashes on startup
- **Solution**: Check Firebase configuration files are in place:
  - `android/app/google-services.json` (for Android)
  - Verify Firebase is initialized in `main.dart`

### Issue: "No devices found"
- **Solution**: 
  - Enable USB debugging on device
  - Check USB cable connection
  - Run `adb devices` to verify connection
  - Restart ADB: `adb kill-server && adb start-server`

### Issue: Camera permission denied
- **Solution**: 
  - Go to device Settings → Apps → Beear Cars Wash → Permissions
  - Enable Camera permission
  - Or grant permission when prompted in app

### Issue: Login fails
- **Solution**: 
  - Verify user exists in Firebase Authentication
  - Verify user document exists in Firestore `users` collection
  - Check that `role` field is set correctly
  - Check that `companyId` is set for `company_admin` role

### Issue: Bookings not showing
- **Solution**:
  - Verify Firestore indexes are created (check Firebase Console for index errors)
  - Check that bookings collection exists in Firestore
  - Verify user has correct `companyId` for company admin

### Issue: Company name shows "Unknown Company"
- **Solution**:
  - Verify company document exists in Firestore `companies` collection
  - Check that `companyId` in booking matches company document ID

## Step 6: Hot Reload and Hot Restart

While testing, you can use Flutter's hot reload feature:

- **Hot Reload**: Press `r` in the terminal (quick updates, preserves state)
- **Hot Restart**: Press `R` in the terminal (full restart, resets state)
- **Stop App**: Press `q` in the terminal

## Step 7: View Logs

To see app logs and debug information:

1. In Android Studio: Open **Logcat** tab (bottom panel)
2. Filter by: `flutter` or your package name
3. Or in terminal: Logs appear automatically when running `flutter run`

## Step 8: Build Release APK (Optional)

To test a release build:

```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

Install on device:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Testing Checklist

- [ ] Admin can login
- [ ] Admin can view companies list
- [ ] Admin can add/edit companies
- [ ] Admin can view all bookings
- [ ] Admin can filter bookings (by company, date, status)
- [ ] Admin can change booking status
- [ ] Company Admin can login
- [ ] Company Admin can view vehicles list
- [ ] Company Admin can add/edit/delete vehicles
- [ ] Company Admin can create bookings
- [ ] License plate scanner works (camera permission)
- [ ] Booking cards show company name and location
- [ ] Logo appears in AppBar on all screens
- [ ] Splash screen shows logo
- [ ] App icon shows on device home screen

## Next Steps

After testing:
- Fix any bugs found
- Proceed to Phase 7: Push Notifications (FCM)
- Proceed to Phase 8: Final polish and store setup

---

**Note**: For iOS testing, you'll need a Mac with Xcode. See `IOS_SETUP_LATER.md` for iOS-specific setup.

