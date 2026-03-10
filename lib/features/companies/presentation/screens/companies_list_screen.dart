import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/company_provider.dart';
import '../../data/models/company_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import 'package:go_router/go_router.dart';

class CompaniesListScreen extends ConsumerStatefulWidget {
  const CompaniesListScreen({super.key});

  @override
  ConsumerState<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends ConsumerState<CompaniesListScreen> {
  ClientType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(allCompaniesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clienți'),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                _buildFilterChip('Toți', _selectedFilter == null, () => setState(() => _selectedFilter = null)),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Juridică', _selectedFilter == ClientType.persoanaJuridica, () => setState(() => _selectedFilter = ClientType.persoanaJuridica)),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Fizică', _selectedFilter == ClientType.persoanaFizica, () => setState(() => _selectedFilter = ClientType.persoanaFizica)),
              ],
            ),
          ),
          Expanded(
            child: companiesAsync.when(
              data: (allCompanies) {
                final companies = _selectedFilter == null
                    ? allCompanies
                    : allCompanies.where((c) => c.clientType == _selectedFilter).toList();

                if (companies.isEmpty) {
                  return EmptyState(
                    icon: Icons.business_outlined,
                    title: _selectedFilter == null ? 'Niciun client' : 'Niciun client de tip ${_selectedFilter!.displayName}',
                    subtitle: 'Adaugă un client nou folosind butonul de mai jos',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allCompaniesProvider),
                  child: ListView.builder(
                    itemCount: companies.length,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemBuilder: (context, index) => _buildCompanyCard(context, ref, companies[index]),
                  ),
                );
              },
              loading: () => ListView(children: List.generate(4, (_) => const SkeletonCard())),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Eroare',
                subtitle: '$error',
                actionLabel: 'Încearcă din nou',
                onAction: () => ref.invalidate(allCompaniesProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addCompany),
        icon: const Icon(Icons.add),
        label: const Text('Client nou'),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onTap();
      },
      selectedColor: AppColors.accent.withValues(alpha: 0.15),
      checkmarkColor: AppColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.accent : AppColors.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildCompanyCard(BuildContext context, WidgetRef ref, CompanyModel company) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.outline),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: company.isActive ? AppColors.successLight : AppColors.surfaceVariant,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Icon(
            company.clientType == ClientType.persoanaJuridica ? Icons.business_outlined : Icons.person_outline,
            color: company.isActive ? AppColors.success : AppColors.onSurfaceVariant,
          ),
        ),
        title: Text(
          company.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: company.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(company.email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
            Text(company.city, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 20, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 12),
                const Text('Editează'),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outlined, size: 20, color: AppColors.error),
                const SizedBox(width: 12),
                Text('Șterge', style: TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              context.push('${RouteNames.editCompany}/${company.id}');
            } else if (value == 'delete') {
              _showDeleteDialog(context, ref, company);
            }
          },
        ),
        onTap: () => context.push('${RouteNames.editCompany}/${company.id}'),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, CompanyModel company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge clientul'),
        content: Text('Ești sigur că vrei să ștergi ${company.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anulează')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(deleteCompanyProvider(company.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Clientul a fost șters'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text('Șterge', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
