import 'package:flutter/material.dart';
import '../../features/bookings/data/models/booking_model.dart';
import 'status_badge.dart';

/// Legacy wrapper -- delegates to StatusBadge
class BookingStatusChip extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(status: status);
  }
}
