import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../providers/company_provider.dart';
import '../../data/models/company_model.dart';
import 'package:go_router/go_router.dart';

class EditCompanyScreen extends ConsumerStatefulWidget {
  final String companyId;

  const EditCompanyScreen({super.key, required this.companyId});

  @override
  ConsumerState<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends ConsumerState<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  CompanyModel? _company;
  bool _isLoading = false;

  // Shared
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  ClientType _clientType = ClientType.persoanaFizica;

  // PJ-specific
  final _cuiController = TextEditingController();
  final _nrRegComController = TextEditingController();
  final _adresaSediuController = TextEditingController();
  final _judetController = TextEditingController();
  final _bancaController = TextEditingController();
  final _ibanController = TextEditingController();

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
          _phoneController.text = company.phone;
          _clientType = company.clientType;
          _cityController.text = company.city;
          _cuiController.text = company.cui ?? '';
          _nrRegComController.text = company.nrRegCom ?? '';
          _adresaSediuController.text = company.adresaSediu ?? '';
          _judetController.text = company.judet ?? '';
          _bancaController.text = company.banca ?? '';
          _ibanController.text = company.iban ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clientul nu a fost găsit'), backgroundColor: AppColors.error),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: $e'), backgroundColor: AppColors.error),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _cuiController.dispose();
    _nrRegComController.dispose();
    _adresaSediuController.dispose();
    _judetController.dispose();
    _bancaController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _company == null) return;
    setState(() => _isLoading = true);

    try {
      final isPJ = _clientType == ClientType.persoanaJuridica;
      final params = UpdateCompanyParams(
        company: _company!,
        name: _nameController.text.trim(),
        clientType: _clientType,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        isActive: _company!.isActive,
        cui: isPJ ? _cuiController.text.trim() : null,
        nrRegCom: isPJ ? _nrRegComController.text.trim() : null,
        adresaSediu: isPJ ? _adresaSediuController.text.trim() : null,
        judet: isPJ ? _judetController.text.trim() : null,
        banca: isPJ && _bancaController.text.trim().isNotEmpty ? _bancaController.text.trim() : null,
        iban: isPJ && _ibanController.text.trim().isNotEmpty ? _ibanController.text.trim() : null,
      );

      await ref.read(updateCompanyProvider(params));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client actualizat cu succes'), backgroundColor: AppColors.success),
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
    if (_company == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isPJ = _clientType == ClientType.persoanaJuridica;

    return Scaffold(
      appBar: AppBar(title: const Text('Editează client')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Client type selector
              Text(
                'Tip client *',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: ClientType.values.map((type) {
                  final isSelected = _clientType == type;
                  final icon = type == ClientType.persoanaFizica
                      ? Icons.person_outline
                      : Icons.business_outlined;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: type == ClientType.values.first ? AppSpacing.sm : 0,
                        left: type == ClientType.values.last ? AppSpacing.sm : 0,
                      ),
                      child: GestureDetector(
                        onTap: _isLoading ? null : () => setState(() => _clientType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: AppSpacing.borderRadiusMd,
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                size: 28,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                type.displayName,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: 4),
                                Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isPJ ? 'Denumire firmă *' : 'Nume complet *',
                  prefixIcon: Icon(isPJ ? Icons.business_outlined : Icons.person_outline),
                ),
                validator: (v) => Validators.required(v, fieldName: isPJ ? 'Denumirea' : 'Numele'),
                enabled: !_isLoading,
              ),

              // PJ-specific fields
              if (isPJ) ...[
                const SizedBox(height: 20),
                _buildSectionLabel(theme, 'Date de facturare'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cuiController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'CUI *', prefixIcon: Icon(Icons.tag, size: 22)),
                  validator: (v) => Validators.required(v, fieldName: 'CUI'),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nrRegComController,
                  decoration: const InputDecoration(labelText: 'Nr. Registrul Comerțului *', prefixIcon: Icon(Icons.assignment_outlined, size: 22)),
                  validator: (v) => Validators.required(v, fieldName: 'Nr. Reg. Com.'),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adresaSediuController,
                  decoration: const InputDecoration(labelText: 'Adresă sediu social *', prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => Validators.required(v, fieldName: 'Adresa sediului'),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _judetController,
                  decoration: const InputDecoration(labelText: 'Județ *', prefixIcon: Icon(Icons.map_outlined)),
                  validator: (v) => Validators.required(v, fieldName: 'Județul'),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),
                _buildSectionLabel(theme, 'Date bancare', optional: true),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bancaController,
                  decoration: const InputDecoration(labelText: 'Banca', prefixIcon: Icon(Icons.account_balance_outlined)),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ibanController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'IBAN', prefixIcon: Icon(Icons.credit_card_outlined)),
                  enabled: !_isLoading,
                ),
              ],

              // Shared fields
              const SizedBox(height: 24),
              Divider(color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              _buildSectionLabel(theme, 'Cont și contact'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined)),
                validator: Validators.email,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone_outlined)),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Oraș *', prefixIcon: Icon(Icons.location_city_outlined)),
                validator: (v) => Validators.required(v, fieldName: 'Orașul'),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Actualizează client'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text, {bool optional = false}) {
    return Row(
      children: [
        Text(text, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        if (optional) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: AppSpacing.borderRadiusFull),
            child: Text('opțional', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ],
    );
  }
}
