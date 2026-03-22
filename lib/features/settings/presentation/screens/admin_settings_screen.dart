import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../main.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  bool _isPasswordLoading = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userAsync = ref.read(currentUserProvider);
    userAsync.whenData((user) {
      if (user != null) {
        setState(() {
          _nameController.text = user.name;
          _emailController.text = user.email;
        });
      }
    });

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;
          });
        }
      } catch (e) {
        // Use default value
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Utilizatorul nu este autentificat');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'notificationsEnabled': _notificationsEnabled,
      });

      if (_emailController.text.trim() != firebaseUser.email) {
        await firebaseUser.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      ref.invalidate(currentUserProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil actualizat cu succes'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorHandler.userFriendlyMessage(e)), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Șterge contul',
      message: 'Ești sigur că vrei să ștergi contul? '
          'Toate datele tale vor fi șterse permanent și nu vor putea fi recuperate.',
      confirmLabel: 'Șterge definitiv',
      cancelLabel: 'Anulează',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.deleteAccount();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      String msg = 'Eroare la ștergerea contului';
      if (e.toString().contains('requires-recent-login')) {
        msg = 'Pentru securitate, te rugăm să te deconectezi și să te autentifici din nou înainte de a șterge contul';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdu parola nouă'), backgroundColor: AppColors.warning),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parolele nu se potrivesc'), backgroundColor: AppColors.warning),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parola trebuie să aibă cel puțin 6 caractere'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isPasswordLoading = true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Utilizatorul nu este autentificat');
      }

      await firebaseUser.updatePassword(_passwordController.text);
      _passwordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parolă actualizată cu succes'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Eroare la actualizarea parolei';
      if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Pentru securitate, te rugăm să te autentifici din nou înainte de a schimba parola';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Setări')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Utilizatorul nu este autentificat'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile header
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Text(user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Text(
                        'Administrator',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Profile edit section
                  _buildSectionCard(
                    theme: theme,
                    icon: Icons.person_outline,
                    title: 'Profil',
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nume *',
                          hintText: 'Introdu numele',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => Validators.required(value, fieldName: 'Numele'),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          hintText: 'Introdu email-ul',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Introdu email-ul';
                          if (!value.contains('@')) return 'Email invalid';
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : const Text('Salvează profilul'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Theme section
                  _buildSectionCard(
                    theme: theme,
                    icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    title: 'Temă aplicație',
                    children: [
                      _buildThemeSelector(theme, ref),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Password section
                  _buildSectionCard(
                    theme: theme,
                    icon: Icons.lock_outline,
                    title: 'Parolă',
                    children: [
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Parolă nouă',
                          hintText: 'Introdu parola nouă',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        enabled: !_isPasswordLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirmă parola',
                          hintText: 'Introdu din nou parola',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        enabled: !_isPasswordLoading,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPasswordLoading ? null : _changePassword,
                          child: _isPasswordLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : const Text('Schimbă parola'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Notifications section
                  _buildSectionCard(
                    theme: theme,
                    icon: Icons.notifications_outlined,
                    title: 'Notificări',
                    children: [
                      SwitchListTile(
                        title: const Text('Activează notificările'),
                        subtitle: const Text('Primește notificări despre rezervări noi'),
                        value: _notificationsEnabled,
                        contentPadding: EdgeInsets.zero,
                        onChanged: _isLoading
                            ? null
                            : (value) async {
                                setState(() => _notificationsEnabled = value);
                                final firebaseUser = FirebaseAuth.instance.currentUser;
                                final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
                                if (firebaseUser != null) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(firebaseUser.uid)
                                        .update({'notificationsEnabled': value});
                                  } catch (e) {
                                    if (!mounted) return;
                                    setState(() => _notificationsEnabled = !value);
                                    scaffoldMessenger?.showSnackBar(
                                      const SnackBar(
                                        content: Text('Eroare la actualizarea setărilor'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Delete account
                  OutlinedButton.icon(
                    onPressed: _isDeletingAccount ? null : _confirmDeleteAccount,
                    icon: _isDeletingAccount
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.delete_forever_outlined),
                    label: Text(_isDeletingAccount ? 'Se șterge...' : 'Șterge contul'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Se încarcă setările...'),
        error: (error, stack) => ErrorDisplay(
          message: AppErrorHandler.userFriendlyMessage(error),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ThemeData theme, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final modes = [
      (ThemeMode.light, 'Zi', Icons.light_mode_outlined),
      (ThemeMode.system, 'Auto', Icons.brightness_auto_outlined),
      (ThemeMode.dark, 'Noapte', Icons.dark_mode_outlined),
    ];

    return Row(
      children: modes.map((entry) {
        final (mode, label, icon) = entry;
        final isSelected = currentMode == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mode != ThemeMode.dark ? 6 : 0,
              left: mode != ThemeMode.light ? 6 : 0,
            ),
            child: GestureDetector(
              onTap: () => ref.read(themeModeProvider.notifier).state = mode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
