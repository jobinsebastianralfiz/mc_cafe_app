import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/storage_keys.dart';

/// Storage Service
///
/// Wrapper around SharedPreferences for type-safe local storage.
/// Provides convenient methods for storing and retrieving data.
class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  /// Get singleton instance
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// Initialize SharedPreferences
  /// Must be called before using any storage methods
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }

  // ============== Generic Methods ==============

  /// Get string value
  String? getString(String key) => prefs.getString(key);

  /// Set string value
  Future<bool> setString(String key, String value) => prefs.setString(key, value);

  /// Get int value
  int? getInt(String key) => prefs.getInt(key);

  /// Set int value
  Future<bool> setInt(String key, int value) => prefs.setInt(key, value);

  /// Get double value
  double? getDouble(String key) => prefs.getDouble(key);

  /// Set double value
  Future<bool> setDouble(String key, double value) => prefs.setDouble(key, value);

  /// Get bool value
  bool? getBool(String key) => prefs.getBool(key);

  /// Set bool value
  Future<bool> setBool(String key, bool value) => prefs.setBool(key, value);

  /// Get string list
  List<String>? getStringList(String key) => prefs.getStringList(key);

  /// Set string list
  Future<bool> setStringList(String key, List<String> value) =>
      prefs.setStringList(key, value);

  /// Get JSON object
  Map<String, dynamic>? getJson(String key) {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Set JSON object
  Future<bool> setJson(String key, Map<String, dynamic> value) =>
      prefs.setString(key, json.encode(value));

  /// Remove a key
  Future<bool> remove(String key) => prefs.remove(key);

  /// Check if key exists
  bool containsKey(String key) => prefs.containsKey(key);

  /// Clear all data
  Future<bool> clear() => prefs.clear();

  // ============== Auth Methods ==============

  /// Get auth token
  String? get authToken => getString(StorageKeys.authToken);

  /// Set auth token
  Future<bool> setAuthToken(String token) =>
      setString(StorageKeys.authToken, token);

  /// Get token type
  String get tokenType => getString(StorageKeys.tokenType) ?? 'Bearer';

  /// Set token type
  Future<bool> setTokenType(String type) =>
      setString(StorageKeys.tokenType, type);

  /// Get authorization header value
  String? get authorizationHeader {
    final token = authToken;
    if (token == null) return null;
    return '$tokenType $token';
  }

  /// Check if user is logged in
  bool get isLoggedIn => getBool(StorageKeys.isLoggedIn) ?? false;

  /// Set logged in status
  Future<bool> setLoggedIn(bool value) =>
      setBool(StorageKeys.isLoggedIn, value);

  /// Save auth data after login
  Future<void> saveAuthData({
    required String token,
    String tokenType = 'Bearer',
    Map<String, dynamic>? userData,
  }) async {
    await Future.wait([
      setAuthToken(token),
      setTokenType(tokenType),
      setLoggedIn(true),
      if (userData != null) setUserData(userData),
    ]);
  }

  /// Clear auth data on logout
  Future<void> clearAuthData() async {
    await Future.wait([
      remove(StorageKeys.authToken),
      remove(StorageKeys.tokenType),
      remove(StorageKeys.tokenExpiry),
      remove(StorageKeys.refreshToken),
      remove(StorageKeys.userId),
      remove(StorageKeys.userName),
      remove(StorageKeys.userEmail),
      remove(StorageKeys.userPhone),
      remove(StorageKeys.userImage),
      remove(StorageKeys.userData),
      setBool(StorageKeys.isLoggedIn, false),
    ]);
  }

  // ============== User Methods ==============

  /// Get user ID
  int? get userId => getInt(StorageKeys.userId);

  /// Set user ID
  Future<bool> setUserId(int id) => setInt(StorageKeys.userId, id);

  /// Get user name
  String? get userName => getString(StorageKeys.userName);

  /// Set user name
  Future<bool> setUserName(String name) =>
      setString(StorageKeys.userName, name);

  /// Get user email
  String? get userEmail => getString(StorageKeys.userEmail);

  /// Set user email
  Future<bool> setUserEmail(String email) =>
      setString(StorageKeys.userEmail, email);

  /// Get user phone
  String? get userPhone => getString(StorageKeys.userPhone);

  /// Set user phone
  Future<bool> setUserPhone(String phone) =>
      setString(StorageKeys.userPhone, phone);

  /// Get user image URL
  String? get userImage => getString(StorageKeys.userImage);

  /// Set user image URL
  Future<bool> setUserImage(String url) =>
      setString(StorageKeys.userImage, url);

  /// Get complete user data
  Map<String, dynamic>? get userData => getJson(StorageKeys.userData);

  /// Set complete user data
  Future<bool> setUserData(Map<String, dynamic> data) =>
      setJson(StorageKeys.userData, data);

  // ============== App State Methods ==============

  /// Check if onboarding is complete
  bool get isOnboardingComplete =>
      getBool(StorageKeys.onboardingComplete) ?? false;

  /// Set onboarding complete
  Future<bool> setOnboardingComplete(bool value) =>
      setBool(StorageKeys.onboardingComplete, value);

  /// Get selected language code
  String get languageCode => getString(StorageKeys.languageCode) ?? 'en';

  /// Set language code
  Future<bool> setLanguageCode(String code) =>
      setString(StorageKeys.languageCode, code);

  /// Get theme mode
  String get themeMode => getString(StorageKeys.themeMode) ?? 'system';

  /// Set theme mode
  Future<bool> setThemeMode(String mode) =>
      setString(StorageKeys.themeMode, mode);

  // ============== Order Preferences ==============

  /// Get selected order type
  String? get selectedOrderType => getString(StorageKeys.selectedOrderType);

  /// Set selected order type
  Future<bool> setSelectedOrderType(String type) =>
      setString(StorageKeys.selectedOrderType, type);

  /// Get selected payment method
  String? get selectedPaymentMethod =>
      getString(StorageKeys.selectedPaymentMethod);

  /// Set selected payment method
  Future<bool> setSelectedPaymentMethod(String method) =>
      setString(StorageKeys.selectedPaymentMethod, method);

  /// Get default address ID
  int? get defaultAddressId => getInt(StorageKeys.defaultAddressId);

  /// Set default address ID
  Future<bool> setDefaultAddressId(int id) =>
      setInt(StorageKeys.defaultAddressId, id);

  // ============== Cache Methods ==============

  /// Check if cache is valid based on timestamp
  bool isCacheValid(String timestampKey, int maxAgeHours) {
    final timestamp = getInt(timestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime).inHours < maxAgeHours;
  }

  /// Set cache timestamp to now
  Future<bool> setCacheTimestamp(String key) =>
      setInt(key, DateTime.now().millisecondsSinceEpoch);

  /// Clear specific cache
  Future<void> clearCache(String dataKey, String timestampKey) async {
    await Future.wait([
      remove(dataKey),
      remove(timestampKey),
    ]);
  }
}