import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../features/bookings/data/models/booking_model.dart';

class WashTypeUtils {
  WashTypeUtils._();

  static Color color(WashType type) {
    switch (type) {
      case WashType.interior:
        return AppColors.washInterior;
      case WashType.exterior:
        return AppColors.washExterior;
      case WashType.all:
        return AppColors.washComplete;
    }
  }

  static IconData icon(WashType type) {
    switch (type) {
      case WashType.interior:
        return AppIcons.washInterior;
      case WashType.exterior:
        return AppIcons.washExterior;
      case WashType.all:
        return AppIcons.washAll;
    }
  }

  static String label(WashType type) {
    switch (type) {
      case WashType.interior:
        return 'Interior';
      case WashType.exterior:
        return 'Exterior';
      case WashType.all:
        return 'Interior + Exterior';
    }
  }

  static String fullLabel(WashType type) {
    switch (type) {
      case WashType.interior:
        return 'Spălare Interior';
      case WashType.exterior:
        return 'Spălare Exterior';
      case WashType.all:
        return 'Spălare Interior + Exterior';
    }
  }

  static List<String> details(WashType type) {
    switch (type) {
      case WashType.interior:
        return [
          'Aspirare completă (scaune, podea, portbagaj)',
          'Curățare bord, consolă și panouri uși',
          'Curățare geamuri interior',
          'Parfumare interior',
        ];
      case WashType.exterior:
        return [
          'Spălare cu apă sub presiune',
          'Spălare manuală cu șampon auto',
          'Curățare jante și anvelope',
          'Uscare și luciu exterior',
        ];
      case WashType.all:
        return [
          'Include toate serviciile Interior + Exterior',
          'Tratament bord și plastic',
          'Luciu exterior și parfumare',
        ];
    }
  }

  /// Estimated duration in minutes for each wash type
  static int estimatedMinutes(WashType type) {
    switch (type) {
      case WashType.interior:
        return 45;
      case WashType.exterior:
        return 30;
      case WashType.all:
        return 75;
    }
  }

  static String estimatedDurationLabel(WashType type) {
    final minutes = estimatedMinutes(type);
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '~${h}h ${m}min' : '~${h}h';
    }
    return '~$minutes min';
  }
}
