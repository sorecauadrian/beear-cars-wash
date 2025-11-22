# Beear Cars Wash - Implementation Plan

## 1. Project Structure

```
beear_cars_wash/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── firestore_paths.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   ├── routing/
│   │   │   ├── app_router.dart
│   │   │   └── route_names.dart
│   │   ├── widgets/
│   │   │   ├── loading_indicator.dart
│   │   │   └── error_widget.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       └── date_time_utils.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── user_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository.dart
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   └── auth_provider.dart
│   │   │   │   └── screens/
│   │   │   │       └── login_screen.dart
│   │   ├── companies/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── company_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── company_repository.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── company_provider.dart
│   │   │       └── screens/
│   │   │           └── companies_list_screen.dart
│   │   ├── vehicles/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── vehicle_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── vehicle_repository.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── vehicle_provider.dart
│   │   │       └── screens/
│   │   │           ├── vehicles_list_screen.dart
│   │   │           ├── add_vehicle_screen.dart
│   │   │           └── edit_vehicle_screen.dart
│   │   ├── bookings/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── booking_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── booking_repository.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── booking_provider.dart
│   │   │       └── screens/
│   │   │           ├── create_booking_screen.dart
│   │   │           ├── booking_details_screen.dart
│   │   │           └── admin/
│   │   │               └── admin_bookings_list_screen.dart
│   │   └── notifications/
│   │       ├── data/
│   │       │   └── repositories/
│   │       │       └── notification_repository.dart
│   │       └── presentation/
│   │           └── providers/
│   │               └── notification_provider.dart
│   └── shared/
│       └── widgets/
│           ├── custom_button.dart
│           ├── custom_text_field.dart
│           └── booking_status_chip.dart
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/
│   │       ├── dev/
│   │       │   └── google-services.json (placeholder)
│   │       └── prod/
│   │           └── google-services.json (placeholder)
├── ios/
│   ├── Runner/
│   │   ├── GoogleService-Info-Dev.plist (placeholder)
│   │   └── GoogleService-Info-Prod.plist (placeholder)
│   └── Runner.xcodeproj/
├── assets/
│   └── images/
│       └── logo.png
├── pubspec.yaml
├── flutter_launcher_icons.yaml
├── flutter_native_splash.yaml
└── docs/
    └── STORE_SETUP.md
```

## 2. Main Packages & Dependencies

### Core Dependencies
- `flutter` (SDK)
- `firebase_core` - Firebase initialization
- `firebase_auth` - Email/password authentication
- `cloud_firestore` - Database
- `firebase_messaging` - Push notifications
- `google_maps_flutter` - Map location selection
- `flutter_riverpod` - State management (simple & robust)
- `go_router` - Declarative routing
- `intl` - Date/time formatting
- `uuid` - Generate unique IDs

### Dev Dependencies
- `flutter_launcher_icons` - Generate app icons
- `flutter_native_splash` - Generate splash screen
- `flutter_lints` - Linting rules

### Optional (for later)
- `flutter_local_notifications` - Local notifications
- `geolocator` - Get current location

## 3. Architecture Approach

### State Management: Riverpod
- **Why**: Simple, robust, type-safe, minimal boilerplate
- **Pattern**: Provider-based, with repositories for data access
- **Structure**: 
  - `*_provider.dart` files for each feature
  - Repositories abstract Firestore calls
  - Easy to swap Firebase for another backend later

### Routing: go_router
- **Why**: Declarative, type-safe, supports deep linking
- **Structure**:
  - Role-based route guards
  - Separate route trees for authenticated/unauthenticated
  - Named routes for easy navigation

### Data Layer
- **Models**: Plain Dart classes with `fromMap`/`toMap`
- **Repositories**: Abstract Firestore operations
- **Providers**: Expose data and business logic to UI

### Theme
- Primary color: `#00395E` (dark blue from logo)
- Secondary: White
- Material Design 3 components

## 4. Data Models

### User Model
```dart
- id: String
- name: String
- email: String
- role: enum (beeAdmin, companyAdmin, worker)
- companyId: String? (nullable for beeAdmin)
```

### Company Model
```dart
- id: String
- name: String
- contractNumber: String
- city: String
- isActive: bool
```

### Vehicle Model
```dart
- id: String
- companyId: String
- plateNumber: String
- description: String?
```

### Booking Model
```dart
- id: String
- companyId: String
- vehicleId: String
- washType: enum (interior, exterior, cosmetic, all)
- addressText: String
- lat: double?
- lng: double?
- date: String (YYYY-MM-DD)
- slotStart: String (HH:mm)
- slotEnd: String (HH:mm)
- status: enum (requested, accepted, rejected, in_progress, done)
- createdAt: Timestamp
- updatedAt: Timestamp
```

## 5. Initial Screens & Navigation Flow

### Unauthenticated Flow
1. **Login Screen**
   - Email/password fields
   - Login button
   - Error handling

### Authenticated Flow (Role-based)

