import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/bookings/data/models/booking_model.dart';
import '../../../../features/bookings/presentation/providers/booking_provider.dart';
import '../../../../shared/widgets/booking_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../features/vehicles/data/repositories/vehicle_repository.dart';
import '../../../../features/vehicles/data/models/vehicle_model.dart';
import 'package:go_router/go_router.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28, withText: true),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.logout, size: 22),
            tooltip: 'Deconectare',
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
              if (context.mounted) context.go(RouteNames.login);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myBookingsProvider),
        child: CustomScrollView(
          slivers: [
            // Greeting
            SliverToBoxAdapter(
              child: _buildGreeting(context, userAsync),
            ),

            // Stats
            SliverToBoxAdapter(
              child: _buildStats(context, bookingsAsync),
            ),

            // Upcoming section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: SectionHeader(
                  title: 'REZERVĂRI ACTIVE',
                  trailing: 'Vezi toate',
                  onTrailingTap: () {},
                ),
              ),
            ),

            // Bookings list
            _buildBookingsList(context, ref, bookingsAsync),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: bookingsAsync.whenOrNull(
        data: (bookings) {
          final hasActive = bookings.any((b) =>
            b.status != BookingStatus.done &&
            b.status != BookingStatus.rejected &&
            b.status != BookingStatus.cancelled
          );
          if (!hasActive) return null;
          return FloatingActionButton.extended(
            onPressed: () => context.push(RouteNames.createBooking),
            icon: const Icon(AppIcons.newBooking),
            label: const Text('Rezervare nouă'),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, AsyncValue userAsync) {
    final name = userAsync.whenOrNull<String?>(
      data: (user) => user?.name,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bună${name != null ? ', $name' : ''}! 👋',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Gestionează rezervările tale',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, AsyncValue<List<BookingModel>> bookingsAsync) {
    return bookingsAsync.when(
      data: (bookings) {
        final active = bookings.where((b) =>
          b.status != BookingStatus.done &&
          b.status != BookingStatus.rejected &&
          b.status != BookingStatus.cancelled
        ).length;
        final completed = bookings.where((b) => b.status == BookingStatus.done).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.schedule_rounded,
                  label: 'Active',
                  value: '$active',
                  color: AppColors.statusAccepted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  icon: Icons.task_alt_rounded,
                  label: 'Finalizate',
                  value: '$completed',
                  color: AppColors.statusSuccess,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Expanded(child: SkeletonLoader(height: 100, borderRadius: AppSpacing.radiusLg)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: SkeletonLoader(height: 100, borderRadius: AppSpacing.radiusLg)),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBookingsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BookingModel>> bookingsAsync,
  ) {
    return bookingsAsync.when(
      data: (bookings) {
        final active = bookings.where((b) =>
          b.status != BookingStatus.done &&
          b.status != BookingStatus.rejected &&
          b.status != BookingStatus.cancelled
        ).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (active.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.event_available_rounded,
              title: 'Nicio rezervare activă',
              subtitle: 'Creează o rezervare nouă pentru a programa o spălare',
              actionLabel: 'Rezervare nouă',
              onAction: () => context.push(RouteNames.createBooking),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final booking = active[index];
              return _BookingCardWithVehicle(booking: booking);
            },
            childCount: active.length,
          ),
        );
      },
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: SkeletonCard(),
          ),
          childCount: 3,
        ),
      ),
      error: (error, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Eroare la încărcarea rezervărilor',
          subtitle: error.toString(),
          actionLabel: 'Încearcă din nou',
          onAction: () => ref.invalidate(myBookingsProvider),
        ),
      ),
    );
  }
}

class _BookingCardWithVehicle extends StatelessWidget {
  final BookingModel booking;

  const _BookingCardWithVehicle({required this.booking});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VehicleModel?>(
      future: _getVehicle(booking.vehicleId),
      builder: (context, snap) {
        return BookingCard(
          booking: booking,
          vehiclePlate: snap.data?.plateNumber,
        );
      },
    );
  }

  Future<VehicleModel?> _getVehicle(String id) async {
    try {
      return await VehicleRepository().getVehicleById(id);
    } catch (_) {
      return null;
    }
  }
}
