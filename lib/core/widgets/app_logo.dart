import 'package:flutter/material.dart';

/// App logo widget - reusable logo display
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 40,
    this.width,
  });

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
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

