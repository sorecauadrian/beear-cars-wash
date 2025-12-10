import 'package:flutter/material.dart';
import '../../../features/bookings/data/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';

/// Widget to display booking status with color coding
class BookingStatusChip extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusChip({
    super.key,
    required this.status,
  });

  Color get _statusColor {
    switch (status) {
      case BookingStatus.requested:
        return AppColors.requested;
      case BookingStatus.accepted:
        return AppColors.accepted;
      case BookingStatus.rejected:
        return AppColors.rejected;
      case BookingStatus.cancelled:
        return AppColors.cancelled;
      case BookingStatus.inProgress:
        return AppColors.inProgress;
      case BookingStatus.done:
        return AppColors.done;
    }
  }

  String get _statusLabel {
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

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        _statusLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: _statusColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

