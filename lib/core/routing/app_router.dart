import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'route_names.dart';
import '../../core/widgets/splash_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/customer_home_screen.dart';
import '../../features/auth/presentation/screens/customer_shell_screen.dart';
import '../../features/vehicles/presentation/screens/add_vehicle_screen.dart';
import '../../features/vehicles/presentation/screens/edit_vehicle_screen.dart';
import '../../features/vehicles/presentation/screens/vehicles_list_wrapper_screen.dart';
import '../../features/bookings/presentation/screens/create_booking_screen.dart';
import '../../features/bookings/presentation/screens/admin/admin_bookings_list_screen.dart';
import '../../features/admin/presentation/screens/admin_shell_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/companies/presentation/screens/companies_list_screen.dart';
import '../../features/companies/presentation/screens/add_company_screen.dart';
import '../../features/companies/presentation/screens/edit_company_screen.dart';
import '../../features/companies/data/models/company_model.dart';
import '../../features/service_records/presentation/screens/service_records_list_screen.dart';
import '../../features/pricing/presentation/screens/pricing_screen.dart';
import '../../features/settings/presentation/screens/admin_settings_screen.dart';
import '../../features/settings/presentation/screens/customer_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_more_screen.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/screens/terms_and_privacy_screen.dart';

class AppRouter {
  AppRouter._();

  static GoRouter get router => _router;

  static CustomTransitionPage _buildTransition(GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    );
  }

  static final _router = GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) async {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final isLoginPage = state.uri.toString() == RouteNames.login;
      final isSplashPage = state.uri.toString() == RouteNames.splash;

      if (firebaseUser != null && (isLoginPage || isSplashPage)) {
        try {
          final authRepo = AuthRepository();
          final userData = await authRepo.getUserData(firebaseUser.uid);
          if (userData.isAdmin) {
            return RouteNames.adminHome;
          } else {
            return RouteNames.companyHome;
          }
        } catch (e) {
          return null;
        }
      }

      final isAuthPage = isLoginPage ||
          state.uri.toString() == RouteNames.register ||
          state.uri.toString() == RouteNames.forgotPassword ||
          state.uri.toString().startsWith(RouteNames.termsAndPrivacy);
      if (firebaseUser == null && !isAuthPage && !isSplashPage) {
        return RouteNames.login;
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => SplashScreen(
          onComplete: () => context.go(RouteNames.login),
        ),
      ),

      // Auth
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) => _buildTransition(state, const AuthScreen(initialMode: AuthMode.login)),
      ),
      GoRoute(
        path: RouteNames.register,
        pageBuilder: (context, state) => _buildTransition(state, const AuthScreen(initialMode: AuthMode.register)),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        pageBuilder: (context, state) => _buildTransition(state, const AuthScreen(initialMode: AuthMode.forgotPassword)),
      ),
      GoRoute(
        path: RouteNames.termsAndPrivacy,
        pageBuilder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return _buildTransition(
            state,
            TermsAndPrivacyScreen(showTerms: tab != 'privacy'),
          );
        },
      ),

      // ═══ Client shell with bottom navigation ═══
      ShellRoute(
        builder: (context, state, child) => CustomerShellScreen(child: child),
        routes: [
          GoRoute(
            path: RouteNames.companyHome,
            pageBuilder: (context, state) => _buildTransition(state, const CustomerHomeScreen()),
          ),
          GoRoute(
            path: RouteNames.vehiclesList,
            pageBuilder: (context, state) => _buildTransition(state, const VehiclesListWrapperScreen()),
          ),
          GoRoute(
            path: RouteNames.customerSettings,
            pageBuilder: (context, state) => _buildTransition(state, const CustomerSettingsScreen()),
          ),
        ],
      ),

      // Client sub-routes (pushed on top, no bottom nav)
      GoRoute(
        path: RouteNames.addVehicle,
        pageBuilder: (context, state) => _buildTransition(state, const AddVehicleScreen()),
      ),
      GoRoute(
        path: '${RouteNames.editVehicle}/:id',
        pageBuilder: (context, state) {
          final vehicleId = state.pathParameters['id']!;
          return _buildTransition(state, EditVehicleScreen(vehicleId: vehicleId));
        },
      ),
      GoRoute(
        path: RouteNames.createBooking,
        pageBuilder: (context, state) => _buildTransition(state, const CreateBookingScreen()),
      ),

      // ═══ Admin shell with bottom navigation ═══
      ShellRoute(
        builder: (context, state, child) => AdminShellScreen(child: child),
        routes: [
          GoRoute(
            path: RouteNames.adminHome,
            pageBuilder: (context, state) => _buildTransition(state, const AdminDashboardScreen()),
          ),
          GoRoute(
            path: RouteNames.adminBookings,
            pageBuilder: (context, state) => _buildTransition(state, const AdminBookingsListScreen()),
          ),
          GoRoute(
            path: RouteNames.companiesList,
            pageBuilder: (context, state) => _buildTransition(state, const CompaniesListScreen()),
          ),
          GoRoute(
            path: RouteNames.serviceRecordsList,
            pageBuilder: (context, state) => _buildTransition(state, const ServiceRecordsListScreen()),
          ),
          GoRoute(
            path: RouteNames.adminMore,
            pageBuilder: (context, state) => _buildTransition(state, const AdminMoreScreen()),
          ),
        ],
      ),

      // Admin sub-routes (pushed on top, no bottom nav)
      GoRoute(
        path: RouteNames.addCompany,
        pageBuilder: (context, state) {
          final typeParam = state.uri.queryParameters['type'];
          ClientType? clientType;
          if (typeParam == 'juridica') clientType = ClientType.persoanaJuridica;
          if (typeParam == 'fizica') clientType = ClientType.persoanaFizica;
          return _buildTransition(state, AddCompanyScreen(initialClientType: clientType));
        },
      ),
      GoRoute(
        path: '${RouteNames.editCompany}/:id',
        pageBuilder: (context, state) {
          final companyId = state.pathParameters['id']!;
          return _buildTransition(state, EditCompanyScreen(companyId: companyId));
        },
      ),
      GoRoute(
        path: RouteNames.pricing,
        pageBuilder: (context, state) => _buildTransition(state, const PricingScreen()),
      ),
      GoRoute(
        path: RouteNames.adminSettings,
        pageBuilder: (context, state) => _buildTransition(state, const AdminSettingsScreen()),
      ),
    ],
  );
}
