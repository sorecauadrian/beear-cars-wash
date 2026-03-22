import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/bookings/data/models/booking_model.dart';
import '../../../../features/bookings/presentation/providers/booking_provider.dart';
import '../../../../features/companies/presentation/providers/company_provider.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/booking_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/utils/status_utils.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final bookingsAsync = ref.watch(allBookingsProvider);
    final companiesAsync = ref.watch(allCompaniesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allBookingsProvider);
          ref.invalidate(allCompaniesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Greeting
            SliverToBoxAdapter(child: _buildGreeting(context, userAsync)),

            // Stats grid
            SliverToBoxAdapter(child: _buildStatsGrid(context, bookingsAsync, companiesAsync)),

            // Today's schedule
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: SectionHeader(
                  title: 'PROGRAMUL DE AZI',
                  trailing: 'Toate rezervările',
                  onTrailingTap: () => context.go(RouteNames.adminBookings),
                ),
              ),
            ),

            // Today's bookings
            _buildTodayBookings(context, bookingsAsync),

            // Pending actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: SectionHeader(title: 'ACȚIUNI NECESARE'),
              ),
            ),

            _buildPendingActions(context, ref, bookingsAsync),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, AsyncValue userAsync) {
    final name = userAsync.whenOrNull<String?>(data: (user) => user?.name);
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Bună dimineața';
    } else if (hour < 18) {
      greeting = 'Bună ziua';
    } else {
      greeting = 'Bună seara';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting${name != null ? ', $name' : ''}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DateTimeUtils.formatDateDisplay(DateTime.now()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AsyncValue<List<BookingModel>> bookingsAsync,
    AsyncValue companiesAsync,
  ) {
    return bookingsAsync.when(
      data: (bookings) {
        final today = DateTimeUtils.formatDate(DateTime.now());
        final todayBookings = bookings.where((b) => b.date == today).toList();
        final pending = bookings.where((b) => b.status == BookingStatus.accepted).length;
        final inProgressCount = bookings.where((b) => b.status == BookingStatus.inProgress).length;
        final totalCompanies = companiesAsync.whenOrNull<int>(data: (c) => c.length) ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.today_rounded,
                      label: 'Azi',
                      value: '${todayBookings.length}',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StatCard(
                      icon: Icons.schedule_rounded,
                      label: 'De făcut',
                      value: '$pending',
                      color: AppColors.statusAccepted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'În progres',
                      value: '$inProgressCount',
                      color: AppColors.statusInProgress,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StatCard(
                      icon: Icons.business_outlined,
                      label: 'Clienți',
                      value: '$totalCompanies',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: SkeletonLoader(height: 100, borderRadius: AppSpacing.radiusLg)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonLoader(height: 100, borderRadius: AppSpacing.radiusLg)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: SkeletonLoader(height: 100, borderRadius: AppSpacing.radiusLg)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonLoader(height: 100, borderRadius: AppSpacing.radiusLg)),
            ]),
          ],
        ),
      ),
      error: (error, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.08),
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 20, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nu s-au putut încărca statisticile',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayBookings(BuildContext context, AsyncValue<List<BookingModel>> bookingsAsync) {
    return bookingsAsync.when(
      data: (bookings) {
        final today = DateTimeUtils.formatDate(DateTime.now());
        final todayBookings = bookings
            .where((b) => b.date == today && b.status != BookingStatus.rejected && b.status != BookingStatus.cancelled)
            .toList()
          ..sort((a, b) => a.slotStart.compareTo(b.slotStart));

        if (todayBookings.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available_rounded, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Nicio rezervare pentru azi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => BookingCard(booking: todayBookings[index], compact: true),
            childCount: todayBookings.length > 5 ? 5 : todayBookings.length,
          ),
        );
      },
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const SkeletonCard(),
          childCount: 3,
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.08),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 20, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Nu s-au putut încărca rezervările',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingActions(BuildContext context, WidgetRef ref, AsyncValue<List<BookingModel>> bookingsAsync) {
    return bookingsAsync.when(
      data: (bookings) {
        final pending = bookings
            .where((b) => b.status == BookingStatus.accepted || b.status == BookingStatus.inProgress)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (pending.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'Nicio acțiune necesară',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final booking = pending[index];
              final nextStatus = StatusUtils.availableTransitions(booking.status).isNotEmpty
                  ? StatusUtils.availableTransitions(booking.status).first
                  : null;

              return BookingCard(
                booking: booking,
                onTap: () => context.go(RouteNames.adminBookings),
                actions: nextStatus != null
                    ? [
                        TextButton.icon(
                          onPressed: () async {
                            final repository = ref.read(bookingRepositoryProvider);
                            await repository.updateBookingStatus(booking.id, nextStatus);
                          },
                          icon: Icon(StatusUtils.icon(nextStatus), size: 16),
                          label: Text(StatusUtils.label(nextStatus)),
                        ),
                      ]
                    : null,
              );
            },
            childCount: pending.length > 5 ? 5 : pending.length,
          ),
        );
      },
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const SkeletonCard(),
          childCount: 2,
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.08),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 20, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Nu s-au putut încărca acțiunile',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
