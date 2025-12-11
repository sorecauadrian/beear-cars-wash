import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/models/booking_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/date_time_utils.dart';

/// Booking repository provider
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

/// Create booking provider
final createBookingProvider = Provider.family<Future<String>, CreateBookingParams>(
  (ref, params) async {
    final repository = ref.read(bookingRepositoryProvider);
    final userAsync = ref.read(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null || user.companyId == null) {
          throw Exception('User not found or no company assigned');
        }

        final now = DateTime.now();
        final booking = BookingModel(
          id: '', // Will be set by repository
          companyId: user.companyId!,
          vehicleId: params.vehicleId,
          washType: params.washType,
          addressText: params.addressText,
          lat: params.lat,
          lng: params.lng,
          description: params.description,
          date: params.date,
          slotStart: params.slotStart,
          slotEnd: DateTimeUtils.getEndSlot(params.slotStart),
          status: BookingStatus.requested,
          createdAt: now,
          updatedAt: now,
        );

        return repository.createBooking(booking);
      },
      loading: () => throw Exception('User data loading'),
      error: (e, _) => throw Exception('User error: $e'),
    );
  },
);

/// Delete booking provider
final deleteBookingProvider = Provider.family<Future<void>, String>(
  (ref, bookingId) async {
    final repository = ref.read(bookingRepositoryProvider);
    return repository.deleteBooking(bookingId);
  },
);

/// Delete multiple bookings provider
final deleteBookingsProvider = Provider.family<Future<void>, List<String>>(
  (ref, bookingIds) async {
    final repository = ref.read(bookingRepositoryProvider);
    for (final bookingId in bookingIds) {
      await repository.deleteBooking(bookingId);
    }
  },
);

/// Get bookings for current user's company
final myBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final repository = ref.watch(bookingRepositoryProvider);

  return userAsync.when(
    data: (user) {
      if (user == null || user.companyId == null) {
        return Stream.value([]);
      }
      return repository.getAllBookingsStream(companyId: user.companyId!);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Get all bookings (for admin)
final allBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final repository = ref.watch(bookingRepositoryProvider);

  return userAsync.when(
    data: (user) {
      // Only proceed if user is loaded (needed for Firestore rules to check admin role)
      if (user == null) {
        return Stream.value([]);
      }
      return repository.getAllBookingsStream();
    },
    loading: () => Stream.value([]), // Return empty stream while loading
    error: (_, __) => Stream.value([]), // Return empty stream on error
  );
});

/// Get bookings with filters (for admin)
final filteredBookingsProvider = StreamProvider.family<
    List<BookingModel>, FilteredBookingsParams>(
  (ref, params) {
    final repository = ref.watch(bookingRepositoryProvider);
    return repository.getAllBookingsStream(
      companyId: params.companyId,
      date: params.date,
      status: params.status,
    );
  },
);

/// Create booking parameters
class CreateBookingParams {
  final String vehicleId;
  final WashType washType;
  final String addressText;
  final double? lat;
  final double? lng;
  final String? description;
  final String date; // YYYY-MM-DD
  final String slotStart; // HH:mm

  CreateBookingParams({
    required this.vehicleId,
    required this.washType,
    required this.addressText,
    this.lat,
    this.lng,
    this.description,
    required this.date,
    required this.slotStart,
  });
}

/// Filtered bookings parameters
class FilteredBookingsParams {
  final String? companyId;
  final String? date;
  final BookingStatus? status;

  FilteredBookingsParams({
    this.companyId,
    this.date,
    this.status,
  });
}

