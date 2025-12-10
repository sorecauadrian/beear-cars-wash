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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  ClientType _clientType = ClientType.persoanaFizica;
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
          _emailController.text = company.email;
          _passwordController.text = company.password;
          _clientType = company.clientType;
          _cityController.text = company.city;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clientul nu a fost găsit'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la încărcarea clientului: $e'),
          backgroundColor: Colors.red,
        ),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
          clientType: _clientType,
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          city: _cityController.text.trim(),
          isActive: _company!.isActive, // Keep existing active status
        ),
      );
      await ref.read(updateProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client actualizat cu succes'),
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
        title: const Text('Editează client'),
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
                  labelText: 'Nume *',
                  hintText: 'Introdu numele',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Numele',
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ClientType>(
                value: _clientType,
                decoration: const InputDecoration(
                  labelText: 'Tip client *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: ClientType.values.map((type) {
                  return DropdownMenuItem<ClientType>(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _clientType = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'Introdu email-ul',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introdu email-ul';
                  }
                  if (!value.contains('@')) {
                    return 'Email invalid';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Parolă *',
                  hintText: 'Introdu parola',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Parola',
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
                    : const Text('Actualizează client'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


