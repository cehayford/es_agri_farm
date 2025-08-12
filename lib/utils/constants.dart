class AppConstants {
  // App Information
  static const String appName = 'Agri Farm';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections (simple names for your database)
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String categoriesCollection = 'categories';
  static const String cartCollection = 'cart'; // Added missing cart collection constant

  // User Roles
  static const String userRole = 'user';
  static const String adminRole = 'admin';

  // Order Status
  static const String orderPending = 'pending';
  static const String orderCompleted = 'completed';
  static const String orderCancelled = 'cancelled';
  
  // Shared Preferences Keys (for storing data locally)
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String isFirstTimeKey = 'is_first_time';

  // Images
  static const String appLogo = 'assets/images/agrilogo.jpg';
}
