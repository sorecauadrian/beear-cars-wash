/// Firestore collection and document paths
class FirestorePaths {
  FirestorePaths._();

  // Collections
  static const String companies = 'companies';
  static const String users = 'users';
  static const String vehicles = 'vehicles';
  static const String bookings = 'bookings';
  static const String serviceRecords = 'serviceRecords';
  static const String pricing = 'pricing';

  // Helper methods to build paths
  static String company(String companyId) => '$companies/$companyId';
  static String user(String userId) => '$users/$userId';
  static String vehicle(String vehicleId) => '$vehicles/$vehicleId';
  static String booking(String bookingId) => '$bookings/$bookingId';
  
  // Subcollections (if needed in future)
  static String companyVehicles(String companyId) => 
      '$companies/$companyId/vehicles';
  static String companyBookings(String companyId) => 
      '$companies/$companyId/bookings';
}

