import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../../data/models/company_model.dart';
import 'package:go_router/go_router.dart';

/// Companies list screen for admin
class CompaniesListScreen extends ConsumerStatefulWidget {
  const CompaniesListScreen({super.key});

  @override
  ConsumerState<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends ConsumerState<CompaniesListScreen> {
  ClientType? _selectedFilter; // null = all

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(allCompaniesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(height: 32),
            const SizedBox(width: 8),
            const Text('Clienți'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section - horizontal scrollable buttons
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.grey[50],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Toți',
                    isSelected: _selectedFilter == null,
                    onTap: () => setState(() => _selectedFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: ClientType.persoanaJuridica.displayName,
                    isSelected: _selectedFilter == ClientType.persoanaJuridica,
                    onTap: () => setState(() => _selectedFilter = ClientType.persoanaJuridica),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: ClientType.persoanaFizica.displayName,
                    isSelected: _selectedFilter == ClientType.persoanaFizica,
                    onTap: () => setState(() => _selectedFilter = ClientType.persoanaFizica),
                  ),
                ],
              ),
            ),
          ),
          // Companies list
          Expanded(
            child: companiesAsync.when(
              data: (allCompanies) {
                // Apply filter
                final companies = _selectedFilter == null
                    ? allCompanies
                    : allCompanies.where((c) => c.clientType == _selectedFilter).toList();

                if (companies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == null
                        ? 'Nu există clienți'
                        : 'Nu există clienți de tip ${_selectedFilter!.displayName}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Folosește butoanele de mai jos pentru a adăuga clienți',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allCompaniesProvider);
            },
            child: ListView.builder(
              itemCount: companies.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final company = companies[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(
                      company.isActive ? Icons.business : Icons.business_center,
                      color: company.isActive ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      company.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: company.isActive
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tip: ${company.clientType.displayName}'),
                        Text('Email: ${company.email}'),
                        Text('Oraș: ${company.city}'),
                        Text(
                          company.isActive ? 'Activă' : 'Inactivă',
                          style: TextStyle(
                            color: company.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Editează'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Șterge', style: TextStyle(color: Colors.red)),
                            ],
                          ),
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
                    onTap: () {
                      context.push('${RouteNames.editCompany}/${company.id}');
                    },
                  ),
                );
              },
            ),
          );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Eroare: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(allCompaniesProvider);
                      },
                      child: const Text('Încearcă din nou'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () {
              context.push('${RouteNames.addCompany}?type=juridica');
            },
            icon: const Icon(Icons.business),
            label: const Text('Persoană Juridică'),
            heroTag: 'add_juridica',
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () {
              context.push('${RouteNames.addCompany}?type=fizica');
            },
            icon: const Icon(Icons.person),
            label: const Text('Persoană Fizică'),
            heroTag: 'add_fizica',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    CompanyModel company,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge clientul'),
        content: Text(
          'Ești sigur că vrei să ștergi ${company.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final deleteProvider = deleteCompanyProvider(company.id);
                await ref.read(deleteProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Clientul a fost șters cu succes'),
                    backgroundColor: Colors.green,
                  ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Șterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

