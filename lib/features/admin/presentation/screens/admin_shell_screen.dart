import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import 'package:go_router/go_router.dart';

class AdminShellScreen extends StatelessWidget {
  final Widget child;

  const AdminShellScreen({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == RouteNames.adminHome) return 0;
    if (location.startsWith(RouteNames.adminBookings)) return 1;
    if (location.startsWith(RouteNames.companiesList)) return 2;
    if (location.startsWith(RouteNames.serviceRecordsList)) return 3;
    if (location == RouteNames.adminMore) return 4;
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
            top: BorderSide(color: AppColors.outline.withValues(alpha: 0.5), width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            HapticFeedback.lightImpact();
            switch (i) {
              case 0:
                context.go(RouteNames.adminHome);
                break;
              case 1:
                context.go(RouteNames.adminBookings);
                break;
              case 2:
                context.go(RouteNames.companiesList);
                break;
              case 3:
                context.go(RouteNames.serviceRecordsList);
                break;
              case 4:
                context.go(RouteNames.adminMore);
                break;
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Acasă',
            ),
            NavigationDestination(
              icon: Icon(AppIcons.bookings),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Rezervări',
            ),
            NavigationDestination(
              icon: Icon(AppIcons.companies),
              selectedIcon: Icon(Icons.business),
              label: 'Clienți',
            ),
            NavigationDestination(
              icon: Icon(AppIcons.serviceRecords),
              selectedIcon: Icon(Icons.description),
              label: 'Registre',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_outlined),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'Mai mult',
            ),
          ],
        ),
      ),
    );
  }
}
