import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/companies/data/repositories/company_repository.dart';
import '../../../../features/companies/data/models/company_model.dart';
import '../../../../features/bookings/data/models/booking_model.dart';
import '../../../../features/bookings/presentation/providers/booking_provider.dart';
import '../../../../features/vehicles/data/models/vehicle_model.dart';
import '../../../../features/vehicles/presentation/providers/vehicle_provider.dart';
import '../../../../features/pricing/presentation/providers/pricing_provider.dart';
import '../../data/models/service_record_model.dart';
import '../services/export_service.dart';
import 'package:go_router/go_router.dart';

/// Service records list screen - auto-generated from completed bookings
class ServiceRecordsListScreen extends ConsumerStatefulWidget {
  const ServiceRecordsListScreen({super.key});

  @override
  ConsumerState<ServiceRecordsListScreen> createState() =>
      _ServiceRecordsListScreenState();
}

class _ServiceRecordsListScreenState
    extends ConsumerState<ServiceRecordsListScreen> {
  String? _selectedCompanyId;
  String? _selectedMonth;
  
  // Create companies provider at class level to avoid recreation
  final _companiesAsync = FutureProvider<List<CompanyModel>>((ref) async {
    final repository = CompanyRepository();
    return repository.getAllCompanies();
  });

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(allBookingsProvider);
    final companies = ref.watch(_companiesAsync);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 32),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
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
          // Visible filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cream,
            child: Column(
              children: [
                // Company filter
                ref.watch(_companiesAsync).when(
                  data: (companiesList) => DropdownButtonFormField<String>(
                    value: _selectedCompanyId,
                    decoration: const InputDecoration(
                      labelText: 'Companie',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Toate companiile'),
                      ),
                      ...companiesList.map((company) {
                        return DropdownMenuItem<String>(
                          value: company.id,
                          child: Text(company.name),
                        );
                      }),
                    ],
                    onChanged: (value) => setState(() => _selectedCompanyId = value),
                    isExpanded: true,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Eroare la încărcarea companiilor'),
                ),
                const SizedBox(height: 12),
                // Month filter
                InkWell(
                  onTap: () => _showMonthPicker(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Lună',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: _selectedMonth != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() => _selectedMonth = null);
                              },
                              tooltip: 'Resetează luna',
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    child: Text(
                      _selectedMonth != null
                          ? _formatMonth(_selectedMonth!)
                          : 'Selectează luna',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Records list
          Expanded(
            child: bookingsAsync.when(
              data: (allBookings) {
                // Filter completed bookings
                final completedBookings = allBookings
                    .where((b) => b.status == BookingStatus.done)
                    .toList();

                if (completedBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nu există servicii finalizate',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Serviciile finalizate vor apărea aici',
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                // Wait for companies to load before grouping
                return companies.when(
                  data: (companiesList) {
                    final groupedRecords = _groupBookingsByCompanyAndMonth(
                        completedBookings, _selectedCompanyId, _selectedMonth, companiesList);

                    if (groupedRecords.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.filter_alt_outlined,
                              size: 64,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nu există înregistrări pentru filtrele selectate',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(allBookingsProvider);
                        ref.invalidate(_companiesAsync);
                      },
                      child: ListView.builder(
                        itemCount: groupedRecords.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final record = groupedRecords[index];
                          final company = companiesList.firstWhere(
                            (c) => c.id == record['companyId'],
                            orElse: () => CompanyModel(
                              id: record['companyId'] as String,
                              name: 'Companie necunoscută',
                              clientType: ClientType.persoanaJuridica,
                              email: '',
                              password: '',
                              city: '',
                              isActive: true,
                            ),
                          );
                          return _buildRecordCard(
                            context,
                            record,
                            company,
                            completedBookings,
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
                        const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Eroare la încărcarea companiilor: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(_companiesAsync);
                          },
                          child: const Text('Încearcă din nou'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Eroare: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(allBookingsProvider);
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
    );
  }

  List<Map<String, dynamic>> _groupBookingsByCompanyAndMonth(
    List<BookingModel> bookings,
    String? companyFilter,
    String? monthFilter,
    List<CompanyModel> companies,
  ) {
    final grouped = <String, Map<String, dynamic>>{};
    final companyIds = companies.map((c) => c.id).toSet();

    for (var booking in bookings) {
      // Skip bookings with missing companies (orphaned bookings)
      if (!companyIds.contains(booking.companyId)) {
        continue;
      }

      // Apply filters
      if (companyFilter != null && booking.companyId != companyFilter) {
        continue;
      }

      // Parse booking date - handle different date formats
      DateTime bookingDate;
      try {
        bookingDate = DateTime.parse(booking.date);
      } catch (e) {
        // If parsing fails, skip this booking
        debugPrint('Warning: Failed to parse booking date: ${booking.date}, Error: $e');
        continue;
      }
      
      final bookingMonth =
          '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}';

      if (monthFilter != null && bookingMonth != monthFilter) {
        continue;
      }

      final key = '${booking.companyId}_$bookingMonth';

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'companyId': booking.companyId,
          'month': bookingMonth,
          'interiorWashes': 0,
          'exteriorWashes': 0,
          'tapiterieWashes': 0,
          'completeWashes': 0,
          'bookings': <BookingModel>[],
        };
      }

      final record = grouped[key]!;
      record['bookings'].add(booking);

      switch (booking.washType) {
        case WashType.interior:
          record['interiorWashes'] = (record['interiorWashes'] as int) + 1;
          break;
        case WashType.exterior:
          record['exteriorWashes'] = (record['exteriorWashes'] as int) + 1;
          break;
        case WashType.tapiterie:
          record['tapiterieWashes'] = (record['tapiterieWashes'] as int) + 1;
          break;
        case WashType.all:
          record['completeWashes'] = (record['completeWashes'] as int) + 1;
          break;
      }
    }

    return grouped.values.toList()
      ..sort((a, b) {
        final monthCompare = (b['month'] as String).compareTo(a['month'] as String);
        if (monthCompare != 0) return monthCompare;
        return (a['companyId'] as String).compareTo(b['companyId'] as String);
      });
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
      backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    Map<String, dynamic> record,
    CompanyModel? company,
    List<BookingModel> allBookings,
  ) {
    final theme = Theme.of(context);
    final monthDate = _parseMonth(record['month'] as String);
    final bookings = record['bookings'] as List<BookingModel>;
    final totalServices = (record['interiorWashes'] as int) +
        (record['exteriorWashes'] as int) +
        (record['tapiterieWashes'] as int) +
        (record['completeWashes'] as int);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          _showRecordDetails(context, record, company, bookings);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      company?.name ?? 'Companie necunoscută',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    color: AppColors.primary,
                    tooltip: 'Exportă',
                    onPressed: () => _exportRecord(context, record, company, bookings),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatMonth(record['month'] as String),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildServiceBadge(
                      'Interior',
                      record['interiorWashes'] as int,
                      AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildServiceBadge(
                      'Exterior',
                      record['exteriorWashes'] as int,
                      AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildServiceBadge(
                      'Tapițerie',
                      record['tapiterieWashes'] as int,
                      AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildServiceBadge(
                      'Complet',
                      record['completeWashes'] as int,
                      AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total servicii',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$totalServices',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${bookings.length} servicii finalizate • Apasă pentru detalii',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordDetails(
    BuildContext context,
    Map<String, dynamic> record,
    CompanyModel? company,
    List<BookingModel> bookings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company?.name ?? 'Companie necunoscută',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatMonth(record['month'] as String),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _buildBookingDetailCard(context, booking);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDetailCard(BuildContext context, BookingModel booking) {
    final theme = Theme.of(context);
    final bookingDate = DateTime.parse(booking.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getWashTypeIcon(booking.washType),
                  color: _getWashTypeColor(booking.washType),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getWashTypeLabel(booking.washType),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getWashTypeColor(booking.washType),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.calendar_today, 'Data',
                DateFormat('dd MMMM yyyy', 'ro_RO').format(bookingDate)),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.access_time, 'Ora',
                '${booking.slotStart} - ${booking.slotEnd}'),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.location_on, 'Locație', booking.addressText),
            if (booking.description != null && booking.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(Icons.note, 'Note', booking.description!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getWashTypeIcon(WashType type) {
    switch (type) {
      case WashType.interior:
        return Icons.air;
      case WashType.exterior:
        return Icons.water_drop;
      case WashType.tapiterie:
        return Icons.chair;
      case WashType.all:
        return Icons.all_inclusive;
    }
  }

  Color _getWashTypeColor(WashType type) {
    switch (type) {
      case WashType.interior:
        return AppColors.secondary;
      case WashType.exterior:
        return AppColors.primary;
      case WashType.tapiterie:
        return AppColors.warning;
      case WashType.all:
        return AppColors.darkNavy;
    }
  }

  String _getWashTypeLabel(WashType type) {
    switch (type) {
      case WashType.interior:
        return 'Spălare Interior';
      case WashType.exterior:
        return 'Spălare Exterior';
      case WashType.tapiterie:
        return 'Spălare Tapițerie';
      case WashType.all:
        return 'Spălare Completă';
    }
  }


  void _exportRecord(
    BuildContext context,
    Map<String, dynamic> record,
    CompanyModel? company,
    List<BookingModel> bookings,
  ) async {
    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu există servicii de exportat'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final format = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.download,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exportă înregistrare',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company?.name ?? 'Companie necunoscută',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatMonth(record['month'] as String),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // Format selection
              Text(
                'Selectează formatul:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Excel option
              InkWell(
                onTap: () => Navigator.pop(context, 'excel'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.table_chart,
                          color: AppColors.success,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Excel (.xlsx)',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tabel editabil',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // PDF option
              InkWell(
                onTap: () => Navigator.pop(context, 'pdf'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: AppColors.error,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PDF (.pdf)',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Document pentru printare',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Anulează',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (format != null && context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se exportă...'),
            duration: Duration(seconds: 1),
          ),
        );

        // Fetch vehicles and pricing
        final vehicleRepo = ref.read(vehicleRepositoryProvider);
        final vehicles = <String, VehicleModel>{};
        for (var booking in bookings) {
          // Skip if vehicleId is empty or null
          if (booking.vehicleId.isEmpty) {
            continue;
          }
          if (!vehicles.containsKey(booking.vehicleId)) {
            try {
              final vehicle = await vehicleRepo.getVehicleById(booking.vehicleId);
              if (vehicle != null) {
                vehicles[booking.vehicleId] = vehicle;
              }
            } catch (e) {
              // If vehicle fetch fails, continue without it
              debugPrint('Failed to fetch vehicle ${booking.vehicleId}: $e');
            }
          }
        }

        final pricingAsync = ref.read(getCurrentPricingProvider.future);
        final pricing = await pricingAsync;

        final serviceRecord = _createServiceRecordFromGroup(record);

        if (format == 'excel') {
          await ExportService.exportRecordToExcel(
            serviceRecord,
            company,
            bookings,
            vehicles,
            pricing,
          );
        } else {
          await ExportService.exportRecordToPDF(
            serviceRecord,
            company,
            bookings,
            vehicles,
            pricing,
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export realizat cu succes!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Eroare la export: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  ServiceRecordModel _createServiceRecordFromGroup(Map<String, dynamic> group) {
    final now = DateTime.now();
    return ServiceRecordModel(
      id: '',
      companyId: group['companyId'] as String,
      month: group['month'] as String,
      interiorWashes: group['interiorWashes'] as int,
      exteriorWashes: group['exteriorWashes'] as int,
      tapiterieWashes: group['tapiterieWashes'] as int,
      completeWashes: group['completeWashes'] as int,
      notes: null,
      isFinalized: false,
      createdBy: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  String _formatMonth(String month) {
    try {
      final date = _parseMonth(month);
      return DateFormat('MMMM yyyy', 'ro_RO').format(date);
    } catch (e) {
      return month;
    }
  }

  DateTime _parseMonth(String month) {
    final parts = month.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Show custom month picker dialog
  Future<void> _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedMonth != null
        ? _parseMonth(_selectedMonth!)
        : DateTime(now.year, now.month);
    
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Selectează luna'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setDialogState(() {
                          selectedYear--;
                        });
                      },
                    ),
                    Text(
                      selectedYear.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setDialogState(() {
                          selectedYear++;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Month grid
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = selectedMonth == month;
                    final monthName = DateFormat('MMM', 'ro_RO')
                        .format(DateTime(selectedYear, month));
                    
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedMonth = month;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outline,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            monthName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  DateTime(selectedYear, selectedMonth),
                );
              },
              child: const Text('Selectează'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedMonth =
            '${result.year}-${result.month.toString().padLeft(2, '0')}';
      });
    }
  }
}

