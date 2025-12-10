import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/vehicles/data/repositories/vehicle_repository.dart';
import '../../../../../features/vehicles/data/models/vehicle_model.dart';
import '../../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../../../../shared/widgets/booking_status_chip.dart';
import '../../../../../shared/widgets/date_grouped_bookings_list.dart';

/// Customer bookings list screen
class CustomerBookingsListScreen extends ConsumerStatefulWidget {
  const CustomerBookingsListScreen({super.key});

  @override
  ConsumerState<CustomerBookingsListScreen> createState() =>
      _CustomerBookingsListScreenState();
}

class _CustomerBookingsListScreenState
    extends ConsumerState<CustomerBookingsListScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Column(
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
        // Bookings list
        Expanded(
          child: bookingsAsync.when(
            data: (bookings) {
              // Filter out completed bookings if toggle is off
              var filteredBookings = bookings;
              if (!_showCompleted) {
                filteredBookings = filteredBookings
                    .where((b) => b.status != BookingStatus.done)
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
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myBookingsProvider);
                },
                child: DateGroupedBookingsList(
                  bookings: filteredBookings,
                  emptyBuilder: () => const SizedBox.shrink(),
                  itemBuilder: (context, booking) {
                    return FutureBuilder<VehicleModel?>(
                      future: _getVehicle(booking.vehicleId),
                      builder: (context, vehicleSnapshot) {
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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with status
                                Row(
                                  children: [
                                    _getWashTypeIcon(booking.washType),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vehicleSnapshot.data?.plateNumber ?? 'Mașină necunoscută',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getWashTypeLabel(booking.washType),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    BookingStatusChip(status: booking.status),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Date and time
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: _getStatusColor(booking.status),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        DateTimeUtils.formatDateDisplay(
                                          DateTimeUtils.parseDate(booking.date) ??
                                              DateTime.now(),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: _getStatusColor(booking.status),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${booking.slotStart} - ${booking.slotEnd}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Address
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        booking.addressText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                  Text('Eroare: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(myBookingsProvider);
                    },
                    child: const Text('Încearcă din nou'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<VehicleModel?> _getVehicle(String vehicleId) async {
    try {
      final repository = VehicleRepository();
      return await repository.getVehicleById(vehicleId);
    } catch (e) {
      return null;
    }
  }

  Widget _getWashTypeIcon(WashType washType) {
    IconData icon;
    Color color;
    switch (washType) {
      case WashType.interior:
        icon = Icons.air;
        color = Colors.blue;
        break;
      case WashType.exterior:
        icon = Icons.water_drop;
        color = Colors.cyan;
        break;
      case WashType.tapiterie:
        icon = Icons.chair;
        color = Colors.orange;
        break;
      case WashType.all:
        icon = Icons.all_inclusive;
        color = Colors.orange;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
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

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return AppColors.requested;
      case BookingStatus.accepted:
        return AppColors.accepted;
      case BookingStatus.inProgress:
        return AppColors.inProgress;
      case BookingStatus.done:
        return AppColors.done;
      case BookingStatus.rejected:
        return AppColors.rejected;
      case BookingStatus.cancelled:
        return AppColors.cancelled;
    }
  }
}

