# Firestore Indexes - What You Need to Know

## Why Do I Need to Create Indexes?

Firestore requires **composite indexes** for queries that:
- Filter on multiple fields
- Order by a field that's different from the filter field
- Use range filters on different fields

This is **normal and expected** - Firestore will prompt you when an index is needed.

## What Happened

When you logged in as a company admin, the app queried vehicles with:
- `where('companyId', isEqualTo: companyId)` - filter
- `.orderBy('plateNumber')` - ordering

This combination requires a composite index.

## How to Handle Indexes

### Option 1: Click the Link (Easiest)
- When Firestore shows the error with a link, click it
- It will open Firebase Console with the index pre-configured
- Click "Create Index"
- Wait for it to build (usually 1-2 minutes)

### Option 2: Create Manually
1. Go to Firebase Console → Firestore Database → **Indexes** tab
2. Click **"Create Index"**
3. Collection: `vehicles`
4. Fields:
   - `companyId` (Ascending)
   - `plateNumber` (Ascending)
5. Click **Create**

## Common Indexes You'll Need

As we add more features, you might need indexes for:

1. **Vehicles** (already created):
   - `companyId` + `plateNumber`

2. **Bookings** (will need later):
   - `companyId` + `date` + `slotStart`
   - `date` + `status` + `slotStart`
   - `companyId` + `status` + `date`

3. **Users**:
   - Usually no indexes needed for basic queries

## Important Notes

- ✅ Indexes are **one-time setup** - create once, use forever
- ✅ Firestore will **automatically prompt** you when needed
- ✅ Indexes take **1-2 minutes** to build
- ✅ The app will work once the index is built
- ⚠️ Don't worry about creating indexes in advance - Firestore will tell you when needed

## Best Practice

Just click the link when prompted - it's the easiest way! Firestore makes it very easy to create the exact index you need.

