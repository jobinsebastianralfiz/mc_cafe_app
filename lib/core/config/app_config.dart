/// App Configuration
///
/// Contains app-wide configuration constants that are not API-related.
/// These values are used throughout the app for consistent behavior.
class AppConfig {
  AppConfig._();

  // ============== App Info ==============
  /// Application name
  static const String appName = 'MC Cafe';

  /// Application tagline
  static const String appTagline = 'A Taste Worth Savouring';

  /// Current app version (update with each release)
  static const String appVersion = '1.0.0';

  /// Build number
  static const int buildNumber = 1;

  // ============== Pagination ==============
  /// Default number of items per page
  static const int defaultPageSize = 10;

  /// Maximum items per page
  static const int maxPageSize = 50;

  // ============== Cache Duration ==============
  /// Categories cache duration in hours
  static const int categoriesCacheDuration = 24;

  /// Products cache duration in hours
  static const int productsCacheDuration = 1;

  /// Banners cache duration in hours
  static const int bannersCacheDuration = 6;

  // ============== Timeouts ==============
  /// API request timeout in seconds
  static const int apiTimeoutSeconds = 30;

  /// Image load timeout in seconds
  static const int imageTimeoutSeconds = 15;

  // ============== OTP Configuration ==============
  /// OTP length
  static const int otpLength = 4;

  /// OTP resend cooldown in seconds
  static const int otpResendCooldown = 60;

  /// OTP expiry time in minutes
  static const int otpExpiryMinutes = 10;

  // ============== Validation ==============
  /// Minimum password length
  static const int minPasswordLength = 6;

  /// Maximum password length
  static const int maxPasswordLength = 32;

  /// Minimum name length
  static const int minNameLength = 2;

  /// Maximum name length
  static const int maxNameLength = 50;

  /// Phone number length
  static const int phoneLength = 10;

  // ============== Cart ==============
  /// Minimum order amount
  static const double minOrderAmount = 0.0;

  /// Maximum cart items
  static const int maxCartItems = 50;

  /// Maximum quantity per item
  static const int maxItemQuantity = 10;

  // ============== Currency ==============
  /// Currency symbol
  static const String currencySymbol = '₹';

  /// Currency code
  static const String currencyCode = 'INR';

  /// Decimal places for currency
  static const int currencyDecimalPlaces = 2;

  // ============== Date Formats ==============
  /// Display date format
  static const String displayDateFormat = 'dd MMM yyyy';

  /// Display time format
  static const String displayTimeFormat = 'hh:mm a';

  /// Display date time format
  static const String displayDateTimeFormat = 'dd MMM yyyy, hh:mm a';

  /// API date format
  static const String apiDateFormat = 'yyyy-MM-dd';

  /// API date time format
  static const String apiDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // ============== Image Sizes ==============
  /// Thumbnail size
  static const int thumbnailSize = 100;

  /// Medium image size
  static const int mediumImageSize = 300;

  /// Large image size
  static const int largeImageSize = 600;

  // ============== Animation Durations ==============
  /// Short animation duration in milliseconds
  static const int shortAnimationMs = 200;

  /// Medium animation duration in milliseconds
  static const int mediumAnimationMs = 300;

  /// Long animation duration in milliseconds
  static const int longAnimationMs = 500;

  // ============== Support ==============
  /// Support email
  static const String supportEmail = 'support@mccafe.com';

  /// Support phone
  static const String supportPhone = '+91 XXXXXXXXXX';

  /// Privacy policy URL
  static const String privacyPolicyUrl = 'https://mccafe.com/privacy';

  /// Terms and conditions URL
  static const String termsUrl = 'https://mccafe.com/terms';
}