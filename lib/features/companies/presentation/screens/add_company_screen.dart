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
          content: Text('Compania a fost creată cu succes'),
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
        title: const Text('Adaugă companie'),
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
                  labelText: 'Nume companie *',
                  hintText: 'Introdu numele companiei',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Numele companiei',
                ),
                enabled: !_isLoading,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contractController,
                decoration: const InputDecoration(
                  labelText: 'Număr contract *',
                  hintText: 'Introdu numărul contractului',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Numărul contractului',
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Oraș *',
                  hintText: 'Introdu orașul',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Orașul',
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Activă'),
                subtitle: const Text('Compania este activă și poate primi rezervări'),
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
                    : const Text('Salvează compania'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


