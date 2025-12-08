import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/vehicles/presentation/screens/vehicles_list_screen.dart';
import '../../../../features/bookings/presentation/screens/customer/customer_bookings_list_screen.dart';
import 'package:go_router/go_router.dart';

/// Customer home screen with tabs for vehicles and bookings
class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 32),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[300],
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (index) {
            setState(() {});
          },
          tabs: const [
            Tab(
              icon: Icon(Icons.directions_car),
              text: 'Mașinile mele',
            ),
            Tab(
              icon: Icon(Icons.event),
              text: 'Rezervările mele',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VehiclesListScreen(),
          CustomerBookingsListScreen(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(RouteNames.addVehicle);
              },
              icon: const Icon(Icons.add),
              label: const Text('Adaugă mașină'),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                context.push(RouteNames.createBooking);
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Rezervare nouă'),
            ),
    );
  }
}

