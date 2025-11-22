# Beear Cars Wash

B2B on-site car wash service mobile app for Beear Cars Wash.

## Tech Stack

- **Flutter 3.x** - Cross-platform mobile framework
- **Firebase** - Authentication, Firestore, Cloud Messaging
- **Riverpod** - State management
- **Google Maps** - Location selection
- **Mobile Scanner** - License plate scanning

## Features

- 🔐 Email/password authentication
- 🚗 Vehicle management per company
- 📅 Booking creation and management
- 👥 Role-based access (BeeAR Admin, Company Admin)
- 📱 Push notifications
- 📍 Map-based location selection
- 📸 License plate scanning

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/beear-cars-wash.git
   cd beear-cars-wash
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a Firebase project
   - Add Android app (package: `com.beear.carswash`)
   - Add iOS app (bundle: `com.beear.carswash`)
   - Download config files and place them in:
     - `android/app/src/dev/google-services.json`
     - `android/app/src/prod/google-services.json`
     - `ios/Runner/GoogleService-Info-Dev.plist`
     - `ios/Runner/GoogleService-Info-Prod.plist`

4. **Run the app**
   ```bash
   flutter run
   ```

## Documentation

- [Implementation Plan](IMPLEMENTATION_PLAN.md)
- [Phase 1 Complete](docs/PHASE_1_COMPLETE.md)
- [GitHub Setup Guide](docs/GITHUB_SETUP.md)
- [Store Setup Guide](docs/STORE_SETUP.md) (coming soon)

## Project Structure

```
lib/
├── core/           # Core utilities, theme, routing
├── features/        # Feature modules (auth, companies, vehicles, bookings)
└── shared/         # Shared widgets and components
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Development Status

🚧 **In Development** - MVP Phase

Current phase: Project bootstrap complete. Authentication and core features in progress.
