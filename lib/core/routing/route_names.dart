class RouteNames {
  RouteNames._();

  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String termsAndPrivacy = '/terms-and-privacy';

  // Client shell tabs
  static const String companyHome = '/company/home';
  static const String companyBookings = '/company/bookings';
  static const String vehiclesList = '/company/vehicles';
  static const String customerSettings = '/company/settings';

  // Client sub-routes
  static const String addVehicle = '/company/vehicles/add';
  static const String editVehicle = '/company/vehicles/edit';
  static const String createBooking = '/company/bookings/create';
  static const String bookingDetails = '/company/bookings/details';

  // Admin shell tabs
  static const String adminHome = '/admin/home';
  static const String adminBookings = '/admin/bookings';
  static const String companiesList = '/admin/companies';
  static const String serviceRecordsList = '/admin/service-records';
  static const String adminMore = '/admin/more';

  // Notifications
  static const String customerNotifications = '/company/notifications';
  static const String adminNotifications = '/admin/notifications';

  // Admin sub-routes
  static const String addCompany = '/admin/companies/add';
  static const String editCompany = '/admin/companies/edit';
  static const String pricing = '/admin/pricing';
  static const String adminSettings = '/admin/settings';
  static const String addServiceRecord = '/admin/service-records/add';
  static const String editServiceRecord = '/admin/service-records/edit';

  // Legacy aliases
  static const String adminBookingsList = adminBookings;
  static const String adminBookingDetails = '/admin/bookings/details';
}
