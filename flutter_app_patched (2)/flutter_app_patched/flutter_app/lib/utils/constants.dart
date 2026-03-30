class AppConstants {
  // 🌐 BASE URL CONFIG — Use Render backend
  static const String baseUrl = 'https://onecampus-backend.onrender.com';

  // 🔗 API BASE
  static const String apiBase = '$baseUrl/api';

  // 🔐 AUTH
  static const String loginUrl = '$apiBase/auth/login';
  static const String registerUrl = '$apiBase/auth/register';
  static const String profileUrl = '$apiBase/auth/profile';
  static const String updateProfileUrl = '$apiBase/auth/profile';

  // 🚌 TRACKING
  static const String trackingLocationUrl = '$apiBase/tracking/location';
  static const String trackingBusesUrl = '$apiBase/tracking/buses';
  static const String trackingSchedulesUrl = '$apiBase/tracking/schedules';

  // 🍔 CANTEEN
  static const String canteenAddItemUrl = '$apiBase/canteen/add-item';
  static const String canteenTodayItemsUrl = '$apiBase/canteen/today-items';
  static const String canteenOrderUrl = '$apiBase/canteen/order';
  static const String canteenOrdersUrl = '$apiBase/canteen/orders';
  static const String canteenAllOrdersUrl = '$apiBase/canteen/all-orders';

  // 🛒 MARKETPLACE
  static const String marketplaceAddUrl = '$apiBase/marketplace/add-product';
  static const String marketplaceProductsUrl = '$apiBase/marketplace/products';
  static const String marketplaceMyProductsUrl = '$apiBase/marketplace/my-products';
  static const String marketplaceMarkSoldUrl = '$apiBase/marketplace/mark-sold';
  static const String marketplaceDeleteUrl = '$apiBase/marketplace/products';
  static const String marketplaceUpdateUrl = '$apiBase/marketplace/products';

  // 📚 MATERIALS
  static const String materialsUrl = '$apiBase/materials';

  // 📢 ANNOUNCEMENTS
  static const String announcementsUrl = '$apiBase/announcements';

  // 🔥 FIREBASE
  static const String rtdbLocationsPath = 'locations';

  // 🚌 BUS SETTINGS
  static const int busOfflineThresholdSeconds = 30;

  // 🎨 UI
  static const int primaryColorValue = 0xFF1A73E8;
  static const int accentColorValue = 0xFF34A853;

  // ⏱️ TIMEOUT
  static const Duration requestTimeout = Duration(seconds: 15);
}