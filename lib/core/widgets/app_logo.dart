import 'package:flutter/material.dart';

/// App logo widget - reusable logo display
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 40,
    this.width,
    this.withText = false, // Default to no text for headers
    this.isWhite = false,
  });

  final double height;
  final double? width;
  final bool withText;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    // Determine which logo variant to use
    String logoPath;
    if (withText) {
      logoPath = isWhite
          ? 'assets/images/beear-cars-wash-white.png'
          : 'assets/images/beear-cars-wash.png';
    } else {
      logoPath = isWhite
          ? 'assets/images/beear-cars-wash-no-text-white.png'
          : 'assets/images/beear-cars-wash-no-text.png';
    }

    return Image.asset(
      logoPath,
      height: height,
      width: width ?? height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if logo not found
        return Icon(
          Icons.local_car_wash,
          size: height,
          color: Theme.of(context).colorScheme.onPrimary,
        );
      },
    );
  }
}

