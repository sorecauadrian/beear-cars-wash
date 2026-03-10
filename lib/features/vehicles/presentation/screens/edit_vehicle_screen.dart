import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../providers/vehicle_provider.dart';
import 'package:go_router/go_router.dart';

class EditVehicleScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const EditVehicleScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends ConsumerState<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  VehicleModel? _vehicle;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      final vehicle = await VehicleRepository().getVehicleById(widget.vehicleId);
      if (vehicle != null && mounted) {
        setState(() {
          _vehicle = vehicle;
          _plateController.text = vehicle.plateNumber;
          _descriptionController.text = vehicle.description ?? '';
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Mașina nu a fost găsită'), backgroundColor: AppColors.error),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la încărcare: $e'), backgroundColor: AppColors.error),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _vehicle == null) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(updateVehicleProvider(
        UpdateVehicleParams(
          vehicle: _vehicle!,
          plateNumber: _plateController.text.trim().toUpperCase(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        ),
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Mașina a fost actualizată'), backgroundColor: AppColors.success),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vehicle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editează mașina')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descriere (Opțional)',
                  hintText: 'Descrierea vehiculului, modelul, culoarea, etc.',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Text('Salvează modificările'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
