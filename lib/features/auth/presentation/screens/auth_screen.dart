import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../features/companies/presentation/providers/company_provider.dart';
import '../../../../features/companies/data/models/company_model.dart';
import 'package:go_router/go_router.dart';

enum AuthMode { login, register, forgotPassword }

class AuthScreen extends ConsumerStatefulWidget {
  final AuthMode initialMode;

  const AuthScreen({super.key, this.initialMode = AuthMode.login});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AuthMode _mode;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();

  // Shared fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Persoană Fizică fields
  final _pfNameController = TextEditingController();
  final _pfPhoneController = TextEditingController();
  final _pfCityController = TextEditingController();

  // Persoană Juridică fields
  final _pjDenumireController = TextEditingController();
  final _pjCuiController = TextEditingController();
  final _pjNrRegComController = TextEditingController();
  final _pjAdresaSediuController = TextEditingController();
  final _pjJudetController = TextEditingController();
  final _pjCityController = TextEditingController();
  final _pjPhoneController = TextEditingController();
  final _pjBancaController = TextEditingController();
  final _pjIbanController = TextEditingController();

  ClientType _clientType = ClientType.persoanaFizica;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pfNameController.dispose();
    _pfPhoneController.dispose();
    _pfCityController.dispose();
    _pjDenumireController.dispose();
    _pjCuiController.dispose();
    _pjNrRegComController.dispose();
    _pjAdresaSediuController.dispose();
    _pjJudetController.dispose();
    _pjCityController.dispose();
    _pjPhoneController.dispose();
    _pjBancaController.dispose();
    _pjIbanController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    _formKey.currentState?.reset();
    setState(() {
      _animController.reset();
      _mode = mode;
      _animController.forward();
    });
  }

  // ═══ Handlers ═══

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      NotificationService().setUserId(user.id);

      if (user.isAdmin) {
        context.go(RouteNames.adminHome);
      } else {
        context.go(RouteNames.companyHome);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(AppErrorHandler.userFriendlyMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      _showError('Trebuie să accepți Termenii și Condițiile pentru a continua.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Parolele nu se potrivesc');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isPJ = _clientType == ClientType.persoanaJuridica;
      final name = isPJ ? _pjDenumireController.text.trim() : _pfNameController.text.trim();
      final city = isPJ ? _pjCityController.text.trim() : _pfCityController.text.trim();
      final phone = isPJ ? _pjPhoneController.text.trim() : _pfPhoneController.text.trim();

      final params = CreateCompanyParams(
        name: name,
        clientType: _clientType,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: phone,
        city: city,
        isActive: true,
        cui: isPJ ? _pjCuiController.text.trim() : null,
        nrRegCom: isPJ ? _pjNrRegComController.text.trim() : null,
        adresaSediu: isPJ ? _pjAdresaSediuController.text.trim() : null,
        judet: isPJ ? _pjJudetController.text.trim() : null,
        banca: isPJ && _pjBancaController.text.trim().isNotEmpty
            ? _pjBancaController.text.trim()
            : null,
        iban: isPJ && _pjIbanController.text.trim().isNotEmpty
            ? _pjIbanController.text.trim()
            : null,
      );

      await ref.read(createCompanyProvider(params));

      if (!mounted) return;

      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      NotificationService().setUserId(user.id);
      context.go(RouteNames.companyHome);
      _showSuccess('Cont creat cu succes!');
    } catch (e) {
      if (!mounted) return;
      _showError(AppErrorHandler.userFriendlyMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPasswordResetEmail(_emailController.text.trim());

      if (!mounted) return;
      _showSuccess('Am trimis un email cu link de resetare. Verifică inbox-ul și spam-ul.');
      _switchMode(AuthMode.login);
    } catch (e) {
      if (!mounted) return;
      _showError(AppErrorHandler.userFriendlyMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
    );
  }

  // ═══ Build ═══

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AssetPaths.heroServiceInAction,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppColors.background),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: size.height > 700 ? 48 : 24,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: 40),
                        _buildCard(theme),
                        const SizedBox(height: 24),
                        _buildFooterLinks(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    String subtitle;
    switch (_mode) {
      case AuthMode.login:
        subtitle = 'Spălare auto la fața locului';
        break;
      case AuthMode.register:
        subtitle = _clientType == ClientType.persoanaJuridica
            ? 'Înregistrează o companie'
            : 'Creează cont';
        break;
      case AuthMode.forgotPassword:
        subtitle = 'Recuperează parola';
        break;
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              AssetPaths.logoNoTextWhite,
              height: 80,
              width: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.local_car_wash, size: 56, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Beear Cars Wash',
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_mode == AuthMode.login) ..._buildLoginFields(theme),
          if (_mode == AuthMode.register) ..._buildRegisterFields(theme),
          if (_mode == AuthMode.forgotPassword) ..._buildForgotPasswordFields(theme),
        ],
      ),
    );
  }

  // ═══ Login ═══

  List<Widget> _buildLoginFields(ThemeData theme) {
    return [
      _buildEmailField(),
      const SizedBox(height: 20),
      _buildPasswordField(onSubmit: _handleLogin),
      const SizedBox(height: 28),
      _buildPrimaryButton(label: 'Conectează-te', onPressed: _handleLogin),
    ];
  }

  // ═══ Register ═══

  List<Widget> _buildRegisterFields(ThemeData theme) {
    return [
      // Client type selector
      _buildClientTypeSelector(theme),
      const SizedBox(height: 24),

      // Type-specific fields
      if (_clientType == ClientType.persoanaFizica)
        ..._buildPFFields(theme)
      else
        ..._buildPJFields(theme),

      // Shared auth fields
      const SizedBox(height: 24),
      Divider(color: theme.colorScheme.outline),
      const SizedBox(height: 16),
      Text(
        'Date autentificare',
        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      _buildEmailField(),
      const SizedBox(height: 20),
      _buildPasswordField(),
      const SizedBox(height: 20),
      _buildConfirmPasswordField(),
      const SizedBox(height: 20),
      _buildTermsCheckbox(theme),
      const SizedBox(height: 20),
      _buildPrimaryButton(label: 'Creează cont', onPressed: _handleRegister),
    ];
  }

  // ═══ Persoană Fizică fields ═══

  List<Widget> _buildPFFields(ThemeData theme) {
    return [
      TextFormField(
        controller: _pfNameController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nume complet *',
          hintText: 'Ex: Ion Popescu',
          prefixIcon: Icon(AppIcons.person, size: 22),
        ),
        validator: (v) => Validators.required(v, fieldName: 'Numele'),
        enabled: !_isLoading,
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _pfPhoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Telefon',
          hintText: 'Ex: 0712 345 678',
          prefixIcon: Icon(Icons.phone_outlined, size: 22),
        ),
        enabled: !_isLoading,
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _pfCityController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Oraș *',
          hintText: 'Ex: București',
          prefixIcon: Icon(AppIcons.location, size: 22),
        ),
        validator: (v) => Validators.required(v, fieldName: 'Orașul'),
        enabled: !_isLoading,
      ),
    ];
  }

  // ═══ Persoană Juridică fields ═══

  List<Widget> _buildPJFields(ThemeData theme) {
    return [
      // Section: Date firmă
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          'Date firmă',
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
      ),
      TextFormField(
        controller: _pjDenumireController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Denumire firmă *',
          hintText: 'Ex: SC Exemplu SRL',
          prefixIcon: Icon(Icons.business_outlined, size: 22),
        ),
        validator: (v) => Validators.required(v, fieldName: 'Denumirea firmei'),
        enabled: !_isLoading,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _pjCuiController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'CUI *',
          hintText: 'Ex: 12345678',
          prefixIcon: Icon(Icons.tag, size: 22),
        ),
        validator: (v) => Validators.required(v, fieldName: 'CUI'),
        enabled: !_isLoading,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _pjNrRegComController,
        decoration: const InputDecoration(
          labelText: 'Nr. Registrul Comerțului *',
          hintText: 'Ex: J40/1234/2020',
          prefixIcon: Icon(Icons.assignment_outlined, size: 22),
        ),
        validator: (v) => Validators.required(v, fieldName: 'Nr. Reg. Com.'),
        enabled: !_isLoading,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _pjAdresaSediuController,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Adresă sediu social *',
          hintText: 'Str. Exemplu nr. 10, Sector 1',
          prefixIcon: Icon(Icons.location_on_outlined, size: 22),
        ),
        validator: (v) => Validators.required(v, fieldName: 'Adresa sediului'),
        enabled: !_isLoading,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _pjCityController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Oraș *',
          hintText: 'Ex: București',
          prefixIcon: Icon(AppIcons.location, size: 22),
        ),
        validator: (v) => Validators.required(v, fieldName: 'Orașul'),
        enabled: !_isLoading,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _pjJudetController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Județ *',
          hintText: 'Ex: Ilfov',
          prefixIcon: Icon(Icons.map_outlined, size: 22),
        ),
        validator: (v) => Validators.required(v, fieldName: 'Județul'),
        enabled: !_isLoading,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _pjPhoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Telefon *',
          hintText: 'Ex: 0212 345 678',
          prefixIcon: Icon(Icons.phone_outlined, size: 22),
        ),
        validator: (v) => Validators.required(v, fieldName: 'Telefonul'),
        enabled: !_isLoading,
      ),

      // Section: Date bancare (opțional)
      const SizedBox(height: 24),
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Text(
              'Date bancare',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              child: Text('opțional', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
      TextFormField(
        controller: _pjBancaController,
        decoration: const InputDecoration(
          labelText: 'Banca',
          hintText: 'Ex: Banca Transilvania',
          prefixIcon: Icon(Icons.account_balance_outlined, size: 22),
        ),
        enabled: !_isLoading,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _pjIbanController,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'IBAN',
          hintText: 'Ex: RO49AAAA1B31007593840000',
          prefixIcon: Icon(Icons.credit_card_outlined, size: 22),
        ),
        enabled: !_isLoading,
      ),
    ];
  }

  // ═══ Forgot Password ═══

  List<Widget> _buildForgotPasswordFields(ThemeData theme) {
    return [
      _buildEmailField(),
      const SizedBox(height: 28),
      _buildPrimaryButton(label: 'Trimite link de resetare', onPressed: _handleForgotPassword),
    ];
  }

  // ═══ Shared field builders ═══

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'exemplu@companie.ro',
        prefixIcon: Icon(AppIcons.email, size: 22),
      ),
      validator: Validators.email,
      enabled: !_isLoading,
    );
  }

  Widget _buildPasswordField({VoidCallback? onSubmit}) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: _mode == AuthMode.register ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: onSubmit != null ? (_) => onSubmit() : null,
      decoration: InputDecoration(
        labelText: 'Parolă',
        hintText: '••••••••',
        prefixIcon: const Icon(AppIcons.password, size: 22),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? AppIcons.visibility : AppIcons.visibilityOff, size: 22),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: _mode == AuthMode.register
          ? Validators.password
          : (v) => Validators.required(v, fieldName: 'Parola'),
      enabled: !_isLoading,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Confirmă parola',
        hintText: '••••••••',
        prefixIcon: const Icon(AppIcons.password, size: 22),
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword ? AppIcons.visibility : AppIcons.visibilityOff, size: 22),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Confirmarea parolei este obligatorie';
        if (v != _passwordController.text) return 'Parolele nu se potrivesc';
        return null;
      },
      enabled: !_isLoading,
    );
  }

  Widget _buildTermsCheckbox(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: _isLoading ? null : (v) => setState(() => _acceptedTerms = v ?? false),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: GestureDetector(
            onTap: _isLoading ? null : () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                children: [
                  const TextSpan(text: 'Am citit și sunt de acord cu '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => context.push('${RouteNames.termsAndPrivacy}?tab=terms'),
                      child: Text(
                        'Termenii și Condițiile',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' și '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => context.push('${RouteNames.termsAndPrivacy}?tab=privacy'),
                      child: Text(
                        'Politica de Confidențialitate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tip cont',
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildClientTypeChip(ClientType.persoanaFizica, 'Persoană fizică', Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _buildClientTypeChip(ClientType.persoanaJuridica, 'Persoană juridică', Icons.business_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildClientTypeChip(ClientType type, String label, IconData icon) {
    final isSelected = _clientType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _clientType = type);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFooterLinks(ThemeData theme) {
    return Column(
      children: [
        if (_mode == AuthMode.login) ...[
          TextButton(
            onPressed: () => _switchMode(AuthMode.forgotPassword),
            child: Text('Ai uitat parola?', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Nu ai cont? ', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              TextButton(
                onPressed: () => _switchMode(AuthMode.register),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Înregistrează-te', style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ] else if (_mode == AuthMode.register) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ai deja cont? ', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              TextButton(
                onPressed: () => _switchMode(AuthMode.login),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Conectează-te', style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ] else ...[
          TextButton.icon(
            onPressed: () => _switchMode(AuthMode.login),
            icon: Icon(Icons.arrow_back, size: 18, color: Colors.white.withValues(alpha: 0.9)),
            label: Text('Înapoi la autentificare', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
          ),
        ],
      ],
    );
  }
}
