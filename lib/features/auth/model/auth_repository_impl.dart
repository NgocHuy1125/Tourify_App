import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  late final HttpClient _httpClient;
  late final SecureStorageService _storageService;

  AuthRepositoryImpl() {
    _storageService = SecureStorageService();
    _httpClient = HttpClient(http.Client(), _storageService);
  }

  void _handleErrorResponse(http.Response response) {
    final body = response.body;
    try {
      if (body.isEmpty) {
        throw const FormatException('Empty body');
      }
      final errorData = json.decode(body);
      final message =
          (errorData is Map)
              ? (errorData['message'] ??
                  errorData['error'] ??
                  errorData['errors'])
              : errorData;
      throw Exception(message?.toString() ?? 'Có lỗi xảy ra.');
    } catch (_) {
      throw Exception(
        'Lỗi máy chủ: ${response.statusCode}. Body: ${body.isEmpty ? 'no-body' : body}',
      );
    }
  }

  @override
  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _httpClient.post(
      '/api/register',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = (data['access_token'] ?? '').toString();
      if (token.isNotEmpty) await _storageService.saveToken(token);
      final user =
          (data['user'] is Map)
              ? (data['user'] as Map).cast<String, dynamic>()
              : <String, dynamic>{};
      return AuthResponse(accessToken: token, user: user);
    }
    _handleErrorResponse(response);
    throw Exception('Đăng ký thất bại');
  }

  @override
  Future<AuthResponse> signIn({
    required String identifier,
    required String password,
  }) async {
    final body =
        identifier.contains('@')
            ? {'email': identifier, 'password': password}
            : {'phone': identifier, 'password': password};
    final response = await _httpClient.post(
      '/api/login',
      body: body,
      asJson: false,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = (data['access_token'] ?? '').toString();
      if (token.isEmpty) {
        throw Exception('Phản hồi không chứa access_token.');
      }
      await _storageService.saveToken(token);
      final user =
          (data['user'] is Map)
              ? (data['user'] as Map).cast<String, dynamic>()
              : <String, dynamic>{};
      return AuthResponse(accessToken: token, user: user);
    }
    _handleErrorResponse(response);
    throw Exception('Đăng nhập thất bại.');
  }

  @override
  Future<void> signOut() async {
    try {
      await _httpClient.post('/api/logout');
    } catch (_) {
    } finally {
      await _storageService.deleteToken();
    }
  }

  @override
  Future<void> sendLoginOrRegisterOtp({required String identifier}) async {
    final channel = identifier.contains('@') ? 'email' : 'phone';
    final response = await _httpClient.post(
      '/api/auth/send-otp',
      body: {'channel': channel, 'value': identifier},
    );
    if (response.statusCode != 200) _handleErrorResponse(response);
  }

  @override
  Future<Map<String, dynamic>> verifyLoginOrRegisterOtp({
    required String identifier,
    required String otp,
  }) async {
    final channel = identifier.contains('@') ? 'email' : 'phone';
    final response = await _httpClient.post(
      '/api/auth/verify-otp',
      body: {'channel': channel, 'value': identifier, 'otp': otp},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final token =
          (data['access_token'] ?? data['token'] ?? '').toString().trim();
      if (token.isNotEmpty) {
        await _storageService.saveToken(token);
      }
      return data;
    }
    _handleErrorResponse(response);
    throw Exception('Xác thực OTP thất bại.');
  }

  @override
  Future<AuthResponse> handleSocialLoginCallback({
    required String provider,
    required String code,
  }) async {
    final response = await _httpClient.get(
      '/api/auth/social/$provider/callback?code=$code',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = (data['access_token'] ?? '').toString();
      if (token.isEmpty) {
        throw Exception('Phản hồi không chứa access_token.');
      }
      await _storageService.saveToken(token);
      final user =
          (data['user'] is Map)
              ? (data['user'] as Map).cast<String, dynamic>()
              : <String, dynamic>{};
      return AuthResponse(accessToken: token, user: user);
    }
    _handleErrorResponse(response);
    throw Exception('Đăng nhập mạng xã hội thất bại.');
  }

  @override
    @override
  Future<AuthResponse> handleGoogleMobile({required String idToken}) async {
    final response = await _httpClient.post(
      '/api/auth/social/google/mobile',
      body: {'id_token': idToken},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final token = (data['access_token'] ?? '').toString();
      if (token.isEmpty) {
        throw Exception('Phản hồi không chứa access_token.');
      }
      await _storageService.saveToken(token);
      final user =
          (data['user'] is Map)
              ? (data['user'] as Map).cast<String, dynamic>()
              : <String, dynamic>{};
      return AuthResponse(accessToken: token, user: user);
    }
    _handleErrorResponse(response);
    throw Exception('Đăng nhập Google (mobile) thất bại.');
  }
Future<void> sendForgotPasswordOtp({required String identifier}) async {
    final channel = identifier.contains('@') ? 'email' : 'phone';
    final response = await _httpClient.post(
      '/api/auth/send-otp',
      body: {'channel': channel, 'value': identifier},
    );
    if (response.statusCode != 200) _handleErrorResponse(response);
  }

  @override
  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String identifier,
    required String otp,
  }) async {
    final channel = identifier.contains('@') ? 'email' : 'phone';
    final response = await _httpClient.post(
      '/api/auth/verify-otp',
      body: {'channel': channel, 'value': identifier, 'otp': otp},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    _handleErrorResponse(response);
    throw Exception('Xác thực OTP thất bại.');
  }

  @override
  Future<void> setNewPassword({
    required String otpId,
    required String identifier,
    required String channel,
    required String otp,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    final response = await _httpClient.post(
      '/api/auth/set-password',
      body: {
        'otp_id': otpId,
        'channel': channel,
        'value': identifier,
        'otp': otp,
        'password': newPassword,
        'password_confirmation': passwordConfirmation,
      },
    );
    if (response.statusCode != 200) _handleErrorResponse(response);
  }
}
