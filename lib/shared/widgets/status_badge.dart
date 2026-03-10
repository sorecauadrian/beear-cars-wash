import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/bookings/data/models/booking_model.dart';
import '../utils/status_utils.dart';

enum StatusBadgeVariant { filled, outlined, dot }

class StatusBadge extends StatelessWidget {
  final BookingStatus status;
  final StatusBadgeVariant variant;

  const StatusBadge({
    super.key,
    required this.status,
    this.variant = StatusBadgeVariant.filled,
  });

  @override
  Widget build(BuildContext context) {
    final color = StatusUtils.color(status);
    final text = StatusUtils.label(status);

    switch (variant) {
      case StatusBadgeVariant.filled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppSpacing.borderRadiusFull,
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case StatusBadgeVariant.outlined:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: AppSpacing.borderRadiusFull,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case StatusBadgeVariant.dot:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }
}
