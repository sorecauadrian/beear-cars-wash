import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../providers/company_provider.dart';
import 'package:go_router/go_router.dart';

/// Add company screen
class AddCompanyScreen extends ConsumerStatefulWidget {
  const AddCompanyScreen({super.key});

  @override
  ConsumerState<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends ConsumerState<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contractController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contractController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final createProvider = createCompanyProvider(
        CreateCompanyParams(
          name: _nameController.text.trim(),
          contractNumber: _contractController.text.trim(),
          city: _cityController.text.trim(),
          isActive: _isActive,
        ),
      );
      await ref.read(createProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Company'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name *',
                  hintText: 'Enter company name',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Company name',
                ),
                enabled: !_isLoading,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contractController,
                decoration: const InputDecoration(
                  labelText: 'Contract Number *',
                  hintText: 'Enter contract number',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Contract number',
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  hintText: 'Enter city',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'City',
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Company is active and can receive bookings'),
                value: _isActive,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Company'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


