import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Date and time utility functions
class DateTimeUtils {
  DateTimeUtils._();

  /// Format date as YYYY-MM-DD
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  /// Format time as HH:mm
  static String formatTime(DateTime time) {
    return DateFormat(AppConstants.timeFormat).format(time);
  }

  /// Format date for display (dd MMM yyyy)
  static String formatDateDisplay(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  /// Parse date from YYYY-MM-DD string
  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat(AppConstants.dateFormat).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse time from HH:mm string
  static DateTime? parseTime(String timeString) {
    try {
      return DateFormat(AppConstants.timeFormat).parse(timeString);
    } catch (e) {
      return null;
    }
  }

  /// Get list of available time slots (08:00 - 18:00, 30-min intervals)
  static List<String> getTimeSlots() {
    final slots = <String>[];
    for (int hour = AppConstants.workStartHour; hour < AppConstants.workEndHour; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      slots.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return slots;
  }

  /// Get end time slot for a given start time
  static String getEndSlot(String startSlot) {
    final time = parseTime(startSlot);
    if (time == null) return startSlot;
    
    final endTime = time.add(Duration(minutes: AppConstants.slotDurationMinutes));
    return formatTime(endTime);
  }

  /// Check if a date is today or in the future
  static bool isDateValid(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.isAtSameMomentAs(todayOnly) || dateOnly.isAfter(todayOnly);
  }
}

