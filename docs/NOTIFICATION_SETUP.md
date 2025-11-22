# Notification Setup & Troubleshooting

## Common Issue: MissingPluginException

If you see this error:
```
MissingPluginException(No implementation found for method initialize on channel dexterous
```

**This is NOT a Firebase Messaging issue** - it's a plugin registration issue with `flutter_local_notifications`.

### Solution: Full Rebuild Required

Native plugins (like `flutter_local_notifications`) require a **full rebuild**, not just hot reload/restart.

#### Steps to Fix:

1. **Stop the app completely** (close it on device/emulator)

2. **Clean the build:**
   ```bash
   flutter clean
   ```

3. **Get dependencies:**
   ```bash
   flutter pub get
   ```

4. **Rebuild and run:**
   ```bash
   flutter run
   ```
   Or use Android Studio: Click the **Stop** button, then **Run** again (not just hot reload)

### Why This Happens

- Hot reload/hot restart only updates Dart code
- Native plugins need to be registered in native Android/iOS code
- This registration only happens during a full build

### For MVP Testing

The error is **non-critical** for MVP:
- ✅ FCM token is still saved to Firestore
- ✅ Notifications will work when app is in background/terminated
- ⚠️ Foreground notifications (when app is open) won't show locally, but FCM still receives them

### Verify It's Working

After full rebuild, you should see:
```
✅ Notification service initialized
FCM Token: <your-token-here>
✅ FCM token saved to Firestore
```

### Testing Notifications

1. **Check FCM token is saved:**
   - Go to Firestore → `users` collection
   - Find your user document
   - Verify `fcmToken` field exists

2. **Send test notification:**
   - Firebase Console → Cloud Messaging
   - Click "Send test message"
   - Enter the FCM token from Firestore
   - Send notification
   - You should receive it on your device

3. **Test booking status change:**
   - Login as company admin
   - Create a booking
   - Login as admin
   - Change booking status
   - Check Firestore → `notifications` collection
   - A notification document should be created

## Next Steps for Production

For production, you'll want to:
1. Set up Cloud Functions to process notification documents
2. Send actual push notifications via Firebase Admin SDK
3. Test on real devices (notifications don't work in emulator)

---

**Note**: The `MissingPluginException` is handled gracefully in the code - the app will continue to work, just without local foreground notifications.

