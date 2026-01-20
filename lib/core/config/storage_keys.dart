/// Storage Keys
///
/// Contains all keys used for storing data in SharedPreferences.
/// Centralizing keys prevents typos and makes maintenance easier.
class StorageKeys {
  StorageKeys._();

  // ============== Auth Keys ==============
  /// User authentication token
  static const String authToken = 'auth_token';

  /// Token type (e.g., 'Bearer')
  static const String tokenType = 'token_type';

  /// Token expiry timestamp
  static const String tokenExpiry = 'token_expiry';

  /// Refresh token (if applicable)
  static const String refreshToken = 'refresh_token';

  // ============== User Keys ==============
  /// User ID
  static const String userId = 'user_id';

  /// User name
  static const String userName = 'user_name';

  /// User email
  static const String userEmail = 'user_email';

  /// User phone
  static const String userPhone = 'user_phone';

  /// User profile image URL
  static const String userImage = 'user_image';

  /// Complete user data as JSON string
  static const String userData = 'user_data';

  // ============== App State Keys ==============
  /// Whether user has completed onboarding
  static const String onboardingComplete = 'onboarding_complete';

  /// Whether user is logged in
  static const String isLoggedIn = 'is_logged_in';

  /// Selected language code
  static const String languageCode = 'language_code';

  /// Theme mode (light/dark/system)
  static const String themeMode = 'theme_mode';

  /// Push notification enabled
  static const String pushNotificationEnabled = 'push_notification_enabled';

  // ============== Cart Keys ==============
  /// Local cart data (for offline/guest users)
  static const String localCart = 'local_cart';

  /// Last synced cart timestamp
  static const String cartSyncTimestamp = 'cart_sync_timestamp';

  // ============== Address Keys ==============
  /// Default address ID
  static const String defaultAddressId = 'default_address_id';

  /// Cached addresses as JSON string
  static const String cachedAddresses = 'cached_addresses';

  // ============== Order Keys ==============
  /// Selected order type (dine_in, takeaway, delivery)
  static const String selectedOrderType = 'selected_order_type';

  /// Selected payment method
  static const String selectedPaymentMethod = 'selected_payment_method';

  // ============== Cache Keys ==============
  /// Categories cache
  static const String categoriesCache = 'categories_cache';

  /// Categories cache timestamp
  static const String categoriesCacheTime = 'categories_cache_time';

  /// Products cache prefix (append category ID)
  static const String productsCachePrefix = 'products_cache_';

  /// Banners cache
  static const String bannersCache = 'banners_cache';

  /// Banners cache timestamp
  static const String bannersCacheTime = 'banners_cache_time';

  // ============== FCM Keys ==============
  /// Firebase Cloud Messaging token
  static const String fcmToken = 'fcm_token';

  /// Device ID for push notifications
  static const String deviceId = 'device_id';
}