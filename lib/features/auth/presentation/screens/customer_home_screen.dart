import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/bookings/presentation/screens/customer/customer_bookings_list_screen.dart';
import 'package:go_router/go_router.dart';

/// Customer home screen - shows reservations by default
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 32, withText: false),
      ),
      drawer: _buildDrawer(context, ref, currentRoute),
      body: const CustomerBookingsListScreen(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(RouteNames.createBooking);
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Rezervare nouă'),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, String currentRoute) {
    final userAsync = ref.watch(currentUserProvider);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary,
            ),
            child: userAsync.when(
              data: (user) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const AppLogo(height: 32, isWhite: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user?.name ?? 'Client',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const AppLogo(height: 32, isWhite: true),
                  const SizedBox(height: 8),
                  Text(
                    'Client',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.event,
            title: 'Rezervările mele',
            isSelected: currentRoute == RouteNames.companyHome,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != RouteNames.companyHome) {
                context.go(RouteNames.companyHome);
              }
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.directions_car,
            title: 'Mașinile mele',
            isSelected: currentRoute == RouteNames.vehiclesList,
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.vehiclesList);
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings,
            title: 'Setări',
            isSelected: currentRoute == RouteNames.customerSettings,
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.customerSettings);
            },
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.logout,
            title: 'Deconectare',
            isSelected: false,
            onTap: () async {
              Navigator.pop(context);
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}

