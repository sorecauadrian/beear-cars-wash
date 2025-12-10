import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/data/repositories/booking_repository.dart';
import '../models/service_record_model.dart';
import 'package:intl/intl.dart';

/// Service to calculate service records from completed bookings
class ServiceRecordCalculator {
  final BookingRepository _bookingRepository;

  ServiceRecordCalculator(this._bookingRepository);

  /// Calculate service record for a company and month from completed bookings
  Future<ServiceRecordModel?> calculateRecordForCompanyAndMonth(
    String companyId,
    String month, // Format: "YYYY-MM"
  ) async {
    try {
      // Get all completed bookings for the company
      final bookings = await _bookingRepository.getAllBookings(
        companyId: companyId,
        status: BookingStatus.done,
      );

      // Filter bookings for the specific month
      final monthBookings = bookings.where((booking) {
        final bookingDate = DateTime.parse(booking.date);
        final bookingMonth = '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}';
        return bookingMonth == month;
      }).toList();

      if (monthBookings.isEmpty) {
        return null; // No completed bookings for this month
      }

      // Count services by type
      int interiorWashes = 0;
      int exteriorWashes = 0;
      int tapiterieWashes = 0;
      int completeWashes = 0;

      for (var booking in monthBookings) {
        switch (booking.washType) {
          case WashType.interior:
            interiorWashes++;
            break;
          case WashType.exterior:
            exteriorWashes++;
            break;
          case WashType.tapiterie:
            tapiterieWashes++;
            break;
          case WashType.all:
            completeWashes++;
            break;
        }
      }

      // Create service record
      final now = DateTime.now();
      return ServiceRecordModel(
        id: '', // Will be set when saved
        companyId: companyId,
        month: month,
        interiorWashes: interiorWashes,
        exteriorWashes: exteriorWashes,
        tapiterieWashes: tapiterieWashes,
        completeWashes: completeWashes,
        notes: null,
        isFinalized: false,
        createdBy: null,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw Exception('Failed to calculate service record: ${e.toString()}');
    }
  }

  /// Get all service records for all companies for a specific month
  Future<Map<String, ServiceRecordModel>> calculateRecordsForMonth(
    String month,
    List<String> companyIds,
  ) async {
    final records = <String, ServiceRecordModel>{};

    for (var companyId in companyIds) {
      final record = await calculateRecordForCompanyAndMonth(companyId, month);
      if (record != null) {
        records[companyId] = record;
      }
    }

    return records;
  }

  /// Get bookings breakdown for a service record
  Future<List<BookingModel>> getBookingsForRecord(
    String companyId,
    String month,
  ) async {
    try {
      final bookings = await _bookingRepository.getAllBookings(
        companyId: companyId,
        status: BookingStatus.done,
      );

      return bookings.where((booking) {
        final bookingDate = DateTime.parse(booking.date);
        final bookingMonth = '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}';
        return bookingMonth == month;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get bookings: ${e.toString()}');
    }
  }
}

