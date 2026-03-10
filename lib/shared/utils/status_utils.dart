import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/bookings/data/models/booking_model.dart';

class StatusUtils {
  StatusUtils._();

  static Color color(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return AppColors.statusPending;
      case BookingStatus.accepted:
        return AppColors.statusAccepted;
      case BookingStatus.inProgress:
        return AppColors.statusInProgress;
      case BookingStatus.done:
        return AppColors.statusSuccess;
      case BookingStatus.rejected:
        return AppColors.statusRejected;
      case BookingStatus.cancelled:
        return AppColors.statusRejected;
    }
  }

  static String label(BookingStatus status) {
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

  static IconData icon(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return Icons.schedule_rounded;
      case BookingStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case BookingStatus.rejected:
        return Icons.cancel_outlined;
      case BookingStatus.cancelled:
        return Icons.block_rounded;
      case BookingStatus.inProgress:
        return Icons.play_circle_outline_rounded;
      case BookingStatus.done:
        return Icons.task_alt_rounded;
    }
  }

  static String description(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return 'Rezervarea a fost trimisă';
      case BookingStatus.accepted:
        return 'Rezervarea a fost confirmată';
      case BookingStatus.rejected:
        return 'Rezervarea a fost respinsă';
      case BookingStatus.cancelled:
        return 'Rezervarea a fost anulată';
      case BookingStatus.inProgress:
        return 'Spălarea este în desfășurare';
      case BookingStatus.done:
        return 'Spălarea a fost finalizată';
    }
  }

  static List<BookingStatus> availableTransitions(BookingStatus current) {
    switch (current) {
      case BookingStatus.requested:
        return [BookingStatus.accepted, BookingStatus.rejected, BookingStatus.cancelled];
      case BookingStatus.accepted:
        return [BookingStatus.inProgress, BookingStatus.cancelled];
      case BookingStatus.inProgress:
        return [BookingStatus.done, BookingStatus.cancelled];
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
      case BookingStatus.done:
        return [];
    }
  }
}
