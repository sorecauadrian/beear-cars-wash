import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_icons.dart';
import 'package:go_router/go_router.dart';

class CustomerShellScreen extends StatelessWidget {
  final Widget child;

  const CustomerShellScreen({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(RouteNames.companyBookings) ||
        location == RouteNames.companyHome) {
      return 0;
    }
    if (location.startsWith('/company/vehicles')) {
      return 1;
    }
    if (location == RouteNames.customerSettings) {
      return 2;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5), width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            HapticFeedback.lightImpact();
            switch (i) {
              case 0:
                context.go(RouteNames.companyHome);
                break;
              case 1:
                context.go(RouteNames.vehiclesList);
                break;
              case 2:
                context.go(RouteNames.customerSettings);
                break;
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(AppIcons.bookings),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Rezervări',
            ),
            NavigationDestination(
              icon: Icon(AppIcons.vehicles),
              selectedIcon: Icon(Icons.directions_car),
              label: 'Mașini',
            ),
            NavigationDestination(
              icon: Icon(AppIcons.settings),
              selectedIcon: Icon(Icons.settings),
              label: 'Setări',
            ),
          ],
        ),
      ),
    );
  }
}
