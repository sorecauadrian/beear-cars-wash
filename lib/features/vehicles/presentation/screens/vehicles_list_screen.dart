import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/animated_list_item.dart';
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
                  return AnimatedListItem(
                    index: index,
                    child: _buildVehicleCard(context, ref, vehicle),
                  );
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
            subtitle: AppErrorHandler.userFriendlyMessage(error),
            actionLabel: 'Încearcă din nou',
            onAction: () => ref.invalidate(myVehiclesProvider),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Eroare',
        subtitle: AppErrorHandler.userFriendlyMessage(error),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, WidgetRef ref, VehicleModel vehicle) {
    final theme = Theme.of(context);
    final typeColor = _vehicleTypeColor(vehicle.vehicleType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Icon(_vehicleTypeIcon(vehicle.vehicleType), color: typeColor),
        ),
        title: Text(vehicle.plateNumber, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicle.vehicleType.label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (vehicle.description != null && vehicle.description!.isNotEmpty)
              Text(vehicle.description!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.md),
                const Text('Editează'),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                const Icon(Icons.delete_outlined, size: 20, color: AppColors.error),
                const SizedBox(width: AppSpacing.md),
                const Text('Șterge', style: TextStyle(color: AppColors.error)),
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

  Color _vehicleTypeColor(VehicleType type) {
    switch (type) {
      case VehicleType.small:
        return AppColors.info;
      case VehicleType.suv:
        return AppColors.secondary;
      case VehicleType.busJeep:
        return AppColors.warning;
      case VehicleType.truck:
        return AppColors.statusInProgress;
    }
  }

  IconData _vehicleTypeIcon(VehicleType type) {
    switch (type) {
      case VehicleType.small:
        return Icons.directions_car_outlined;
      case VehicleType.suv:
        return Icons.directions_car_filled_outlined;
      case VehicleType.busJeep:
        return Icons.airport_shuttle_outlined;
      case VehicleType.truck:
        return Icons.local_shipping_outlined;
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, VehicleModel vehicle) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Șterge mașina',
      message: 'Ești sigur că vrei să ștergi mașina ${vehicle.plateNumber}?',
      confirmLabel: 'Șterge',
      isDestructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(deleteVehicleProvider(vehicle.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mașina a fost ștearsă'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorHandler.userFriendlyMessage(e)), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
