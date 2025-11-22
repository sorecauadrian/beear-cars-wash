# How to Create a Company Admin User

To test with a `company_admin` role, you need to:
1. Create a company in Firestore first
2. Then create the user document with the companyId

## Step 1: Create a Company in Firestore

1. Go to Firebase Console → **Firestore Database**
2. Click **"Start collection"** (or the **"+"** button)
3. **Collection ID**: Enter `companies` (exactly as shown)
4. Click **Next**

### Add the Company Document

1. **Document ID**: 
   - Click **"Auto-ID"** to toggle it ON (let Firestore generate an ID)
   - Or toggle it OFF and enter a custom ID like `company1`
2. **Add fields** (click "Add field" for each):

   **Field 1:**
   - Field name: `name`
   - Type: `string`
   - Value: `Test Company` (or your company name)

   **Field 2:**
   - Field name: `contractNumber`
   - Type: `string`
   - Value: `CONTRACT-001` (or any contract number)

   **Field 3:**
   - Field name: `city`
   - Type: `string`
   - Value: `Bistrița` (or your city)

   **Field 4:**
   - Field name: `isActive`
   - Type: `boolean`
   - Value: `true`

3. Click **Save**
4. **Copy the Document ID** - you'll need it for the user document!

## Step 2: Create the Company Admin User

### 2.1 Create User in Firebase Authentication

1. Go to Firebase Console → **Authentication**
2. Click **"Add user"**
3. Enter email and password
4. Click **Add user**
5. **Copy the UID** (click on the user to see details)

### 2.2 Create User Document in Firestore

1. Go to Firebase Console → **Firestore Database**
2. Navigate to the `users` collection (or create it if it doesn't exist)
3. Click **"Add document"** (or **"+"** button)
4. **Document ID**: 
   - Toggle **Auto-ID OFF**
   - Paste the **UID** from Authentication
5. **Add fields**:

   **Field 1:**
   - Field name: `name`
   - Type: `string`
   - Value: `Company Admin Name`

   **Field 2:**
   - Field name: `email`
   - Type: `string`
   - Value: Same email as in Authentication

   **Field 3:**
   - Field name: `role`
   - Type: `string`
   - Value: `company_admin`

   **Field 4:**
   - Field name: `companyId`
   - Type: `string`
   - Value: Paste the **company document ID** from Step 1

6. Click **Save**

## Example Structure

### Company Document
```
Collection: companies
Document ID: company123 (or auto-generated)
Fields:
  name: "Test Company"
  contractNumber: "CONTRACT-001"
  city: "Bistrița"
  isActive: true
```

### Company Admin User Document
```
Collection: users
Document ID: [Firebase Auth UID]
Fields:
  name: "John Doe"
  email: "john@company.com"
  role: "company_admin"
  companyId: "company123"  ← Must match company document ID
```

## Quick Checklist

- [ ] Created company in `companies` collection
- [ ] Copied company document ID
- [ ] Created user in Firebase Authentication
- [ ] Copied user UID
- [ ] Created user document in `users` collection
- [ ] Set role to `company_admin`
- [ ] Set companyId to the company document ID

## Testing

After creating both:
1. Log out from the app
2. Log in with the company_admin email/password
3. Should navigate to Company Admin home (vehicles list)
4. User info should show role as `company_admin`

## Troubleshooting

**"User data not found" error:**
- Check that user document ID matches Firebase Auth UID exactly
- Check that collection name is `users` (lowercase, plural)

**Wrong navigation:**
- Verify role is exactly `company_admin` (lowercase, with underscore)
- Check that companyId field exists and has a value

**Company not found:**
- Verify companyId in user document matches a company document ID
- Check that company exists in `companies` collection

