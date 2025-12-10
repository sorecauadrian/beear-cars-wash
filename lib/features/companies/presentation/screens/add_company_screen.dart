import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../providers/company_provider.dart';
import '../../data/models/company_model.dart';
import 'package:go_router/go_router.dart';

/// Add company screen
class AddCompanyScreen extends ConsumerStatefulWidget {
  final ClientType? initialClientType;
  
  const AddCompanyScreen({
    super.key,
    this.initialClientType,
  });

  @override
  ConsumerState<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends ConsumerState<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  late ClientType _clientType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _clientType = widget.initialClientType ?? ClientType.persoanaFizica;
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
          clientType: _clientType,
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          city: _cityController.text.trim(),
          isActive: true, // Always active for new clients
        ),
      );
      await ref.read(createProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clientul a fost creat cu succes'),
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
        title: const Text('Adaugă client'),
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
                autofocus: true,
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
                onChanged: (_isLoading || widget.initialClientType != null)
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
              const SizedBox(height: 16),
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
                    : const Text('Salvează clientul'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


