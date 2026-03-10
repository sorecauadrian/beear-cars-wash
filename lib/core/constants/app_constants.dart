/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Beear Cars Wash';
  
  // Working hours
  static const int workStartHour = 8;
  static const int workEndHour = 18;
  static const int slotDurationMinutes = 75; // 1h 15min per slot (estimated wash duration)
  
  // Booking duration estimate
  static const String bookingDurationEstimate = '~1 hour 15 minutes per car';
  
  // Date format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayTimeFormat = 'HH:mm';
}

