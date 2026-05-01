import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../../../../core/constants/firestore_paths.dart';

/// Booking repository
/// Handles all Firestore operations for bookings
class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all bookings
  Future<List<BookingModel>> getAllBookings({
    String? companyId,
    String? date,
    BookingStatus? status,
  }) async {
    try {
      Query query = _firestore.collection(FirestorePaths.bookings);

      // Apply filters
      if (companyId != null) {
        query = query.where('companyId', isEqualTo: companyId);
      }
      if (date != null) {
        query = query.where('date', isEqualTo: date);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.toString());
      }

      // Order by date and time
      query = query.orderBy('date').orderBy('slotStart');

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookings: ${e.toString()}');
    }
  }

  /// Get bookings stream
  Stream<List<BookingModel>> getAllBookingsStream({
    String? companyId,
    String? date,
    BookingStatus? status,
  }) {
    Query query = _firestore.collection(FirestorePaths.bookings);

    // Apply filters
    if (companyId != null) {
      query = query.where('companyId', isEqualTo: companyId);
    }
    if (date != null) {
      query = query.where('date', isEqualTo: date);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString());
    }

    // Order by date and time
    query = query.orderBy('date').orderBy('slotStart');

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList());
  }

  /// Get bookings for a company
  Future<List<BookingModel>> getBookingsByCompany(String companyId) async {
    return getAllBookings(companyId: companyId);
  }

  /// Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.bookings)
          .doc(bookingId)
          .get();

      if (!doc.exists) return null;
      return BookingModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get booking: ${e.toString()}');
    }
  }

  /// Create a new booking
  Future<String> createBooking(BookingModel booking) async {
    try {
      final docRef = await _firestore
          .collection(FirestorePaths.bookings)
          .add(booking.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  /// Update booking
  Future<void> updateBooking(BookingModel booking) async {
    try {
      // Always update updatedAt timestamp
      final updatedBooking = booking.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(FirestorePaths.bookings)
          .doc(booking.id)
          .update(updatedBooking.toFirestore());
    } catch (e) {
      throw Exception('Failed to update booking: ${e.toString()}');
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _firestore
          .collection(FirestorePaths.bookings)
          .doc(bookingId)
          .update({
        'status': status.toString(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update booking status: ${e.toString()}');
    }
  }

  /// Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore
          .collection(FirestorePaths.bookings)
          .doc(bookingId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete booking: ${e.toString()}');
    }
  }

  /// Get all bookings within a date range (inclusive)
  Future<List<BookingModel>> getBookingsForDateRange(String startDate, String endDate) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.bookings)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date')
          .orderBy('slotStart')
          .get();
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get bookings for date range: ${e.toString()}');
    }
  }

  /// Delete all bookings for a company
  Future<void> deleteBookingsByCompany(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.bookings)
          .where('companyId', isEqualTo: companyId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete bookings for company: ${e.toString()}');
    }
  }
}

