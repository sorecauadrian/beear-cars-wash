# Beear Cars Wash - Mobile Application

## Overview

**Beear Cars Wash** is a comprehensive mobile application designed to streamline on-site car wash services for both businesses and individuals. The app connects service providers (Beear Cars Wash) with clients, enabling efficient booking management, service tracking, and automated invoicing.

The application serves multiple user types:
- **Service Providers (Beear Admin)**: Manage bookings, track services, generate invoices, set pricing, and handle both corporate and individual clients
- **Corporate Clients (Company Admins)**: Create and manage vehicle fleets, book car wash services, track service history, and receive monthly invoices
- **Individual Clients**: Book car wash services for personal vehicles with upfront payment

### Business Models

**B2B (Business-to-Business) - Corporate Clients:**
- Companies receive monthly invoices based on completed services
- Service records are automatically calculated and can be exported
- Invoices include detailed breakdowns of all services rendered
- Post-payment model with invoicing

**B2C (Business-to-Consumer) - Individual Clients:**
- Individuals pay upfront when booking services
- Service records are still tracked and can be viewed
- Same booking and service management features as corporate clients

## What It Does

### For Clients (Both Corporate and Individual)

1. **Vehicle Management**
   - **Corporate Clients**: Add and manage multiple vehicles per company (fleet management)
   - **Individual Clients**: Add and manage personal vehicles
   - Store license plate numbers and vehicle descriptions
   - Quick license plate scanning using mobile camera

2. **Service Booking**
   - Create car wash bookings with flexible scheduling
   - Select from multiple service types (Interior, Exterior, Tapițerie, Complete)
   - Choose specific time slots and locations
   - Book up to 3 vehicles simultaneously
   - View real-time pricing for each service type
   - Map-based location selection with address autocomplete
   - **Individual Clients**: Pay upfront when booking
   - **Corporate Clients**: Book now, pay later via monthly invoice

3. **Booking Management**
   - View all bookings with status tracking
   - See booking history and completed services
   - Real-time status updates (Requested, Accepted, In Progress, Done, Rejected)
   - Access service records and invoices (for both client types)

### For Service Providers (Beear Admin)

1. **Booking Management**
   - View all bookings from all companies
   - Filter by company, date, and status
   - Accept, reject, or update booking status
   - Track service progress in real-time
   - View detailed booking information including vehicle details and locations

2. **Client Management**
   - Create and manage corporate client accounts
   - Create and manage individual client accounts
   - Store company information (name, contract number, city) for businesses
   - Store individual client information
   - Track active and inactive clients

3. **Pricing Management**
   - Set and update prices for each service type
   - Dynamic pricing that updates across the app
   - Visual pricing interface with color-coded service types

4. **Service Records & Invoicing**
   - **Automatic Service Calculation**: System automatically calculates monthly service records from completed bookings
   - **Universal Access**: Both corporate and individual clients can view their service records
   - **Detailed Breakdown**: View service counts per client, per month, with individual booking details
   - **Export Functionality**: Generate professional PDF and Excel invoices/receipts
   - **Invoice Features**:
     - Company logo and branding
     - Detailed service breakdown with dates, times, and locations
     - Vehicle information (license plates)
     - Pricing per service type
     - Monthly totals and summaries
     - **For Companies**: Monthly invoices for accounting
     - **For Individuals**: Service records and receipts
     - Ready for accountant use

5. **Analytics & Reporting**
   - Filter service records by company and month
   - View service statistics and trends
   - Export data for accounting and reporting purposes

## Key Features

### 🔐 Authentication & Security
- Secure email/password authentication via Firebase
- Role-based access control (Admin, Company Admin, Company Worker)
- User session management

### 🚗 Vehicle Management
- **Corporate Clients**: Multi-vehicle fleet support per company
- **Individual Clients**: Personal vehicle management
- License plate scanning using mobile camera
- Vehicle descriptions and notes

### 📅 Booking System
- Flexible time slot selection
- Multiple service types (Interior, Exterior, Tapițerie, Complete)
- Real-time availability checking
- Map-based location selection
- Support for up to 3 vehicles per booking

### 💰 Dynamic Pricing
- Admin-configurable pricing per service type
- Real-time price display for clients
- Automatic price calculation in invoices

### 📊 Automated Service Records
- Automatic calculation from completed bookings
- Monthly service aggregation per client (both corporate and individual)
- Detailed booking breakdown
- Export to PDF and Excel formats
- **Corporate Clients**: Professional monthly invoices for accounting
- **Individual Clients**: Service records and receipts

### 📱 Real-time Updates
- Push notifications for booking status changes
- Real-time data synchronization via Firestore
- Instant status updates across devices

### 🎨 Modern UI/UX
- Material Design 3 interface
- Branded color scheme matching company identity
- Animated splash screen
- Intuitive navigation and user flows
- Responsive design for various screen sizes

### 📍 Location Services
- Google Maps integration
- Address autocomplete
- GPS-based location selection
- Location display in bookings and invoices

## Technology Stack

### Frontend Framework
- **Flutter 3.32.6** - Cross-platform mobile framework
  - Single codebase for Android and iOS
  - Native performance and UI
  - Material Design 3 components

### Backend & Cloud Services
- **Firebase Authentication** - Secure user authentication
- **Cloud Firestore** - Real-time NoSQL database
  - Automatic data synchronization
  - Offline support
  - Scalable cloud infrastructure
- **Firebase Cloud Messaging (FCM)** - Push notifications

