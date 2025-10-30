import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';
import 'package:tourify_app/features/account/model/user_profile.dart';

abstract class AccountRepository {
  Future<UserProfile?> getProfile();
}

class AccountRepositoryImpl implements AccountRepository {
  late final HttpClient _http;
  AccountRepositoryImpl() {
    _http = HttpClient(http.Client(), SecureStorageService());
  }

  @override
  Future<UserProfile?> getProfile() async {
    final res = await _http.get('/api/profile');
    if (res.statusCode != 200) return null;
    final data = json.decode(res.body);
    final Map<String, dynamic> map =
        data is Map<String, dynamic> ? data : (data['data'] ?? {});
    if (map.isEmpty) return null;
    return UserProfile.fromJson(map);
  }
}

