import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';
import 'package:tourify_app/features/account/model/user_profile.dart';

abstract class AccountRepository {
  Future<UserProfile?> getProfile();
  Future<UserProfile?> updateProfile(Map<String, dynamic> payload);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<Map<String, bool>> getNotificationPreferences();
  Future<Map<String, bool>> updateNotificationPreferences(
    Map<String, bool> prefs,
  );
  Future<void> submitFeedback(String message);
  Future<UserProfile?> uploadAvatar(
    Uint8List bytes, {
    required String fileName,
  });
}

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl()
    : _http = HttpClient(http.Client(), SecureStorageService()),
      _supabase = Supabase.instance.client;

  final HttpClient _http;
  final SupabaseClient _supabase;
  static const _avatarBucket = 'Traveltour';

  @override
  Future<UserProfile?> getProfile() async {
    final res = await _http.get('/api/profile');
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    final map = _extractPayload(data);
    if (map.isEmpty) return null;
    return UserProfile.fromJson(map);
  }

  @override
  Future<UserProfile?> updateProfile(Map<String, dynamic> payload) async {
    final sanitized = payload.map(
      (key, value) =>
          MapEntry(key, value is DateTime ? value.toIso8601String() : value),
    );
    final res = await _http.put('/api/profile', body: sanitized);
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      final message =
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'Không thể cập nhật thông tin.';
      throw Exception(message);
    }
    final data = jsonDecode(res.body);
    final map = _extractPayload(data);
    if (map.isEmpty) return null;
    return UserProfile.fromJson(map);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await _http.post(
      '/api/reset-password',
      body: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      },
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      final message =
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'Đổi mật khẩu thất bại.';
      throw Exception(message);
    }
  }

  @override
  Future<Map<String, bool>> getNotificationPreferences() async {
    final res = await _http.get('/api/notification-preferences');
    if (res.statusCode != 200) {
      return {};
    }
    final data = jsonDecode(res.body);
    return _parsePreferencePayload(data);
  }

  @override
  Future<Map<String, bool>> updateNotificationPreferences(
    Map<String, bool> prefs,
  ) async {
    final res = await _http.put(
      '/api/notification-preferences',
      body: prefs.map((key, value) => MapEntry(key, value)),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      final message =
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'Không thể cập nhật cài đặt thông báo.';
      throw Exception(message);
    }
    final data = jsonDecode(res.body);
    return _parsePreferencePayload(data);
  }

  @override
  Future<void> submitFeedback(String message) async {
    final res = await _http.post('/api/feedback', body: {'message': message});
    if (res.statusCode != 200 && res.statusCode != 201) {
      final data = jsonDecode(res.body);
      final errorMessage =
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'Gửi phản hồi thất bại.';
      throw Exception(errorMessage);
    }
  }

  Map<String, dynamic> _extractPayload(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return {};
  }

  Map<String, bool> _parsePreferencePayload(dynamic data) {
    final map = _extractPayload(data);
    final prefs = <String, bool>{};
    map.forEach((key, value) {
      if (value is bool) {
        prefs[key] = value;
      } else if (value is num) {
        prefs[key] = value != 0;
      } else if (value is String) {
        final lower = value.toLowerCase();
        prefs[key] = lower == 'true' || lower == '1' || lower == 'on';
      }
    });
    return prefs;
  }

  @override
  Future<UserProfile?> uploadAvatar(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final userId = _supabase.auth.currentUser?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final extension = _fileExtension(fileName);
    final objectPath =
        'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    final contentType = _contentTypeFromExtension(extension);

    try {
      await _supabase.storage.from(_avatarBucket).uploadBinary(
        objectPath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );
    } on StorageException catch (error) {
      throw Exception(error.message);
    } catch (error) {
      throw Exception('Không thể tải ảnh lên. Vui lòng thử lại.');
    }

    final publicUrl =
        _supabase.storage.from(_avatarBucket).getPublicUrl(objectPath);
    return updateProfile({'avatar_url': publicUrl});
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < fileName.length - 1) {
      final ext = fileName.substring(dotIndex + 1).toLowerCase();
      if (ext.isNotEmpty) return ext;
    }
    return 'jpg';
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
