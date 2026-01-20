import '../../core/config/api_config.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../requests/auth_requests.dart';

/// Auth Repository
///
/// Handles all authentication-related API calls and local storage operations.
class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepository({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService.instance,
        _storageService = storageService ?? StorageService.instance;

  /// Register a new user
  /// Returns User and saves auth token
  Future<User> register(RegisterRequest request) async {
    final response = await _apiService.post(
      ApiConfig.register,
      body: request.toJson(),
      requiresAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    final tokenType = data['token_type'] as String? ?? 'Bearer';

    // Save auth data
    await _storageService.saveAuthData(
      token: token,
      tokenType: tokenType,
      userData: data['user'] as Map<String, dynamic>,
    );

    return user;
  }

  /// Login user
  /// Returns User and saves auth token
  Future<User> login(LoginRequest request) async {
    final response = await _apiService.post(
      ApiConfig.login,
      body: request.toJson(),
      requiresAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    final tokenType = data['token_type'] as String? ?? 'Bearer';

    // Save auth data
    await _storageService.saveAuthData(
      token: token,
      tokenType: tokenType,
      userData: data['user'] as Map<String, dynamic>,
    );

    return user;
  }

  /// Verify OTP
  Future<bool> verifyOtp(OtpVerifyRequest request) async {
    final response = await _apiService.post(
      ApiConfig.verifyOtp,
      body: request.toJson(),
      requiresAuth: false,
    );

    return response['success'] == true;
  }

  /// Resend OTP
  Future<bool> resendOtp(ResendOtpRequest request) async {
    final response = await _apiService.post(
      ApiConfig.resendOtp,
      body: request.toJson(),
      requiresAuth: false,
    );

    return response['success'] == true;
  }

  /// Forgot password - sends reset link/token
  Future<bool> forgotPassword(ForgotPasswordRequest request) async {
    final response = await _apiService.post(
      ApiConfig.forgotPassword,
      body: request.toJson(),
      requiresAuth: false,
    );

    return response['success'] == true;
  }

  /// Reset password with token
  Future<bool> resetPassword(ResetPasswordRequest request) async {
    final response = await _apiService.post(
      ApiConfig.resetPassword,
      body: request.toJson(),
      requiresAuth: false,
    );

    return response['success'] == true;
  }

  /// Get current user profile
  Future<User> getProfile() async {
    final response = await _apiService.get(ApiConfig.profile);

    final data = response['data'] as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    // Update stored user data
    await _storageService.setUserData(data['user'] as Map<String, dynamic>);

    return user;
  }

  /// Update user profile
  Future<User> updateProfile(UpdateProfileRequest request) async {
    final response = await _apiService.put(
      ApiConfig.profile,
      body: request.toJson(),
    );

    final data = response['data'] as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    // Update stored user data
    await _storageService.setUserData(data['user'] as Map<String, dynamic>);

    return user;
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _apiService.post(ApiConfig.logout);
    } catch (_) {
      // Ignore API errors on logout
    }

    // Clear local auth data
    await _storageService.clearAuthData();
  }

  /// Check if user is logged in (from local storage)
  bool get isLoggedIn => _storageService.isLoggedIn;

  /// Get stored auth token
  String? get authToken => _storageService.authToken;

  /// Get stored user data
  User? get storedUser {
    final userData = _storageService.userData;
    if (userData == null) return null;
    return User.fromJson(userData);
  }

  /// Check if token is valid by calling profile endpoint
  Future<bool> validateToken() async {
    if (!isLoggedIn || authToken == null) return false;

    try {
      await getProfile();
      return true;
    } on ApiException catch (e) {
      if (e.isAuthError) {
        await _storageService.clearAuthData();
        return false;
      }
      rethrow;
    }
  }
}
