import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../../../../shared/widgets/booking_card_with_vehicle.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/skeleton_loader.dart';

class CustomerBookingsListScreen extends ConsumerStatefulWidget {
  const CustomerBookingsListScreen({super.key});

  @override
  ConsumerState<CustomerBookingsListScreen> createState() => _CustomerBookingsListScreenState();
}

class _CustomerBookingsListScreenState extends ConsumerState<CustomerBookingsListScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              Text(
                'Arată finalizate',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const Spacer(),
              Switch(value: _showCompleted, onChanged: (v) => setState(() => _showCompleted = v)),
            ],
          ),
        ),
        Expanded(
          child: bookingsAsync.when(
            data: (bookings) {
              var filtered = bookings.toList();
              if (!_showCompleted) {
                filtered = filtered.where((b) => b.status != BookingStatus.done).toList();
              }
              filtered.sort((a, b) => a.date.compareTo(b.date));

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'Nu există rezervări',
                  subtitle: _showCompleted ? null : 'Activează "Arată finalizate" pentru a vedea toate',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(myBookingsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final booking = filtered[index];
                    return BookingCardWithVehicle(booking: booking);
                  },
                ),
              );
            },
            loading: () => ListView(
              children: List.generate(3, (_) => const SkeletonCard()),
            ),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Eroare',
              subtitle: '$error',
              actionLabel: 'Încearcă din nou',
              onAction: () => ref.invalidate(myBookingsProvider),
            ),
          ),
        ),
      ],
    );
  }
}

