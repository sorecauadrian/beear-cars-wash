import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../features/bookings/data/models/booking_model.dart';
import '../../../../features/bookings/presentation/providers/booking_provider.dart';
import '../../../../shared/widgets/booking_card_with_vehicle.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import 'package:go_router/go_router.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  late DateTime _displayedMonth;
  DateTime? _selectedDay;

  static const _monthNames = [
    '', 'Ianuarie', 'Februarie', 'Martie', 'Aprilie', 'Mai', 'Iunie',
    'Iulie', 'August', 'Septembrie', 'Octombrie', 'Noiembrie', 'Decembrie',
  ];
  static const _dayNames = ['Lu', 'Ma', 'Mi', 'Jo', 'Vi', 'Sâ', 'Du'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  List<DateTime?> _buildCalendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startOffset = firstDay.weekday - 1; // Mon=0, Sun=6
    final days = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) {
      days.add(null);
    }
    for (int d = 1; d <= lastDay.day; d++) {
      days.add(DateTime(month.year, month.month, d));
    }
    while (days.length % 7 != 0) {
      days.add(null);
    }
    return days;
  }

  Set<String> _bookedDates(List<BookingModel> bookings) =>
      bookings.map((b) => b.date).toSet();

  List<BookingModel> _bookingsForDay(List<BookingModel> bookings, DateTime day) {
    final key = DateTimeUtils.formatDate(day);
    return bookings.where((b) => b.date == key).toList()
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
  }

  void _previousMonth() => setState(() {
        _displayedMonth =
            DateTime(_displayedMonth.year, _displayedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _displayedMonth =
            DateTime(_displayedMonth.year, _displayedMonth.month + 1);
      });

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28, withText: true),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 24),
            tooltip: 'Notificări',
            onPressed: () => context.push(RouteNames.customerNotifications),
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          final dates = _bookedDates(bookings);
          final dayBookings = _selectedDay != null
              ? _bookingsForDay(bookings, _selectedDay!)
              : <BookingModel>[];

          return Column(
            children: [
              _buildCalendar(context, dates),
              Divider(
                  height: 1,
                  color:
                      Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
              Expanded(child: _buildDayList(context, dayBookings)),
            ],
          );
        },
        loading: () => ListView(
          children: [
            _buildCalendarSkeleton(context),
            ...List.generate(3, (_) => const SkeletonCard()),
          ],
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Eroare la încărcarea rezervărilor',
          subtitle: error.toString(),
          actionLabel: 'Încearcă din nou',
          onAction: () => ref.invalidate(myBookingsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final sel = _selectedDay;
          if (sel != null && !sel.isBefore(today)) {
            context.push(
                '${RouteNames.createBooking}?date=${DateTimeUtils.formatDate(sel)}');
          } else {
            context.push(RouteNames.createBooking);
          }
        },
        tooltip: 'Rezervare nouă',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, Set<String> bookedDates) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final calDays = _buildCalendarDays(_displayedMonth);
    final monthLabel =
        '${_monthNames[_displayedMonth.month]} ${_displayedMonth.year}';

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _previousMonth,
              ),
              Text(
                monthLabel,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _nextMonth,
              ),
            ],
          ),
          // Day name headers
          Row(
            children: _dayNames.map((name) {
              return Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Calendar grid
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: calDays.map((day) {
              if (day == null) return const SizedBox.shrink();

              final dateKey = DateTimeUtils.formatDate(day);
              final hasBooking = bookedDates.contains(dateKey);
              final isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final isSelected = _selectedDay != null &&
                  day.year == _selectedDay!.year &&
                  day.month == _selectedDay!.month &&
                  day.day == _selectedDay!.day;
              final isPast = day.isBefore(
                  DateTime(today.year, today.month, today.day));

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedDay = isSelected ? null : day;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.12)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? theme.colorScheme.primary
                                    : isPast
                                        ? theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.45)
                                        : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hasBooking)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 5),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayList(BuildContext context, List<BookingModel> dayBookings) {
    final theme = Theme.of(context);

    if (_selectedDay == null) {
      return _compactEmpty(
        context,
        Icons.calendar_today_rounded,
        'Selectează o zi din calendar',
      );
    }

    final d = _selectedDay!;
    final dayLabel = '${d.day} ${_monthNames[d.month]} ${d.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
          child: Text(
            dayLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: dayBookings.isEmpty
              ? _compactEmpty(
                  context,
                  Icons.event_available_rounded,
                  'Nicio rezervare în această zi',
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myBookingsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    itemCount: dayBookings.length,
                    itemBuilder: (context, index) {
                      return BookingCardWithVehicle(booking: dayBookings[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _compactEmpty(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSkeleton(BuildContext context) {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
    );
  }
}