#### BeeAR Admin
1. **Admin Home** (Bookings List)
   - All bookings with filters (date, company, status)
   - Status change actions
   - Navigation to company management

2. **Companies List Screen**
   - View all companies
   - Create/edit company (if time allows)

3. **Booking Details Screen**
   - View full booking info
   - Change status actions

#### Company Admin
1. **Company Home** (Vehicles List)
   - List of company vehicles
   - Add/Edit/Delete vehicles
   - Navigation to create booking

2. **Create Booking Screen**
   - Vehicle selector
   - Wash type selector
   - Address input + optional map picker
   - Date picker
   - Time slot selector (08:00-18:00, 30-min slots)
   - Submit button

3. **Booking Details Screen** (read-only)
   - View booking status and details

## 6. Implementation Phases

### Phase 1: Project Bootstrap
- [ ] Create Flutter project with correct package IDs
- [ ] Add all dependencies to `pubspec.yaml`
- [ ] Set up folder structure
- [ ] Configure theme with brand colors
- [ ] Set up basic routing skeleton
- [ ] Configure Android/iOS for Firebase (placeholders)

### Phase 2: Firebase Integration
- [ ] Initialize Firebase in `main.dart`
- [ ] Create environment config structure (dev/prod)
- [ ] Set up Firestore paths constants
- [ ] Ensure Android/iOS builds compile

### Phase 3: Authentication
- [ ] Create User model
- [ ] Create AuthRepository
- [ ] Create AuthProvider (Riverpod)
- [ ] Build LoginScreen
- [ ] Implement role-based routing after login
- [ ] Add auth state persistence

### Phase 4: Core Data Models & Repositories
- [ ] Company model & repository
- [ ] Vehicle model & repository
- [ ] Booking model & repository
- [ ] Notification repository (FCM setup)

### Phase 5: Company Admin Features
- [ ] Vehicles list screen
- [ ] Add/Edit vehicle screens
- [ ] Create booking screen (with map picker)
- [ ] Booking details screen (read-only)

### Phase 6: BeeAR Admin Features
- [ ] Admin bookings list with filters
- [ ] Booking status management
- [ ] Companies list screen (basic)

### Phase 7: Notifications
- [ ] FCM token registration
- [ ] Cloud Functions triggers (or manual notification sending)
- [ ] Handle notification taps
- [ ] Update UI on notification received

### Phase 8: Polish & Store Readiness
- [ ] Configure app icons (flutter_launcher_icons)
- [ ] Configure splash screen (flutter_native_splash)
- [ ] Add error handling & loading states
- [ ] Create STORE_SETUP.md documentation
- [ ] Test on both platforms

## 7. Key Design Decisions

### Simple Over Complex
- **No complex state machines** - Simple status enums
- **No offline-first** - Firestore handles sync
- **No complex validation** - Basic checks only
- **Manual conflict resolution** - Admin handles overlaps

### Extensibility
- Repository pattern allows backend swap
- Provider pattern allows state management swap
- Feature-based structure allows easy additions

### MVP Scope
- **Included**: Auth, vehicles, bookings, basic admin
- **Excluded**: Recurring bookings, chat, payments, advanced stats
- **Future**: Worker role, advanced filters, analytics

## 8. Firebase Setup Requirements

### Collections Structure
```
companies/
  {companyId}/
    - name, contractNumber, city, isActive

users/
  {userId}/
    - name, email, role, companyId

vehicles/
  {vehicleId}/
    - companyId, plateNumber, description

bookings/
  {bookingId}/
    - companyId, vehicleId, washType, addressText, lat, lng,
      date, slotStart, slotEnd, status, createdAt, updatedAt
```

### Security Rules (Basic for MVP)
- Users can read their own data
- Company Admins can read/write their company's vehicles/bookings
- BeeAR Admins can read/write everything

### Cloud Messaging
- FCM tokens stored per user
- Notifications sent on status changes
- Can use Cloud Functions or Admin SDK

## 9. Build Configuration

### Android
- Application ID: `com.beear.carswash`
- Build flavors: `dev`, `prod`
- Separate `google-services.json` per flavor
- Release keystore configuration

### iOS
- Bundle ID: `com.beear.carswash`
- Separate `GoogleService-Info.plist` per environment
- Signing configuration

## 10. Next Steps After Approval

1. **Create Flutter project** with correct configuration
2. **Set up dependencies** and folder structure
3. **Create base architecture** (routing, theme, core widgets)
4. **Implement authentication** flow
5. **Build feature screens** incrementally
6. **Add Firebase integration** step by step
7. **Test and document** store setup process

---

## Questions/Clarifications Needed?

- **Time slot validation**: Should we prevent double bookings in the same slot, or is manual admin management sufficient? (You mentioned manual is OK)
- **Worker role**: Should we create the data model for it now, or wait? (You said optional for later)
- **Company creation**: Should we build the admin UI for creating companies, or is manual Firestore creation acceptable for MVP? (You said manual is OK, but if time allows...)

**Ready to proceed once you approve this plan!**

