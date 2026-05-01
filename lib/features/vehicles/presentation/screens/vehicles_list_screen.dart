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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return AnimatedListItem(
                    index: index,
                    child: _VehicleCard(
                      vehicle: vehicle,
                      onEdit: () => context.push('${RouteNames.editVehicle}/${vehicle.id}'),
                      onDelete: () => _showDeleteDialog(context, ref, vehicle),
                    ),
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

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final VehicleModel vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _typeColor {
    switch (vehicle.vehicleType) {
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

  IconData get _typeIcon {
    switch (vehicle.vehicleType) {
      case VehicleType.small:
        return Icons.directions_car_rounded;
      case VehicleType.suv:
        return Icons.directions_car_filled_rounded;
      case VehicleType.busJeep:
        return Icons.airport_shuttle_rounded;
      case VehicleType.truck:
        return Icons.local_shipping_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _typeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppSpacing.shadowMd,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onEdit,
        child: Column(
          children: [
            _CardHeader(color: color, icon: _typeIcon),
            _CardBody(
              vehicle: vehicle,
              typeColor: color,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(icon, size: 120, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Center(
            child: Icon(icon, size: 52, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.vehicle,
    required this.typeColor,
    required this.onEdit,
    required this.onDelete,
  });

  final VehicleModel vehicle;
  final Color typeColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LicensePlate(plateNumber: vehicle.plateNumber),
                const SizedBox(height: AppSpacing.sm),
                _TypeChip(label: vehicle.vehicleType.label, color: typeColor),
                if (vehicle.description != null && vehicle.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    vehicle.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            children: [
              _ActionButton(
                icon: Icons.edit_outlined,
                color: AppColors.secondary,
                onTap: onEdit,
              ),
              const SizedBox(height: AppSpacing.xs),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                color: AppColors.error,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LicensePlate extends StatelessWidget {
  const _LicensePlate({required this.plateNumber});

  final String plateNumber;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: const Color(0xFF1A2B47), width: 2),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFF003399),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(2),
                bottomLeft: Radius.circular(2),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'RO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            plateNumber.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 17,
              letterSpacing: 2,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppSpacing.borderRadiusMd,
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
