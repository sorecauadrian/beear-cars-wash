import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../companies/presentation/providers/company_provider.dart';

class CustomerSettingsScreen extends ConsumerWidget {
  const CustomerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Setări')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Utilizatorul nu este autentificat'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile avatar
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(user.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Center(
                  child: Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Info cards
                _buildInfoCard(context, icon: Icons.person_outline, label: 'Nume', value: user.name),
                _buildInfoCard(context, icon: Icons.email_outlined, label: 'Email', value: user.email),
                if (user.companyId != null)
                  _buildCompanyRoleCard(context, ref, user)
                else
                  _buildInfoCard(context, icon: Icons.badge_outlined, label: 'Rol', value: _getRoleDisplayName(user.role, null)),

                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Contactați administratorul pentru modificări la contul dumneavoastră.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Eroare: $error')),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyRoleCard(BuildContext context, WidgetRef ref, UserModel user) {
    final companyAsync = ref.watch(companyByIdProvider(user.companyId!));
    return companyAsync.when(
      data: (company) {
        final role = _getRoleDisplayName(user.role, company?.clientType.toString());
        return _buildInfoCard(context, icon: Icons.badge_outlined, label: 'Rol', value: role);
      },
      loading: () => _buildInfoCard(context, icon: Icons.badge_outlined, label: 'Rol', value: '...'),
      error: (_, __) => _buildInfoCard(context, icon: Icons.badge_outlined, label: 'Rol', value: _getRoleDisplayName(user.role, null)),
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
