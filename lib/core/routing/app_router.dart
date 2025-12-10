import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'route_names.dart';
import '../../core/widgets/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/customer_home_screen.dart';
import '../../features/vehicles/presentation/screens/add_vehicle_screen.dart';
import '../../features/vehicles/presentation/screens/edit_vehicle_screen.dart';
import '../../features/vehicles/presentation/screens/vehicles_list_wrapper_screen.dart';
import '../../features/bookings/presentation/screens/create_booking_screen.dart';
import '../../features/bookings/presentation/screens/admin/admin_bookings_list_screen.dart';
import '../../features/companies/presentation/screens/companies_list_screen.dart';
import '../../features/companies/presentation/screens/add_company_screen.dart';
import '../../features/companies/presentation/screens/edit_company_screen.dart';
import '../../features/companies/data/models/company_model.dart';
import '../../features/service_records/presentation/screens/service_records_list_screen.dart';
import '../../features/pricing/presentation/screens/pricing_screen.dart';
import '../../features/settings/presentation/screens/admin_settings_screen.dart';
import '../../features/settings/presentation/screens/customer_settings_screen.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
// TODO: Import more screens as they are created

/// Application router configuration
class AppRouter {
  AppRouter._();

  static GoRouter get router => _router;

  static final _router = GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) async {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final isLoginPage = state.uri.toString() == RouteNames.login;
      final isSplashPage = state.uri.toString() == RouteNames.splash;

      // If user is logged in and on login/splash, redirect to appropriate home
      if (firebaseUser != null && (isLoginPage || isSplashPage)) {
        // Get user data to determine role
        try {
          final authRepo = AuthRepository();
          final userData = await authRepo.getUserData(firebaseUser.uid);
          if (userData.isAdmin) {
            return RouteNames.adminHome;
          } else {
            return RouteNames.companyHome;
          }
        } catch (e) {
          // If we can't get user data, stay on login
          return null;
        }
      }

      // If user is not logged in and trying to access protected routes, redirect to login
      if (firebaseUser == null && !isLoginPage && !isSplashPage) {
        return RouteNames.login;
      }

      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => SplashScreen(
          onComplete: () {
            context.go(RouteNames.login);
          },
        ),
      ),
      // Auth routes
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Company Admin routes
      GoRoute(
        path: RouteNames.companyHome,
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.addVehicle,
        builder: (context, state) => const AddVehicleScreen(),
      ),
      GoRoute(
        path: '${RouteNames.editVehicle}/:id',
        builder: (context, state) {
          final vehicleId = state.pathParameters['id']!;
          return EditVehicleScreen(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: RouteNames.createBooking,
        builder: (context, state) => const CreateBookingScreen(),
      ),
      GoRoute(
        path: RouteNames.vehiclesList,
        builder: (context, state) => const VehiclesListWrapperScreen(),
      ),
      GoRoute(
        path: RouteNames.customerSettings,
        builder: (context, state) => const CustomerSettingsScreen(),
      ),
      // GoRoute(
      //   path: RouteNames.createBooking,
      //   builder: (context, state) => const CreateBookingScreen(),
      // ),
      // GoRoute(
      //   path: RouteNames.bookingDetails,
      //   builder: (context, state) {
      //     final bookingId = state.pathParameters['id']!;
      //     return BookingDetailsScreen(bookingId: bookingId);
      //   },
      // ),

      // BeeAR Admin routes
      GoRoute(
        path: RouteNames.adminHome,
        builder: (context, state) => const AdminBookingsListScreen(),
      ),
      GoRoute(
        path: RouteNames.companiesList,
        builder: (context, state) => const CompaniesListScreen(),
      ),
      GoRoute(
        path: RouteNames.addCompany,
        builder: (context, state) {
          final typeParam = state.uri.queryParameters['type'];
          ClientType? clientType;
          if (typeParam == 'juridica') {
            clientType = ClientType.persoanaJuridica;
          } else if (typeParam == 'fizica') {
            clientType = ClientType.persoanaFizica;
          }
          return AddCompanyScreen(initialClientType: clientType);
        },
      ),
      GoRoute(
        path: '${RouteNames.editCompany}/:id',
        builder: (context, state) {
          final companyId = state.pathParameters['id']!;
          return EditCompanyScreen(companyId: companyId);
        },
      ),
      GoRoute(
        path: RouteNames.serviceRecordsList,
        builder: (context, state) => const ServiceRecordsListScreen(),
      ),
      GoRoute(
        path: RouteNames.pricing,
        builder: (context, state) => const PricingScreen(),
      ),
      GoRoute(
        path: RouteNames.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      // GoRoute(
      //   path: RouteNames.adminBookingsList,
      //   builder: (context, state) => const AdminBookingsListScreen(),
      // ),
      // GoRoute(
      //   path: RouteNames.adminBookingDetails,
      //   builder: (context, state) {
      //     final bookingId = state.pathParameters['id']!;
      //     return AdminBookingDetailsScreen(bookingId: bookingId);
      //   },
      // ),
      // GoRoute(
      //   path: RouteNames.companiesList,
      //   builder: (context, state) => const CompaniesListScreen(),
      // ),
      // GoRoute(
      //   path: RouteNames.addCompany,
      //   builder: (context, state) => const AddCompanyScreen(),
      // ),
      // GoRoute(
      //   path: RouteNames.editCompany,
      //   builder: (context, state) {
      //     final companyId = state.pathParameters['id']!;
      //     return EditCompanyScreen(companyId: companyId);
      //   },
      // ),
    ],
  );
}

