import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_time_utils.dart';
import '../../features/bookings/data/models/booking_model.dart';
import 'status_badge.dart';
import 'wash_type_indicator.dart';
import '../utils/wash_type_utils.dart';
import '../utils/status_utils.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final String? vehiclePlate;
  final String? vehicleDescription;
  final String? companyName;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final bool compact;

  const BookingCard({
    super.key,
    required this.booking,
    this.vehiclePlate,
    this.vehicleDescription,
    this.companyName,
    this.onTap,
    this.actions,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final washColor = WashTypeUtils.color(booking.washType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: AppSpacing.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: washColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: compact ? _buildCompact(context) : _buildFull(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
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
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${booking.slotStart} - ${booking.slotEnd}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
    final statusColor = StatusUtils.color(booking.status);
    final statusIcon = StatusUtils.icon(booking.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: plate + wash type + status
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
                  if (vehiclePlate != null)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            vehiclePlate!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (vehicleDescription != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              vehicleDescription!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Text(
                      WashTypeUtils.fullLabel(booking.washType),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    WashTypeUtils.fullLabel(booking.washType),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WashTypeUtils.color(booking.washType),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    StatusUtils.label(booking.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Date and time row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                DateTimeUtils.formatDateDisplay(
                  DateTimeUtils.parseDate(booking.date) ?? DateTime.now(),
                ),
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              Container(
                width: 1,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                color: theme.colorScheme.outline,
              ),
              Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${booking.slotStart} – ${booking.slotEnd}',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Address
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                booking.addressText,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
