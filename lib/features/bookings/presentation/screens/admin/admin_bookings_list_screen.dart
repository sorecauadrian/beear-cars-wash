import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/app_logo.dart';
import '../../../../../core/services/notification_sender_service.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/companies/data/repositories/company_repository.dart';
import '../../../../../features/companies/data/models/company_model.dart';
import '../../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../../../../shared/widgets/booking_status_chip.dart';
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
  final _companiesAsync = FutureProvider<List<CompanyModel>>((ref) async {
    final repository = CompanyRepository();
    return repository.getAllCompanies();
  });

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(allBookingsProvider);
    final companiesAsync = ref.watch(_companiesAsync);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(height: 32),
            const SizedBox(width: 8),
            const Text('All Bookings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            tooltip: 'Companies',
            onPressed: () {
              context.push(RouteNames.companiesList);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () => _showFilterDialog(context, companiesAsync),
          ),
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
                            label: Text(_selectedDate!),
                            onDeleted: () {
                              setState(() {
                                _selectedDate = null;
                              });
                            },
                          ),
                        if (_selectedStatus != null)
                          Chip(
                            label: Text(_selectedStatus.toString()),
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
                    child: const Text('Clear'),
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
                          'No bookings found',
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
                            'Try adjusting your filters',
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
                  child: ListView.builder(
                    itemCount: filteredBookings.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      // Get company name
                      final companyName = companiesAsync.value?.firstWhere(
                        (c) => c.id == booking.companyId,
                        orElse: () => CompanyModel(
                          id: booking.companyId,
                          name: 'Unknown Company',
                          contractNumber: '',
                          city: '',
                          isActive: true,
                        ),
                      ).name ?? 'Unknown Company';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.local_car_wash),
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
                                  const Icon(Icons.calendar_today, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${booking.date} ${booking.slotStart}',
                                    style: const TextStyle(fontSize: 13),
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
                                'Wash: ${booking.washType.toString()}',
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
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Company filter
              companiesAsync.when(
                data: (companies) => DropdownButtonFormField<String>(
                  value: _selectedCompanyId,
                  decoration: const InputDecoration(
                    labelText: 'Company',
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Companies'),
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
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading companies'),
              ),
              const SizedBox(height: 16),

              // Date filter
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                initialValue: _selectedDate,
                onChanged: (value) {
                  setState(() {
                    _selectedDate = value.isEmpty ? null : value;
                  });
                },
              ),
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
                    child: Text('All Statuses'),
                  ),
                  ...BookingStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toString()),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
      builder: (context) => AlertDialog(
        title: const Text('Change Booking Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${booking.date}'),
            Text('Time: ${booking.slotStart} - ${booking.slotEnd}'),
            Text('Wash Type: ${booking.washType.toString()}'),
            const SizedBox(height: 16),
            const Text('New Status:'),
            const SizedBox(height: 8),
            ..._getAvailableStatuses(booking.status).map((status) {
              return ListTile(
                title: Text(_getStatusLabel(status)),
                leading: BookingStatusChip(status: status),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus(ref, booking, status);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  List<BookingStatus> _getAvailableStatuses(BookingStatus currentStatus) {
    switch (currentStatus) {
      case BookingStatus.requested:
        return [BookingStatus.accepted, BookingStatus.rejected];
      case BookingStatus.accepted:
        return [BookingStatus.inProgress];
      case BookingStatus.inProgress:
        return [BookingStatus.done];
      case BookingStatus.rejected:
      case BookingStatus.done:
        return []; // No status changes allowed
    }
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return 'Requested';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.done:
        return 'Done';
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
          content: Text('Status updated to ${_getStatusLabel(newStatus)}'),
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
}
