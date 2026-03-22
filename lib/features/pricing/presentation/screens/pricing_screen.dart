import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/pricing_provider.dart' as pricing_providers;
import '../../data/models/pricing_model.dart';
import '../../../vehicles/data/models/vehicle_model.dart';
import '../../../bookings/data/models/booking_model.dart';
import 'package:go_router/go_router.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<VehicleType, Map<WashType, TextEditingController>> _controllers = {};
  late TextEditingController _discountController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final vt in VehicleType.values) {
      _controllers[vt] = {
        for (final wt in WashType.values) wt: TextEditingController(),
      };
    }
    _discountController = TextEditingController();
    _loadCurrentPricing();
  }

  @override
  void dispose() {
    for (final map in _controllers.values) {
      for (final c in map.values) {
        c.dispose();
      }
    }
    _discountController.dispose();
    super.dispose();
  }

  void _loadCurrentPricing() {
    final pricingAsync = ref.read(pricing_providers.getCurrentPricingProvider.future);
    pricingAsync.then((pricing) {
      if (pricing != null && mounted) {
        setState(() {
          for (final vt in VehicleType.values) {
            for (final wt in WashType.values) {
              _controllers[vt]![wt]!.text =
                  pricing.getPrice(vt, wt).toInt().toString();
            }
          }
          _discountController.text = pricing.multiVehicleDiscount.toInt().toString();
        });
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userAsync = ref.read(currentUserProvider);
      final user = await userAsync.when(
        data: (u) {
          if (u == null) throw Exception('User not found');
          return Future.value(u);
        },
        loading: () => throw Exception('User loading'),
        error: (e, _) => throw Exception('User error: $e'),
      );

      final prices = <VehicleType, Map<WashType, double>>{};
      for (final vt in VehicleType.values) {
        prices[vt] = {
          for (final wt in WashType.values)
            wt: int.parse(_controllers[vt]![wt]!.text).toDouble(),
        };
      }

      final pricing = PricingModel(
        id: '',
        prices: prices,
        multiVehicleDiscount: int.parse(_discountController.text).toDouble(),
        updatedAt: DateTime.now(),
        updatedBy: user.id,
      );

      await ref.read(pricing_providers.setPricingProvider(pricing));

      ref.invalidate(pricing_providers.getCurrentPricingProvider);
      ref.invalidate(pricing_providers.currentPricingProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prețuri actualizate cu succes!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.userFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prețuri'),
      ),
      body: ref.watch(pricing_providers.getCurrentPricingProvider).when(
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: AppColors.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestionează Prețuri',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Prețuri per tip vehicul și tip spălare',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                for (final vt in VehicleType.values) ...[
                  _buildVehicleTypeCard(context, vt),
                  const SizedBox(height: 16),
                ],

                _buildDiscountCard(context),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSave,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Se salvează...' : 'Salvează Prețuri'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const LoadingIndicator(message: 'Se încarcă prețurile...'),
        error: (error, stack) => ErrorDisplay(
          message: AppErrorHandler.userFriendlyMessage(error),
          onRetry: () => ref.invalidate(pricing_providers.getCurrentPricingProvider),
        ),
      ),
    );
  }

  Widget _buildVehicleTypeCard(BuildContext context, VehicleType vehicleType) {
    final theme = Theme.of(context);
    final colors = {
      VehicleType.small: AppColors.info,
      VehicleType.suv: Colors.cyan,
      VehicleType.busJeep: AppColors.warning,
      VehicleType.truck: Colors.purple,
    };
    final icons = {
      VehicleType.small: Icons.directions_car,
      VehicleType.suv: Icons.directions_car_filled,
      VehicleType.busJeep: Icons.airport_shuttle,
      VehicleType.truck: Icons.local_shipping,
    };
    final color = colors[vehicleType]!;
    final icon = icons[vehicleType]!;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    vehicleType.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final wt in WashType.values) ...[
                    Expanded(
                      child: _buildPriceField(
                        context: context,
                        label: _washTypeLabel(wt),
                        controller: _controllers[vehicleType]![wt]!,
                        color: color,
                      ),
                    ),
                    if (wt != WashType.values.last) const SizedBox(width: 12),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _washTypeLabel(WashType wt) {
    switch (wt) {
      case WashType.interior:
        return 'Interior';
      case WashType.exterior:
        return 'Exterior';
      case WashType.all:
        return 'Int + Ext';
    }
  }

  Widget _buildPriceField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            suffixText: 'lei',
            suffixStyle: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Preț';
            final price = int.tryParse(value);
            if (price == null || price < 0) return 'Invalid';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDiscountCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.success.withValues(alpha: 0.08),
              AppColors.success.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.discount, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reducere vehicul suplimentar',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Se aplică de la al 2-lea vehicul',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _discountController,
                  decoration: InputDecoration(
                    suffixText: 'lei',
                    suffixStyle: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.success),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.success, width: 2),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Req';
                    final v = int.tryParse(value);
                    if (v == null || v < 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
