import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/app_logo.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/notification_sender_service.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/companies/data/repositories/company_repository.dart';
import '../../../../../features/companies/data/models/company_model.dart';
import '../../../../../features/companies/presentation/providers/company_provider.dart';
import '../../../../vehicles/data/repositories/vehicle_repository.dart';
import '../../../../vehicles/data/models/vehicle_model.dart';
import '../../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../../../../shared/widgets/booking_status_chip.dart';
import '../../../../../shared/widgets/date_grouped_bookings_list.dart';
import 'package:go_router/go_router.dart';

/// BeeAR Admin home screen - Bookings list with filters
class AdminBookingsListScreen extends ConsumerStatefulWidget {
  const AdminBookingsListScreen({super.key});

  @override
  ConsumerState<AdminBookingsListScreen> createState() =>
      _AdminBookingsListScreenState();
}

class _AdminBookingsListScreenState
    extends ConsumerState<AdminBookingsListScreen> {
  String? _selectedCompanyId;
  String? _selectedDate;
  BookingStatus? _selectedStatus;
  bool _showCompleted = false;
  // REMOVE: final _companiesAsync = FutureProvider<List<CompanyModel>>((ref) async {
  // REMOVE:   final repository = CompanyRepository();
  // REMOVE:   return repository.getAllCompanies();
  // REMOVE: });

  @override
  Widget build(BuildContext context) {
    // Wait for user data to be loaded to avoid permission errors on first load
    final userAsync = ref.watch(currentUserProvider);
    final bookingsAsync = ref.watch(allBookingsProvider);
    final companiesAsync = ref.watch(allCompaniesProvider);
    
    // Show loading if user data is not yet loaded (prevents permission errors)
    if (userAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 32, withText: false),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrează',
            onPressed: () => _showFilterDialog(context, companiesAsync),
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref),
      body: Column(
        children: [
          // Toggle completed bookings
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Arată finalizate',
                  style: TextStyle(fontSize: 14),
                ),
                const Spacer(),
                Switch(
                  value: _showCompleted,
                  onChanged: (value) {
                    setState(() {
                      _showCompleted = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // Orphaned bookings warning
          bookingsAsync.when(
            data: (bookings) {
              final orphanedBookings = _getOrphanedBookings(bookings, companiesAsync.value ?? []);
              if (orphanedBookings.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${orphanedBookings.length} rezervări cu companii inexistente găsite',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showDeleteOrphanedBookingsDialog(
                        context,
                        ref,
                        orphanedBookings,
                      ),
                      child: Text(
                        'Șterge',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Active filters display
          if (_selectedCompanyId != null ||
              _selectedDate != null ||
              _selectedStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_selectedCompanyId != null)
                          Chip(
                            label: Text(
                              companiesAsync.value?.firstWhere(
                                        (c) => c.id == _selectedCompanyId,
                                      ).name ??
                                  'Company',
                            ),
                            onDeleted: () {
                              setState(() {
                                _selectedCompanyId = null;
                              });
                            },
                          ),
                        if (_selectedDate != null)
                          Chip(
                            label: Text(
                              DateTimeUtils.formatDateDisplay(
                                DateTimeUtils.parseDate(_selectedDate!) ?? DateTime.now(),
                              ),
                            ),
                            onDeleted: () {
                              setState(() {
                                _selectedDate = null;
                              });
                            },
                          ),
                        if (_selectedStatus != null)
                          Chip(
                            label: Text(_getStatusLabel(_selectedStatus!)),
                            onDeleted: () {
                              setState(() {
                                _selectedStatus = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCompanyId = null;
                        _selectedDate = null;
                        _selectedStatus = null;
                      });
                    },
                    child: const Text('Șterge toate'),
                  ),
                ],
              ),
            ),

          // Bookings list
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                // Apply filters
                var filteredBookings = bookings;
                
                // Filter out completed bookings if toggle is off
                if (!_showCompleted) {
                  filteredBookings = filteredBookings
                      .where((b) => b.status != BookingStatus.done)
                      .toList();
                }
                
                if (_selectedCompanyId != null) {
                  filteredBookings = filteredBookings
                      .where((b) => b.companyId == _selectedCompanyId)
                      .toList();
                }
                if (_selectedDate != null) {
                  filteredBookings = filteredBookings
                      .where((b) => b.date == _selectedDate)
                      .toList();
                }
                if (_selectedStatus != null) {
                  filteredBookings = filteredBookings
                      .where((b) => b.status == _selectedStatus)
                      .toList();
                }

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nu există rezervări',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        if (_selectedCompanyId != null ||
                            _selectedDate != null ||
                            _selectedStatus != null)
                          const SizedBox(height: 8),
                        if (_selectedCompanyId != null ||
                            _selectedDate != null ||
                            _selectedStatus != null)
                          const Text(
                            'Încearcă să ajustezi filtrele',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allBookingsProvider);
                  },
                  child: DateGroupedBookingsList(
                    bookings: filteredBookings,
                    emptyBuilder: () => const SizedBox.shrink(),
                    itemBuilder: (context, booking) {
                      // Get company name
                      final companyName = companiesAsync.value?.firstWhere(
                        (c) => c.id == booking.companyId,
                        orElse: () => CompanyModel(
                          id: booking.companyId,
                          name: 'Companie necunoscută',
                          clientType: ClientType.persoanaJuridica,
                          email: '',
                          password: '',
                          city: '',
                          isActive: true,
                        ),
                      ).name ?? 'Companie necunoscută';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _getStatusColor(booking.status).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        color: _getStatusColor(booking.status).withValues(alpha: 0.05),
                        child: ListTile(
                          leading: _getWashTypeIconWidget(booking.washType),
                          title: Text(
                            companyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: _getStatusColor(booking.status),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${booking.slotStart} - ${booking.slotEnd}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(booking.status),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      booking.addressText,
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getWashTypeLabel(booking.washType),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: BookingStatusChip(status: booking.status),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right, size: 18),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          onTap: () {
                            _showStatusChangeDialog(context, ref, booking);
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
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(allBookingsProvider);
                      },
                      child: const Text('Retry'),
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

  void _showFilterDialog(
    BuildContext context,
    AsyncValue<List<CompanyModel>> companiesAsync,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
        title: const Text('Filtrează rezervările'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Company filter
              companiesAsync.when(
                data: (companies) => DropdownButtonFormField<String>(
                  value: _selectedCompanyId,
                  decoration: const InputDecoration(
                    labelText: 'Companie',
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Toate companiile'),
                    ),
                    ...companies.map((company) {
                      return DropdownMenuItem(
                        value: company.id,
                        child: Text(company.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCompanyId = value;
                    });
                    setDialogState(() {});
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Eroare la încărcarea companiilor'),
              ),
              const SizedBox(height: 16),

              // Date filter
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate != null
                        ? DateTimeUtils.parseDate(_selectedDate!) ?? DateTime.now()
                        : DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('ro', 'RO'),
                  );
                  if (picked != null && mounted) {
                    setState(() {
                      _selectedDate = DateTimeUtils.formatDate(picked);
                    });
                    setDialogState(() {});
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Dată',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? DateTimeUtils.formatDateDisplay(
                            DateTimeUtils.parseDate(_selectedDate!) ?? DateTime.now(),
                          )
                        : 'Selectează o dată',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                    });
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Șterge data'),
                ),
              ],
              const SizedBox(height: 16),

              // Status filter
              DropdownButtonFormField<BookingStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Toate statusurile'),
                  ),
                  const DropdownMenuItem(
                    value: BookingStatus.accepted,
                    child: Text('Acceptat'),
                  ),
                  const DropdownMenuItem(
                    value: BookingStatus.inProgress,
                    child: Text('În progres'),
                  ),
                  const DropdownMenuItem(
                    value: BookingStatus.done,
                    child: Text('Finalizat'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  setDialogState(() {});
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Închide'),
          ),
        ],
      );
        },
      ),
    );
  }

  void _showStatusChangeDialog(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalii rezervare',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          BookingStatusChip(status: booking.status),
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
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FutureBuilder<CompanyModel?>(
                    future: _getCompany(booking.companyId),
                    builder: (context, companySnapshot) {
                      return FutureBuilder<VehicleModel?>(
                        future: _getVehicle(booking.vehicleId),
                        builder: (context, vehicleSnapshot) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Company Info
                              _buildInfoSection(
                                icon: Icons.business,
                                title: 'Companie',
                                content: companySnapshot.data?.name ?? 'Companie necunoscută',
                              ),
                              const SizedBox(height: 16),
                              
                              // Date & Time
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      icon: Icons.calendar_today,
                                      label: 'Dată',
                                      value: DateTimeUtils.formatDateDisplay(
                                        DateTimeUtils.parseDate(booking.date) ?? DateTime.now(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInfoCard(
                                      icon: Icons.access_time,
                                      label: 'Ora',
                                      value: '${booking.slotStart}–${booking.slotEnd}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Address
                              _buildInfoSection(
                                icon: Icons.location_on,
                                title: 'Adresă',
                                content: booking.addressText,
                                action: booking.lat != null && booking.lng != null
                                    ? IconButton(
                                        icon: const Icon(Icons.map, size: 20),
                                        tooltip: 'Deschide în hartă',
                                        onPressed: () {
                                          // TODO: Open in maps app
                                        },
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              
                              // Vehicle Section
                              const Text(
                                'Mașină',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (vehicleSnapshot.hasData && vehicleSnapshot.data != null)
                                _buildVehicleCard(
                                  vehicle: vehicleSnapshot.data!,
                                  washType: booking.washType,
                                )
                              else
                                _buildVehicleCard(
                                  vehicle: VehicleModel(
                                    id: booking.vehicleId,
                                    companyId: booking.companyId,
                                    plateNumber: 'Necunoscut',
                                  ),
                                  washType: booking.washType,
                                ),
                              
                              // Description if available
                              if (booking.description != null && booking.description!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildInfoSection(
                                  icon: Icons.note,
                                  title: 'Note',
                                  content: booking.description!,
                                ),
                              ],
                              
                              // Status Change Section
                              if (_getAvailableStatuses(booking.status).isNotEmpty) ...[
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 16),
                                const Text(
                                  'Schimbă statusul',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._getAvailableStatuses(booking.status).map((status) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          _getWashTypeIcon(booking.washType),
                                          size: 24,
                                          color: _getWashTypeColor(booking.washType),
                                        ),
                                      ),
                                      title: Text(
                                        _getStatusLabel(status),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        _getStatusDescription(status),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: _getStatusColor(status),
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await _updateStatus(ref, booking, status);
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<CompanyModel?> _getCompany(String companyId) async {
    try {
      final repository = CompanyRepository();
      return await repository.getCompanyById(companyId);
    } catch (e) {
      return null;
    }
  }

  Future<VehicleModel?> _getVehicle(String vehicleId) async {
    try {
      final repository = VehicleRepository();
      return await repository.getVehicleById(vehicleId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            if (action != null) const Spacer(),
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            content,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard({
    required VehicleModel vehicle,
    required WashType washType,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getWashTypeColor(washType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getWashTypeIcon(washType),
                    size: 28,
                    color: _getWashTypeColor(washType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Număr înmatriculare',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.plateNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.local_car_wash, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  _getWashTypeLabel(washType),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (vehicle.description != null && vehicle.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        vehicle.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.done:
        return Colors.green;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.cancelled:
        return Colors.orange.shade300; // Light orange for cancelled
    }
  }

  Widget _getWashTypeIconWidget(WashType washType) {
    final icon = _getWashTypeIcon(washType);
    final color = _getWashTypeColor(washType);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Color _getWashTypeColor(WashType washType) {
    switch (washType) {
      case WashType.interior:
        return Colors.blue;
      case WashType.exterior:
        return Colors.cyan;
      case WashType.tapiterie:
        return Colors.orange;
      case WashType.all:
        return Colors.orange;
    }
  }

  IconData _getWashTypeIcon(WashType washType) {
    switch (washType) {
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

  String _getWashTypeLabel(WashType washType) {
    switch (washType) {
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

  String _getStatusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.inProgress:
        return 'Marchează că ai început spălarea';
      case BookingStatus.done:
        return 'Marchează că spălarea este finalizată';
      default:
        return '';
    }
  }

  List<BookingStatus> _getAvailableStatuses(BookingStatus currentStatus) {
    switch (currentStatus) {
      case BookingStatus.requested:
        return [BookingStatus.accepted, BookingStatus.rejected, BookingStatus.cancelled];
      case BookingStatus.accepted:
        return [BookingStatus.inProgress, BookingStatus.cancelled]; // Admin can cancel accepted bookings
      case BookingStatus.inProgress:
        return [BookingStatus.done, BookingStatus.cancelled]; // Can cancel even if in progress
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
      case BookingStatus.done:
        return []; // No status changes allowed
    }
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return 'Solicitat';
      case BookingStatus.accepted:
        return 'Acceptat';
      case BookingStatus.rejected:
        return 'Respins';
      case BookingStatus.cancelled:
        return 'Anulat';
      case BookingStatus.inProgress:
        return 'În progres';
      case BookingStatus.done:
        return 'Finalizat';
    }
  }

  Future<void> _updateStatus(
    WidgetRef ref,
    BookingModel booking,
    BookingStatus newStatus,
  ) async {
    if (!mounted) return;
    
    try {
      final repository = ref.read(bookingRepositoryProvider);
      final oldStatus = booking.status;
      
      // Update booking status
      await repository.updateBookingStatus(booking.id, newStatus);

      // Send notification to company admin
      final notificationService = NotificationSenderService();
      await notificationService.sendBookingStatusNotification(
        booking: booking,
        oldStatus: oldStatus,
        newStatus: newStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status actualizat la: ${_getStatusLabel(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final userAsync = ref.watch(currentUserProvider);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary,
            ),
            child: userAsync.when(
              data: (user) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const AppLogo(height: 32, isWhite: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user?.name ?? 'Administrator',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const AppLogo(height: 32, isWhite: true),
                  const SizedBox(height: 8),
                  Text(
                    'Administrator',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.event,
            title: 'Rezervări',
            isSelected: currentRoute == RouteNames.adminHome || 
                       currentRoute == RouteNames.adminBookingsList,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != RouteNames.adminHome) {
                context.go(RouteNames.adminHome);
              }
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.description,
            title: 'Registre Servicii',
            isSelected: currentRoute == RouteNames.serviceRecordsList,
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.serviceRecordsList);
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.business,
            title: 'Clienți',
            isSelected: currentRoute == RouteNames.companiesList ||
                       currentRoute.startsWith(RouteNames.addCompany) ||
                       currentRoute.startsWith(RouteNames.editCompany),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.companiesList);
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.attach_money,
            title: 'Prețuri',
            isSelected: currentRoute == RouteNames.pricing,
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.pricing);
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings,
            title: 'Setări',
            isSelected: currentRoute == RouteNames.adminSettings,
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.adminSettings);
            },
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.logout,
            title: 'Deconectare',
            isSelected: false,
            onTap: () async {
              Navigator.pop(context);
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }

  /// Get bookings with missing companies (orphaned bookings)
  List<BookingModel> _getOrphanedBookings(
    List<BookingModel> bookings,
    List<CompanyModel> companies,
  ) {
    final companyIds = companies.map((c) => c.id).toSet();
    return bookings.where((booking) => !companyIds.contains(booking.companyId)).toList();
  }

  /// Show dialog to confirm deletion of orphaned bookings
  Future<void> _showDeleteOrphanedBookingsDialog(
    BuildContext context,
    WidgetRef ref,
    List<BookingModel> orphanedBookings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge rezervările orfane'),
        content: Text(
          'Ești sigur că vrei să ștergi ${orphanedBookings.length} rezervări cu companii inexistente?\n\n'
          'Această acțiune nu poate fi anulată.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Delete all orphaned bookings
        final repository = ref.read(bookingRepositoryProvider);
        for (final booking in orphanedBookings) {
          await repository.deleteBooking(booking.id);
        }

        // Refresh bookings
        ref.invalidate(allBookingsProvider);

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${orphanedBookings.length} rezervări au fost șterse cu succes',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Eroare la ștergere: ${e.toString()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
