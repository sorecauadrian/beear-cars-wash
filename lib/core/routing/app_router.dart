import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/vehicles/presentation/screens/vehicles_list_screen.dart';
import '../../features/vehicles/presentation/screens/add_vehicle_screen.dart';
import '../../features/vehicles/presentation/screens/edit_vehicle_screen.dart';
import '../../features/bookings/presentation/screens/create_booking_screen.dart';
import '../../features/bookings/presentation/screens/admin/admin_bookings_list_screen.dart';
import '../../features/companies/presentation/screens/companies_list_screen.dart';
import '../../features/companies/presentation/screens/add_company_screen.dart';
import '../../features/companies/presentation/screens/edit_company_screen.dart';
// TODO: Import more screens as they are created

/// Application router configuration
class AppRouter {
  AppRouter._();

  static GoRouter get router => _router;

  static final _router = GoRouter(
    initialLocation: RouteNames.login,
    redirect: (context, state) {
      // This will be handled by auth state listener
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Company Admin routes
      GoRoute(
        path: RouteNames.companyHome,
        builder: (context, state) => const VehiclesListScreen(),
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
        builder: (context, state) => const AddCompanyScreen(),
      ),
      GoRoute(
        path: '${RouteNames.editCompany}/:id',
        builder: (context, state) {
          final companyId = state.pathParameters['id']!;
          return EditCompanyScreen(companyId: companyId);
        },
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

