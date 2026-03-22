import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/vehicle_model.dart';
import '../providers/vehicle_provider.dart';
import 'package:go_router/go_router.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _descriptionController = TextEditingController();
  VehicleType _selectedVehicleType = VehicleType.small;
  bool _isLoading = false;

  @override
  void dispose() {
    _plateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(createVehicleProvider(
        CreateVehicleParams(
          plateNumber: _plateController.text.trim().toUpperCase(),
          vehicleType: _selectedVehicleType,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        ),
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mașina a fost adăugată cu succes'), backgroundColor: AppColors.success),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorHandler.userFriendlyMessage(e)), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Adaugă mașină')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'Număr înmatriculare *',
                  hintText: 'Introdu numărul de înmatriculare',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: Validators.plateNumber,
                enabled: !_isLoading,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Tip vehicul *',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...VehicleType.values.map((type) {
                final isSelected = _selectedVehicleType == type;
                final color = _vehicleTypeColor(type);
                return GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () => setState(() => _selectedVehicleType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: isSelected ? color : theme.colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _vehicleTypeIcon(type),
                          color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            type.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? color : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? color : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? color : theme.colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descriere (Opțional)',
                  hintText: 'Modelul, culoarea, anul, etc.',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Text('Salvează mașina'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
