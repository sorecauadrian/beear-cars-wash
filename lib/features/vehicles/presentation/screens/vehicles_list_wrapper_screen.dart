import 'package:flutter/material.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_icons.dart';
import 'vehicles_list_screen.dart';
import 'package:go_router/go_router.dart';

class VehiclesListWrapperScreen extends StatelessWidget {
  const VehiclesListWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mașinile mele'),
      ),
      body: const VehiclesListScreen(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addVehicle),
        icon: const Icon(AppIcons.addVehicle),
        label: const Text('Adaugă mașină'),
      ),
    );
  }
}
