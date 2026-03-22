import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../main.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../companies/presentation/providers/company_provider.dart';

class CustomerSettingsScreen extends ConsumerStatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  ConsumerState<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends ConsumerState<CustomerSettingsScreen> {
  bool _isDeletingAccount = false;

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
      await ref.read(deleteAccountProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorHandler.userFriendlyMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Setări')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const ErrorDisplay(message: 'Utilizatorul nu este autentificat');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile header
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Center(
                  child: Text(user.email, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Info section
                _buildSectionCard(
                  theme: theme,
                  children: [
                    _buildInfoRow(theme, icon: Icons.person_outline, label: 'Nume', value: user.name),
                    Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    _buildInfoRow(theme, icon: Icons.email_outlined, label: 'Email', value: user.email),
                    if (user.companyId != null) ...[
                      Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      _buildCompanyRoleRow(theme, ref, user),
                    ] else ...[
                      Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      _buildInfoRow(theme, icon: Icons.badge_outlined, label: 'Rol', value: _getRoleDisplayName(user.role, null)),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Theme section
                _buildSectionCard(
                  theme: theme,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Temă aplicație', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                      child: _buildThemeSelector(theme, ref),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkInfoLight : AppColors.infoLight,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: isDark ? AppColors.darkInfo : AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Contactați administratorul pentru modificări la contul dumneavoastră.',
                          style: theme.textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkInfo : AppColors.info),
                        ),
                      ),
                    ],
                  ),
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
          );
        },
        loading: () => const LoadingIndicator(message: 'Se încarcă setările...'),
        error: (error, _) => ErrorDisplay(
          message: AppErrorHandler.userFriendlyMessage(error),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required ThemeData theme, required List<Widget> children}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyRoleRow(ThemeData theme, WidgetRef ref, UserModel user) {
    final companyAsync = ref.watch(companyByIdProvider(user.companyId!));
    return companyAsync.when(
      data: (company) {
        final role = _getRoleDisplayName(user.role, company?.clientType.toString());
        return _buildInfoRow(theme, icon: Icons.badge_outlined, label: 'Rol', value: role);
      },
      loading: () => _buildInfoRow(theme, icon: Icons.badge_outlined, label: 'Rol', value: '...'),
      error: (_, __) => _buildInfoRow(theme, icon: Icons.badge_outlined, label: 'Rol', value: _getRoleDisplayName(user.role, null)),
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

  String _getRoleDisplayName(UserRole role, String? clientType) {
    switch (role) {
      case UserRole.companyAdmin:
        if (clientType == 'persoana_juridica') {
          return 'Administrator Companie';
        }
        return 'Client';
      case UserRole.companyWorker:
        return 'Angajat';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}
