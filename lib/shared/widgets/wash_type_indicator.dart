import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/bookings/data/models/booking_model.dart';
import '../utils/wash_type_utils.dart';

class WashTypeIndicator extends StatelessWidget {
  final WashType washType;
  final double size;
  final bool showLabel;

  const WashTypeIndicator({
    super.key,
    required this.washType,
    this.size = 40,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = WashTypeUtils.color(washType);
    final iconData = WashTypeUtils.icon(washType);

    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(color, iconData),
          const SizedBox(width: AppSpacing.sm),
          Text(
            WashTypeUtils.label(washType),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return _buildIcon(color, iconData);
  }

  Widget _buildIcon(Color color, IconData iconData) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Icon(
        iconData,
        color: color,
        size: size * 0.55,
      ),
    );
  }
}
