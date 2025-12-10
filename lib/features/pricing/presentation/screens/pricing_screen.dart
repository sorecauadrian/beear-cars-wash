import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/pricing_provider.dart' as pricing_providers;
import '../../data/models/pricing_model.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';

/// Pricing management screen for admin
class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _interiorController;
  late TextEditingController _exteriorController;
  late TextEditingController _tapiterieController;
  late TextEditingController _completeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _interiorController = TextEditingController();
    _exteriorController = TextEditingController();
    _tapiterieController = TextEditingController();
    _completeController = TextEditingController();
    _loadCurrentPricing();
  }

  @override
  void dispose() {
    _interiorController.dispose();
    _exteriorController.dispose();
    _tapiterieController.dispose();
    _completeController.dispose();
    super.dispose();
  }

  void _loadCurrentPricing() {
    final pricingAsync = ref.read(pricing_providers.getCurrentPricingProvider.future);
    pricingAsync.then((pricing) {
      if (pricing != null && mounted) {
        setState(() {
          _interiorController.text = pricing.interiorPrice.toInt().toString();
          _exteriorController.text = pricing.exteriorPrice.toInt().toString();
          _tapiterieController.text = pricing.tapiteriePrice.toInt().toString();
          _completeController.text = pricing.completePrice.toInt().toString();
        });
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userAsync = ref.read(currentUserProvider);
      final user = await userAsync.when(
        data: (u) {
          if (u == null) {
            throw Exception('User not found');
          }
          return Future.value(u);
        },
        loading: () => throw Exception('User loading'),
        error: (e, _) => throw Exception('User error: $e'),
      );

      final pricing = PricingModel(
        id: '',
        interiorPrice: int.parse(_interiorController.text).toDouble(),
        exteriorPrice: int.parse(_exteriorController.text).toDouble(),
        tapiteriePrice: int.parse(_tapiterieController.text).toDouble(),
        completePrice: int.parse(_completeController.text).toDouble(),
        updatedAt: DateTime.now(),
        updatedBy: user.id,
      );

      await ref.read(pricing_providers.setPricingProvider(pricing));
      
      // Invalidate pricing providers to refresh data
      ref.invalidate(pricing_providers.getCurrentPricingProvider);
      ref.invalidate(pricing_providers.currentPricingProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prețuri actualizate cu succes!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      ),
      body: ref.watch(pricing_providers.getCurrentPricingProvider).when(
        data: (pricing) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Card(
                  color: AppColors.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                    'Setează prețurile pentru serviciile de spălare',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Price Cards in Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildPriceCard(
                      context: context,
                      label: 'Interior',
                      description: 'Spălare interior',
                      controller: _interiorController,
                      icon: Icons.airline_seat_recline_normal,
                      color: Colors.blue,
                      currentPrice: pricing?.interiorPrice.toInt().toString(),
                    ),
                    _buildPriceCard(
                      context: context,
                      label: 'Exterior',
                      description: 'Spălare exterior',
                      controller: _exteriorController,
                      icon: Icons.local_car_wash,
                      color: Colors.cyan,
                      currentPrice: pricing?.exteriorPrice.toStringAsFixed(2),
                    ),
                    _buildPriceCard(
                      context: context,
                      label: 'Tapițerie',
                      description: 'Spălare tapițerie',
                      controller: _tapiterieController,
                      icon: Icons.chair,
                      color: Colors.orange,
                      currentPrice: pricing?.tapiteriePrice.toStringAsFixed(2),
                    ),
                    _buildPriceCard(
                      context: context,
                      label: 'Completă',
                      description: 'Spălare completă',
                      controller: _completeController,
                      icon: Icons.cleaning_services,
                      color: Colors.purple,
                      currentPrice: pricing?.completePrice.toStringAsFixed(2),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Save Button
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Eroare: $error',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(pricing_providers.getCurrentPricingProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Încearcă din nou'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard({
    required BuildContext context,
    required String label,
    required String description,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    String? currentPrice,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: currentPrice != null && currentPrice.isNotEmpty 
                      ? currentPrice.replaceAll('.00', '') 
                      : '0',
                  suffixText: 'RON',
                  suffixStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introdu prețul';
                  }
                  final price = int.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Preț invalid';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
