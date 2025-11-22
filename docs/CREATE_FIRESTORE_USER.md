# How to Create a User in Firestore

Firestore collections are created automatically when you add data, or you can create them manually. Since we haven't implemented user registration yet, you need to manually create the user document.

## Step-by-Step Instructions

### 1. Get the Firebase Auth UID

1. Go to Firebase Console → **Authentication**
2. You should see your user listed
3. Click on the user to see their details
4. **Copy the UID** (it's a long string like `abc123xyz456...`)

### 2. Create the User Document in Firestore

1. Go to Firebase Console → **Firestore Database**
2. Click **"Start collection"** (or the **"+"** button)
3. **Collection ID**: Enter `users` (exactly as shown)
4. Click **Next**

### 3. Add the Document

1. **Document ID**: 
   - Click **"Auto-ID"** to toggle it OFF
   - Paste the **UID** you copied from Authentication (this is critical - it must match!)
2. **Add fields** (click "Add field" for each):

   **Field 1:**
   - Field name: `name`
   - Type: `string`
   - Value: `Test User` (or your name)

   **Field 2:**
   - Field name: `email`
   - Type: `string`
   - Value: `test@example.com` (must match the email in Authentication)

   **Field 3:**
   - Field name: `role`
   - Type: `string`
   - Value: `admin` (or `company_admin` or `company_worker`)

   **Field 4 (Optional - only for company_admin):**
   - Field name: `companyId`
   - Type: `string`
   - Value: `company123` (or leave empty for bee_admin)

3. Click **Save**

## Example User Documents

### Company Admin User
```
Collection: users
Document ID: [Firebase Auth UID]
Fields:
  name: "John Doe"
  email: "john@company.com"
  role: "company_admin"
  companyId: "company123"
```

### Admin User (BeeAR Admin)
```
Collection: users
Document ID: [Firebase Auth UID]
Fields:
  name: "Admin User"
  email: "admin@beear.com"
  role: "admin"
  (no companyId field, or set to null)
```

### Company Worker User
```
Collection: users
Document ID: [Firebase Auth UID]
Fields:
  name: "Worker Name"
  email: "worker@beear.com"
  role: "company_worker"
  companyId: "company123"
```

## Important Notes

⚠️ **Document ID must match Firebase Auth UID**
- The document ID in Firestore MUST be the same as the user's UID in Firebase Authentication
- This is how the app links the Auth user to their Firestore data

⚠️ **Role values must be exact**
- Use exactly: `admin`, `company_admin`, or `company_worker`
- Not: `bee_admin`, `Bee Admin`, `worker`, etc.

⚠️ **Email should match**
- The email in Firestore should match the email in Firebase Authentication (for consistency)

## Verify It Works

1. After creating the user document, try logging in with the app
2. The app should:
   - Authenticate with Firebase Auth
   - Fetch user data from Firestore
   - Navigate to the appropriate screen based on role

## Troubleshooting

**"User data not found in Firestore" error:**
- Check that the document ID matches the Firebase Auth UID exactly
- Check that the collection name is `users` (lowercase, plural)
- Check that all required fields are present

**Wrong role/navigation:**
- Verify the `role` field value is exactly: `admin`, `company_admin`, or `company_worker`
- Check spelling and case sensitivity
- The code is case-insensitive, but use lowercase for consistency

## Future: Automatic User Creation

In a future update, we can add automatic user document creation when a user signs up, but for now, manual creation is needed for testing.

