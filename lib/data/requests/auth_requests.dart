/// Login Request
///
/// Request body for user login.
class LoginRequest {
  final String email;
  final String password;
  final String? deviceToken;
  final String? deviceType;

  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceToken,
    this.deviceType,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (deviceToken != null) 'device_token': deviceToken,
      if (deviceType != null) 'device_type': deviceType,
    };
  }
}

/// Register Request
///
/// Request body for user registration.
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? phone;
  final String? deviceToken;
  final String? deviceType;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone,
    this.deviceToken,
    this.deviceType,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (phone != null) 'phone': phone,
      if (deviceToken != null) 'device_token': deviceToken,
      if (deviceType != null) 'device_type': deviceType,
    };
  }
}

/// OTP Verify Request
///
/// Request body for OTP verification.
class OtpVerifyRequest {
  final String email;
  final String otp;

  const OtpVerifyRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}

/// Resend OTP Request
///
/// Request body for resending OTP.
class ResendOtpRequest {
  final String email;

  const ResendOtpRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

/// Forgot Password Request
///
/// Request body for initiating password reset.
class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

/// Reset Password Request
///
/// Request body for resetting password with token.
class ResetPasswordRequest {
  final String email;
  final String token;
  final String password;
  final String passwordConfirmation;

  const ResetPasswordRequest({
    required this.email,
    required this.token,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}

/// Update Profile Request
///
/// Request body for updating user profile.
class UpdateProfileRequest {
  final String? name;
  final String? phone;
  final String? address;
  final String? image;

  const UpdateProfileRequest({
    this.name,
    this.phone,
    this.address,
    this.image,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (image != null) 'image': image,
    };
  }

  bool get hasChanges => name != null || phone != null || address != null || image != null;
}

/// Change Password Request
///
/// Request body for changing password.
class ChangePasswordRequest {
  final String currentPassword;
  final String password;
  final String passwordConfirmation;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}
