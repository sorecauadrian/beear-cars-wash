import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/vehicle_model.dart';
import '../providers/vehicle_provider.dart';
import 'package:go_router/go_router.dart';

/// Company Admin home screen - Vehicles list
class VehiclesListScreen extends ConsumerWidget {
  const VehiclesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(myVehiclesProvider);
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Nu ești autentificat'));
          }
          if (user.companyId == null) {
            return const Center(
              child: Text('Nu ai o companie asociată contului tău'),
            );
          }

          return vehiclesAsync.when(
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nu există mașini',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Adaugă prima ta mașină pentru a începe',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.push(RouteNames.addVehicle);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Adaugă mașină'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myVehiclesProvider);
                },
                child: ListView.builder(
                  itemCount: vehicles.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.directions_car),
                        title: Text(
                          vehicle.plateNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: vehicle.description != null &&
                                vehicle.description!.isNotEmpty
                            ? Text(vehicle.description!)
                            : null,
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20, color: Colors.blue),
                                  SizedBox(width: 12),
                                  Text('Editează', style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Șterge', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              context.push(
                                '${RouteNames.editVehicle}/${vehicle.id}',
                              );
                            } else if (value == 'delete') {
                              _showDeleteDialog(context, ref, vehicle);
                            }
                          },
                        ),
                        onTap: () {
                          context.push(
                            '${RouteNames.editVehicle}/${vehicle.id}',
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(myVehiclesProvider);
                    },
                    child: const Text('Încearcă din nou'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge mașina'),
        content: Text(
          'Ești sigur că vrei să ștergi mașina ${vehicle.plateNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final deleteProvider = deleteVehicleProvider(vehicle.id);
                await ref.read(deleteProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mașina a fost ștearsă cu succes'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Șterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
