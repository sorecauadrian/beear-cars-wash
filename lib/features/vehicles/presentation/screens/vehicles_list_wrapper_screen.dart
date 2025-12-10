import 'package:flutter/material.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/routing/route_names.dart';
import 'vehicles_list_screen.dart';
import 'package:go_router/go_router.dart';

/// Wrapper screen for vehicles list with AppBar and FAB
class VehiclesListWrapperScreen extends StatelessWidget {
  const VehiclesListWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 32, withText: true),
      ),
      body: const VehiclesListScreen(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(RouteNames.addVehicle);
        },
        icon: const Icon(Icons.add),
        label: const Text('Adaugă mașină'),
      ),
    );
  }
}

