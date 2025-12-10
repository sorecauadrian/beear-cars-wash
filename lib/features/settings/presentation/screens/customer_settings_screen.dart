import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';

/// Customer settings screen (view-only)
class CustomerSettingsScreen extends ConsumerWidget {
  const CustomerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 32),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Utilizatorul nu este autentificat'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Profil',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          label: 'Nume',
                          value: user.name,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          label: 'Email',
                          value: user.email,
                          icon: Icons.email,
                        ),
                        if (user.companyId != null) ...[
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            context,
                            label: 'ID Companie',
                            value: user.companyId!,
                            icon: Icons.business,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Role Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Informații',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          label: 'Rol',
                          value: _getRoleDisplayName(user.role),
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Notă: Aceste informații sunt doar pentru vizualizare. Contactați administratorul pentru modificări.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Eroare la încărcarea datelor: $error'),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.companyAdmin:
        return 'Administrator Companie';
      case UserRole.companyWorker:
        return 'Angajat Companie';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}

