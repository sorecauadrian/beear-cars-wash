import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_time_utils.dart';
import '../../features/bookings/data/models/booking_model.dart';
import 'status_badge.dart';
import 'wash_type_indicator.dart';
import '../utils/wash_type_utils.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final String? vehiclePlate;
  final String? companyName;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final bool compact;

  const BookingCard({
    super.key,
    required this.booking,
    this.vehiclePlate,
    this.companyName,
    this.onTap,
    this.actions,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.outline),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: compact ? _buildCompact(context) : _buildFull(context),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Row(
      children: [
        WashTypeIndicator(washType: booking.washType, size: 36),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehiclePlate ?? WashTypeUtils.fullLabel(booking.washType),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${booking.slotStart} - ${booking.slotEnd}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        StatusBadge(status: booking.status, variant: StatusBadgeVariant.outlined),
      ],
    );
  }

  Widget _buildFull(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WashTypeIndicator(washType: booking.washType),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (companyName != null)
                    Text(
                      companyName!,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  Text(
                    vehiclePlate ?? WashTypeUtils.fullLabel(booking.washType),
                    style: companyName != null
                        ? theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)
                        : theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            StatusBadge(status: booking.status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                DateTimeUtils.formatDateDisplay(
                  DateTimeUtils.parseDate(booking.date) ?? DateTime.now(),
                ),
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.access_time_rounded, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${booking.slotStart} – ${booking.slotEnd}',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: AppColors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                booking.addressText,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions!,
          ),
        ],
      ],
    );
  }
}
