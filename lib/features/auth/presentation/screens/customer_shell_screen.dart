import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_icons.dart';
import 'package:go_router/go_router.dart';

class CustomerShellScreen extends StatefulWidget {
  final Widget child;

  const CustomerShellScreen({super.key, required this.child});

  @override
  State<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends State<CustomerShellScreen> {
  int _lastTabIndex = 0;
  int _slideDirection = 1; // 1 = incoming tab is to the right, -1 = to the left

  int _currentIndex() {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(RouteNames.companyBookings) || location == RouteNames.companyHome) return 0;
    if (location.startsWith('/company/vehicles')) return 1;
    if (location == RouteNames.customerSettings) return 2;
    return 0;
  }

  void _onTabSelected(int i) {
    HapticFeedback.lightImpact();
    setState(() {
      _slideDirection = i > _lastTabIndex ? 1 : -1;
      _lastTabIndex = i;
    });
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
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex();

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) {
          final isEntering = child.key == ValueKey(index);
          final enterOffset = Offset(_slideDirection.toDouble(), 0);
          final exitOffset = Offset(-_slideDirection.toDouble(), 0);
          final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

          return SlideTransition(
            position: Tween<Offset>(
              begin: isEntering ? enterOffset : Offset.zero,
              end: isEntering ? Offset.zero : exitOffset,
            ).animate(curve),
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(index),
          child: widget.child,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _onTabSelected,
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
