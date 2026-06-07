import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/enums/app_enums.dart';
import '../core/exceptions/api_exception.dart';
import '../core/services/notification_service.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/requests/auth_requests.dart';

/// Auth Provider
///
/// Manages authentication state using ChangeNotifier for Provider.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  /// Set to true to bypass API calls (for testing when backend is not ready)
  static const bool _mockMode = false;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  // ============== State ==============

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isGuest = false;

  // ============== Getters ==============

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;
  bool get isPendingVerification => _status == AuthStatus.pendingVerification;

  /// True when the user chose "Browse as Guest" and is not authenticated.
  /// Account-based actions (cart, checkout, wishlist, orders, profile) should
  /// prompt for login when this is true.
  bool get isGuest => _isGuest && !isAuthenticated;

  /// Enter guest browsing mode (called from the splash "Browse as Guest" CTA).
  void continueAsGuest() {
    _isGuest = true;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ============== Initialization ==============

  /// Initialize auth state from stored data
  Future<void> init() async {
    _setLoading(true);

    try {
      // Check if user is logged in locally
      if (_repository.isLoggedIn) {
        // Try to load stored user
        _user = _repository.storedUser;

        if (_mockMode) {
          // In mock mode, trust local storage
          _status = AuthStatus.authenticated;
        } else {
          // Validate token with server
          final isValid = await _repository.validateToken();
          if (isValid) {
            _user = _repository.storedUser;
            _status = AuthStatus.authenticated;
            // Refresh FCM token registration on app start.
            unawaited(NotificationService.instance.registerFcmToken());
          } else {
            _status = AuthStatus.unauthenticated;
            _user = null;
          }
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    }

    _setLoading(false);
  }

  // ============== Auth Methods ==============

  /// Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (_mockMode) {
        // Mock registration - create a temporary user
        await Future.delayed(const Duration(milliseconds: 500));
        _user = User(
          id: 1,
          name: name,
          email: email,
          phone: phone,
          role: 'customer',
          loyaltyPoints: 0,
        );
        _status = AuthStatus.pendingVerification;
        _setLoading(false);
        return true;
      }

      final request = RegisterRequest(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );

      _user = await _repository.register(request);

      // After registration, user needs to verify OTP
      _status = AuthStatus.pendingVerification;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Registration failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Login user
  /// After login, OTP is sent to user's email for verification
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (_mockMode) {
        // Mock login - accept any credentials
        await Future.delayed(const Duration(milliseconds: 500));
        _user = User(
          id: 1,
          name: 'Test User',
          email: email,
          role: 'customer',
          loyaltyPoints: 100,
        );
        _status = AuthStatus.pendingVerification;
        _setLoading(false);
        return true;
      }

      final request = LoginRequest(
        email: email,
        password: password,
      );

      _user = await _repository.login(request);

      // Check if token was saved (user already verified) or OTP needed
      if (_repository.isLoggedIn) {
        _status = AuthStatus.authenticated;
        unawaited(NotificationService.instance.registerFcmToken());
      } else {
        _status = AuthStatus.pendingVerification;
      }
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Login failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (_mockMode) {
        // Mock OTP verification - accept any 4-digit OTP
        await Future.delayed(const Duration(milliseconds: 500));
        if (otp.length == 6) {
          _status = AuthStatus.authenticated;
          _setLoading(false);
          return true;
        } else {
          _setError('Please enter a 6-digit OTP');
          _setLoading(false);
          return false;
        }
      }

      final request = OtpVerifyRequest(
        email: email,
        otp: otp,
      );

      final success = await _repository.verifyOtp(request);
      if (success) {
        // Load user from stored data (saved during verifyOtp if token returned)
        _user = _repository.storedUser ?? _user;
        _status = AuthStatus.authenticated;
        unawaited(NotificationService.instance.registerFcmToken());
      }
      _setLoading(false);
      return success;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('OTP verification failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Resend OTP
  Future<bool> resendOtp({required String email, String type = 'registration'}) async {
    _setLoading(true);
    _clearError();

    try {
      if (_mockMode) {
        // Mock resend OTP
        await Future.delayed(const Duration(milliseconds: 500));
        _setLoading(false);
        return true;
      }

      final request = ResendOtpRequest(email: email, type: type);
      final success = await _repository.resendOtp(request);
      _setLoading(false);
      return success;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to resend OTP. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Forgot password
  Future<bool> forgotPassword({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      if (_mockMode) {
        // Mock forgot password
        await Future.delayed(const Duration(milliseconds: 500));
        _setLoading(false);
        return true;
      }

      final request = ForgotPasswordRequest(email: email);
      final success = await _repository.forgotPassword(request);
      _setLoading(false);
      return success;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to send reset link. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final request = ResetPasswordRequest(
        email: email,
        otp: otp,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      final success = await _repository.resetPassword(request);
      _setLoading(false);
      return success;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Password reset failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Get user profile
  Future<void> getProfile() async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _repository.getProfile();
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      if (e.isAuthError) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      }
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load profile.');
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (_mockMode) {
        // Mock update profile
        await Future.delayed(const Duration(milliseconds: 500));
        if (_user != null) {
          _user = User(
            id: _user!.id,
            name: name ?? _user!.name,
            email: _user!.email,
            phone: phone ?? _user!.phone,
            role: _user!.role,
            address: address ?? _user!.address,
            loyaltyPoints: _user!.loyaltyPoints,
            loyaltyTier: _user!.loyaltyTier,
            avatar: _user!.avatar,
            createdAt: _user!.createdAt,
          );
        }
        _setLoading(false);
        return true;
      }

      final request = UpdateProfileRequest(
        name: name,
        phone: phone,
        address: address,
      );

      _user = await _repository.updateProfile(request);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to update profile.');
      _setLoading(false);
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount({required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _repository.deleteAccount(password);
      if (success) {
        await _repository.logout();
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      _setLoading(false);
      return success;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to delete account. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _setLoading(true);

    // Clear FCM token on the backend BEFORE clearing local auth — the request
    // needs the auth token to identify the device.
    await NotificationService.instance.clearFcmToken();

    await _repository.logout();

    _user = null;
    _status = AuthStatus.unauthenticated;
    _clearError();
    _setLoading(false);
  }

  // ============== Private Helpers ==============

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message (can be called from UI)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
