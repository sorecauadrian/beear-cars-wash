import 'package:flutter/material.dart';

/// Centralized, intuitive icons for the app
/// Use these instead of scattered Icons.* for consistency
class AppIcons {
  AppIcons._();

  // Navigation & main actions
  static const IconData bookings = Icons.calendar_month;
  static const IconData newBooking = Icons.add_circle_outline;
  static const IconData vehicles = Icons.directions_car_outlined;
  static const IconData addVehicle = Icons.add;
  static const IconData companies = Icons.business_outlined;
  static const IconData addCompany = Icons.add_business_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData logout = Icons.logout;
  static const IconData filter = Icons.filter_list;
  static const IconData pricing = Icons.attach_money;
  static const IconData serviceRecords = Icons.description_outlined;

  // Form & input
  static const IconData email = Icons.mail_outlined;
  static const IconData password = Icons.lock_outlined;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;
  static const IconData person = Icons.person_outline;
  static const IconData location = Icons.location_on_outlined;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData time = Icons.access_time;
  static const IconData note = Icons.note_outlined;
  static const IconData plateNumber = Icons.confirmation_number_outlined;
  static const IconData description = Icons.description_outlined;

  // Wash types (intuitive for car wash)
  static const IconData washExterior = Icons.water_drop_outlined;
  static const IconData washInterior = Icons.air_outlined;
  static const IconData washTapiterie = Icons.chair_outlined;
  static const IconData washAll = Icons.cleaning_services_outlined;

  // Actions
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outlined;
  static const IconData close = Icons.close;
  static const IconData check = Icons.check_circle_outlined;
  static const IconData map = Icons.map_outlined;
  static const IconData download = Icons.download_outlined;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline;
  static const IconData info = Icons.info_outline;
}
