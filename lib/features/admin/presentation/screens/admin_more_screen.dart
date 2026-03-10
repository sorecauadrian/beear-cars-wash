import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mai mult')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // User card
          userAsync.when(
            data: (user) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (user?.name ?? 'A').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Administrator',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 72),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildMenuItem(
            context,
            icon: AppIcons.pricing,
            title: 'Prețuri',
            subtitle: 'Gestionează prețurile serviciilor',
            onTap: () => context.push(RouteNames.pricing),
          ),
          _buildMenuItem(
            context,
            icon: AppIcons.settings,
            title: 'Profil & Setări',
            subtitle: 'Modifică parola și preferințele',
            onTap: () => context.push(RouteNames.adminSettings),
          ),
          const Divider(height: AppSpacing.xl),
          _buildMenuItem(
            context,
            icon: AppIcons.logout,
            title: 'Deconectare',
            subtitle: 'Ieși din cont',
            isDestructive: true,
            onTap: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
              if (context.mounted) context.go(RouteNames.login);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isDestructive ? AppColors.error : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isDestructive ? AppColors.error : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!isDestructive)
              Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
