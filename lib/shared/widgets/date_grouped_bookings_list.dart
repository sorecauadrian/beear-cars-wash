import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../features/bookings/data/models/booking_model.dart';
import '../../../core/utils/date_time_utils.dart';

/// Widget that groups bookings by date and displays them with date headers
class DateGroupedBookingsList extends StatelessWidget {
  final List<BookingModel> bookings;
  final Widget Function(BuildContext, BookingModel) itemBuilder;
  final Widget Function()? emptyBuilder;

  const DateGroupedBookingsList({
    super.key,
    required this.bookings,
    required this.itemBuilder,
    this.emptyBuilder,
  });

  Map<String, List<BookingModel>> groupBookingsByDate(List<BookingModel> bookings) {
    final grouped = <String, List<BookingModel>>{};
    
    for (final booking in bookings) {
      final dateKey = booking.date;
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(booking);
    }
    
    // Sort bookings within each date by time
    for (final dateKey in grouped.keys) {
      grouped[dateKey]!.sort((a, b) => a.slotStart.compareTo(b.slotStart));
    }
    
    return grouped;
  }

  String _formatDateHeader(String dateString) {
    final date = DateTimeUtils.parseDate(dateString);
    if (date == null) return dateString;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Day name in Romanian
    String dayName;
    switch (date.weekday) {
      case 1:
        dayName = 'Luni';
        break;
      case 2:
        dayName = 'Marți';
        break;
      case 3:
        dayName = 'Miercuri';
        break;
      case 4:
        dayName = 'Joi';
        break;
      case 5:
        dayName = 'Vineri';
        break;
      case 6:
        dayName = 'Sâmbătă';
        break;
      case 7:
        dayName = 'Duminică';
        break;
      default:
        dayName = '';
    }
    
    if (dateOnly == today) {
      return 'Astăzi - $dayName, ${DateFormat('dd.MM.yyyy').format(date)}';
    } else if (dateOnly == tomorrow) {
      return 'Mâine - $dayName, ${DateFormat('dd.MM.yyyy').format(date)}';
    } else {
      return '$dayName, ${DateFormat('dd.MM.yyyy').format(date)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return emptyBuilder?.call() ?? const SizedBox.shrink();
    }

    final grouped = groupBookingsByDate(bookings);
    
    // Sort dates chronologically
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) {
        final dateA = DateTimeUtils.parseDate(a);
        final dateB = DateTimeUtils.parseDate(b);
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dateBookings = grouped[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateHeader(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${dateBookings.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bookings for this date
            ...dateBookings.map((booking) => itemBuilder(context, booking)),
            if (index < sortedDates.length - 1)
              const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

