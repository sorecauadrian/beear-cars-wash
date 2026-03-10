import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utilities for opening maps and navigation
class MapUtils {
  MapUtils._();

  /// Open address in Google Maps (navigates to location).
  /// Uses coordinates if available, tries to geocode the address text as
  /// fallback, and finally passes the raw text to Google Maps.
  static Future<bool> openInMaps({
    required String addressText,
    double? lat,
    double? lng,
  }) async {
    final coords = await _resolveCoordinates(addressText, lat, lng);
    final Uri uri;
    if (coords != null) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${coords.$1},${coords.$2}');
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addressText)}');
    }
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Launch phone dialer to call the given number
  static Future<bool> launchPhone(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return false;
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Open Google Maps directions from current location to address.
  /// Tries coordinates first, geocodes as fallback, then raw text.
  static Future<bool> openDirections({
    required String addressText,
    double? lat,
    double? lng,
  }) async {
    final coords = await _resolveCoordinates(addressText, lat, lng);
    final destination = coords != null
        ? '${coords.$1},${coords.$2}'
        : Uri.encodeComponent(addressText);
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Returns (lat, lng) from the provided coordinates, or by geocoding
  /// the address text. Returns null if neither approach works.
  static Future<(double, double)?> _resolveCoordinates(
    String addressText,
    double? lat,
    double? lng,
  ) async {
    if (lat != null && lng != null) return (lat, lng);

    if (addressText.trim().isEmpty) return null;

    try {
      final locations = await locationFromAddress(addressText);
      if (locations.isNotEmpty) {
        return (locations.first.latitude, locations.first.longitude);
      }
    } catch (_) {
      // Geocoding failed — will fall back to raw text
    }
    return null;
  }
}
