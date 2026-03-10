import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../data/models/vehicle_model.dart';
import '../providers/vehicle_provider.dart';
import 'package:go_router/go_router.dart';

class VehiclesListScreen extends ConsumerWidget {
  const VehiclesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(myVehiclesProvider);
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const EmptyState(icon: Icons.person_off_outlined, title: 'Nu ești autentificat');
        }
        if (user.companyId == null) {
          return const EmptyState(icon: Icons.business_outlined, title: 'Nu ai o companie asociată contului tău');
        }

        return vehiclesAsync.when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return EmptyState(
                icon: Icons.directions_car_outlined,
                title: 'Nicio mașină adăugată',
                subtitle: 'Adaugă prima ta mașină pentru a putea crea rezervări',
                actionLabel: 'Adaugă mașină',
                onAction: () => context.push(RouteNames.addVehicle),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(myVehiclesProvider),
              child: ListView.builder(
                itemCount: vehicles.length,
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return _buildVehicleCard(context, ref, vehicle);
                },
              ),
            );
          },
          loading: () => ListView(
            children: List.generate(3, (_) => const SkeletonCard()),
          ),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Eroare',
            subtitle: '$error',
            actionLabel: 'Încearcă din nou',
            onAction: () => ref.invalidate(myVehiclesProvider),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(icon: Icons.error_outline_rounded, title: 'Eroare: $error'),
    );
  }

  Widget _buildVehicleCard(BuildContext context, WidgetRef ref, VehicleModel vehicle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.outline),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Icon(Icons.directions_car_outlined, color: AppColors.onSurfaceVariant),
        ),
        title: Text(vehicle.plateNumber, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: vehicle.description != null && vehicle.description!.isNotEmpty
            ? Text(vehicle.description!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant))
            : null,
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 20, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 12),
                const Text('Editează'),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outlined, size: 20, color: AppColors.error),
                const SizedBox(width: 12),
                Text('Șterge', style: TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              context.push('${RouteNames.editVehicle}/${vehicle.id}');
            } else if (value == 'delete') {
              _showDeleteDialog(context, ref, vehicle);
            }
          },
        ),
        onTap: () => context.push('${RouteNames.editVehicle}/${vehicle.id}'),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge mașina'),
        content: Text('Ești sigur că vrei să ștergi mașina ${vehicle.plateNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anulează')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(deleteVehicleProvider(vehicle.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Mașina a fost ștearsă'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text('Șterge', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
