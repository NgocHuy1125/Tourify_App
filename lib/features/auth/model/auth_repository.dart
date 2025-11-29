// lib/features/auth/model/auth_repository.dart

class AuthResponse {
  final String accessToken;
  final Map<String, dynamic> user;

  AuthResponse({required this.accessToken, required this.user});
}

abstract class AuthRepository {
  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<AuthResponse> signIn({
    required String identifier,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendLoginOrRegisterOtp({required String identifier});

  Future<Map<String, dynamic>> verifyLoginOrRegisterOtp({
    required String identifier,
    required String otp,
  });

  /// Đăng nhập Google cho mobile: gửi id_token cho backend.
  Future<AuthResponse> handleGoogleMobile({required String idToken});

  /// Gửi mã xác thực từ Google/Facebook cho backend để hoàn tất đăng nhập.
  /// [provider] = 'google' | 'facebook'; [code] = idToken (Google) | accessToken (Facebook).
  Future<AuthResponse> handleSocialLoginCallback({
    required String provider,
    required String code,
  });

  Future<void> sendForgotPasswordOtp({required String identifier});

  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String identifier,
    required String otp,
  });

  Future<void> setNewPassword({
    required String otpId,
    required String identifier,
    required String channel,
    required String otp,
    required String newPassword,
    required String passwordConfirmation,
  });
}
