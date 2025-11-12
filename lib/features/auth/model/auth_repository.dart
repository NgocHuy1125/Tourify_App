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

  /// Đăng nhập bằng email và mật khẩu.
  Future<AuthResponse> signIn({
    required String identifier,
    required String password,
  });

  /// Đăng xuất khỏi ứng dụng (thông báo cho backend).
  Future<void> signOut();

  /// Yêu cầu backend gửi mã OTP cho việc đăng nhập/đăng ký.
  Future<void> sendLoginOrRegisterOtp({required String identifier});

  /// Yêu cầu backend xác thực mã OTP và trả về kết quả (user có tồn tại không và token nếu có).
  Future<Map<String, dynamic>> verifyLoginOrRegisterOtp({
    required String identifier,
    required String otp,
  });

  // --- LUỒNG ĐĂNG NHẬP XÃ HỘI ---

  /// Gửi mã xác thực từ Google/Facebook cho backend để hoàn tất đăng nhập.
  /// [provider] là 'google' hoặc 'facebook'.
  /// [code] là idToken (từ Google) hoặc accessToken (từ Facebook).
  Future<AuthResponse> handleSocialLoginCallback({
    required String provider,
    required String code,
  });

  // --- LUỒNG QUÊN MẬT KHẨU TÙY CHỈNH (DO BACKEND XỬ LÝ) ---

  /// Yêu cầu backend gửi mã OTP để reset mật khẩu.
  Future<void> sendForgotPasswordOtp({required String identifier});

  /// Yêu cầu backend xác thực mã OTP và trả về otp_id để dùng ở bước tiếp theo.
  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String identifier,
    required String otp,
  });

  /// Gửi mật khẩu mới cùng với thông tin OTP đã xác thực để hoàn tất việc reset.
  Future<void> setNewPassword({
    required String otpId,
    required String identifier,
    required String channel,
    required String otp,
    required String newPassword,
    required String passwordConfirmation,
  });
}