### State Management
- **Riverpod 2.6.1** - Reactive state management
  - Type-safe providers
  - Dependency injection
  - Async state handling

### Navigation
- **GoRouter 14.8.2** - Declarative routing
  - Type-safe navigation
  - Deep linking support
  - Route guards and redirects

### Maps & Location
- **Google Maps Flutter** - Interactive maps
- **Geocoding** - Address conversion and autocomplete

### Camera & Scanning
- **Mobile Scanner** - License plate scanning
  - Real-time camera processing
  - OCR capabilities

### Data Export
- **Excel (excel package)** - Excel file generation
- **PDF (pdf package)** - Professional PDF generation
- **Printing** - PDF preview and printing
- **Share Plus** - File sharing capabilities
- **Path Provider** - File system access

### Localization
- **Intl** - Internationalization and date formatting
- **Flutter Localizations** - Romanian language support

### UI Components
- **Material Icons** - Icon library
- **Custom Brand Assets** - Company logos and images

## Architecture

### Clean Architecture Pattern
The application follows a feature-based modular architecture:

```
lib/
├── core/                    # Core application infrastructure
│   ├── config/             # Firebase configuration
│   ├── constants/          # App-wide constants (Firestore paths, etc.)
│   ├── routing/            # Navigation and routing
│   ├── services/           # Core services (notifications, etc.)
│   ├── theme/              # App theming and colors
│   └── widgets/            # Reusable widgets (logo, splash screen)
│
├── features/               # Feature modules
│   ├── auth/               # Authentication
│   │   ├── data/           # Models, repositories
│   │   └── presentation/    # Screens, providers
│   ├── companies/          # Company management
│   ├── vehicles/           # Vehicle management
│   ├── bookings/           # Booking system
│   ├── pricing/            # Pricing management
│   └── service_records/    # Service records and invoicing
│
└── shared/                  # Shared components
    └── widgets/            # Shared UI components
```

### Data Flow
1. **Presentation Layer**: UI screens and widgets
2. **Provider Layer**: Riverpod providers for state management
3. **Repository Layer**: Data access and business logic
4. **Data Layer**: Firestore models and API interactions

## Key Workflows

### Booking Creation Flow
1. Client logs in (corporate or individual) and navigates to booking creation
2. Selects vehicles from their fleet/personal vehicles (up to 3)
3. Chooses service type for each vehicle (with real-time pricing)
4. Selects date and available time slot
5. Picks location using map or address input
6. **Individual Clients**: Pays upfront before submitting booking
7. **Corporate Clients**: Submits booking request (payment via monthly invoice)
8. Receives push notification when booking is accepted/rejected

### Service Completion Flow
1. Admin marks booking as "In Progress" when service starts
2. Admin marks booking as "Done" when service completes
3. System automatically aggregates completed bookings into monthly service records
4. Admin can view and export service records with detailed breakdowns
5. Generated invoices include all booking details, pricing, and totals

### Invoice/Record Generation Flow
1. Admin navigates to Service Records
2. Filters by client (company or individual) and month
3. Views calculated service record with booking breakdown
4. Clicks export button on specific record
5. Chooses PDF or Excel format
6. System generates professional document with:
   - Company logo and branding
   - Client information (company name or individual name)
   - Detailed service list (date, time, vehicle, service type, price)
   - Monthly totals and summary
   - **For Companies**: Monthly invoice for accounting
   - **For Individuals**: Service record/receipt
7. Document is saved and can be shared/printed

## Platform Support

- ✅ **Android** - Full support with native features
- ✅ **iOS** - Full support with native features
- 🔄 **Web** - Partial support (in development)

## Security & Permissions

- **Firebase Security Rules**: Role-based data access
- **Authentication Required**: All features require user authentication
- **Role-Based Access**: Different features for Admin vs Company Admin
- **Data Validation**: Input validation and sanitization
- **Secure Storage**: Sensitive data stored securely in Firestore

## Performance Optimizations

- **Lazy Loading**: Data loaded on-demand
- **Streaming Data**: Real-time updates via Firestore streams
- **Image Optimization**: Compressed assets and efficient loading
- **State Caching**: Riverpod providers cache data efficiently
- **Offline Support**: Firestore offline persistence

## Future Enhancements

- 📊 Advanced analytics and reporting dashboard
- 💳 Payment integration
- 📧 Email notifications
- 🔔 Enhanced push notification system
- 📱 Company Worker role features
- 🌐 Multi-language support expansion
- 📈 Business intelligence and insights
- 🔄 Automated invoice generation
- 📅 Calendar integration
- 🗺️ Route optimization for service providers

## Development Status

✅ **Production Ready** - Core features complete and tested

The application is fully functional with all core features implemented:
- ✅ User authentication and role management
- ✅ Vehicle fleet management
- ✅ Booking creation and management
- ✅ Service tracking and status updates
- ✅ Automated service record calculation
- ✅ Professional invoice generation (PDF/Excel)
- ✅ Pricing management
- ✅ Company management
- ✅ Real-time notifications
- ✅ Modern, branded UI/UX

## Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Firebase project configured
- Android Studio / Xcode for native builds
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd beear_cars_wash
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` for Android
   - Add `GoogleService-Info.plist` for iOS
   - Configure Firestore security rules

4. **Run the application**
   ```bash
   flutter run
   ```

For detailed setup instructions, see the [Firebase Setup Guide](docs/FIREBASE_SETUP.md).

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contact & Support

For questions, support, or feature requests, please contact the development team.

---

**Beear Cars Wash** - Streamlining car wash services for businesses and individuals, one booking at a time. 🚗✨
