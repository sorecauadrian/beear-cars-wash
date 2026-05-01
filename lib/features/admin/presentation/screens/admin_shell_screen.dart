import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_icons.dart';
import 'package:go_router/go_router.dart';

class AdminShellScreen extends StatefulWidget {
  final Widget child;

  const AdminShellScreen({super.key, required this.child});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _lastTabIndex = 0;
  int _slideDirection = 1; // 1 = incoming tab is to the right, -1 = to the left

  int _currentIndex() {
    final location = GoRouterState.of(context).uri.toString();
    if (location == RouteNames.adminHome) return 0;
    if (location.startsWith(RouteNames.adminBookings)) return 1;
    if (location.startsWith(RouteNames.companiesList)) return 2;
    if (location.startsWith(RouteNames.serviceRecordsList)) return 3;
    if (location == RouteNames.adminMore) return 4;
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
