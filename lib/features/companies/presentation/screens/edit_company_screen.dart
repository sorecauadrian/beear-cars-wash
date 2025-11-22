import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../providers/company_provider.dart';
import '../../data/models/company_model.dart';
import 'package:go_router/go_router.dart';

/// Edit company screen
class EditCompanyScreen extends ConsumerStatefulWidget {
  final String companyId;

  const EditCompanyScreen({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends ConsumerState<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contractController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;
  CompanyModel? _company;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    try {
      final repository = ref.read(companyRepositoryProvider);
      final company = await repository.getCompanyById(widget.companyId);
      
      if (!mounted) return;
      
      if (company != null) {
        setState(() {
          _company = company;
          _nameController.text = company.name;
          _contractController.text = company.contractNumber;
          _cityController.text = company.city;
          _isActive = company.isActive;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company not found'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading company: $e'),
          backgroundColor: Colors.red,
        ),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contractController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _company == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updateProvider = updateCompanyProvider(
        UpdateCompanyParams(
          company: _company!,
          name: _nameController.text.trim(),
          contractNumber: _contractController.text.trim(),
          city: _cityController.text.trim(),
          isActive: _isActive,
        ),
      );
      await ref.read(updateProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company updated successfully'),
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
    if (_company == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Company'),
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
                    : const Text('Update Company'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


