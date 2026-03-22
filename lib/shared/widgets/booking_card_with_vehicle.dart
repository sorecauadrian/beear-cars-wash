import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/bookings/data/models/booking_model.dart';
import '../../features/vehicles/data/models/vehicle_model.dart';
import '../../features/vehicles/presentation/providers/vehicle_provider.dart';
import 'booking_card.dart';

final vehicleByIdProvider = FutureProvider.family<VehicleModel?, String>(
  (ref, vehicleId) async {
    final repository = ref.watch(vehicleRepositoryProvider);
    try {
      return await repository.getVehicleById(vehicleId);
    } catch (_) {
      return null;
    }
  },
);

class BookingCardWithVehicle extends ConsumerWidget {
  final BookingModel booking;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final bool compact;

  const BookingCardWithVehicle({
    super.key,
    required this.booking,
    this.onTap,
    this.actions,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleByIdProvider(booking.vehicleId));
    final vehicle = vehicleAsync.whenOrNull(data: (v) => v);

    return BookingCard(
      booking: booking,
      vehiclePlate: vehicle?.plateNumber,
      vehicleDescription: vehicle?.description,
      onTap: onTap,
      actions: actions,
      compact: compact,
    );
  }
}
