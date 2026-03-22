import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 40,
    this.width,
    this.withText = false,
    this.isWhite,
  });

  final double height;
  final double? width;
  final bool withText;
  /// If null, auto-detects from current brightness (dark mode = white logo).
  final bool? isWhite;

  @override
  Widget build(BuildContext context) {
    final useWhite = isWhite ?? (Theme.of(context).brightness == Brightness.dark);

    String logoPath;
    if (withText) {
      logoPath = useWhite
          ? 'assets/images/beear-cars-wash-white.png'
          : 'assets/images/beear-cars-wash.png';
    } else {
      logoPath = useWhite
          ? 'assets/images/beear-cars-wash-no-text-white.png'
          : 'assets/images/beear-cars-wash-no-text.png';
    }

    return Semantics(
      label: 'Beear Cars Wash',
      image: true,
      child: Image.asset(
        logoPath,
        height: height,
        width: width ?? height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.local_car_wash,
            size: height,
            color: Theme.of(context).colorScheme.onPrimary,
          );
        },
      ),
    );
  }
}
