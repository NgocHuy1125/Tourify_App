// lib/core/api/http_client.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:tourify_app/core/services/secure_storage_service.dart';

class HttpClient {
  final http.Client _client;
  final SecureStorageService _storageService;
  final String _baseUrl = 'https://travel-backend-heov.onrender.com';

  HttpClient(this._client, this._storageService);

  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final token = await _storageService.getToken();
    final headers = {
      // Chỉ đặt Content-Type cho JSON.
      // Với Form Data (asJson = false), package http sẽ tự động đặt header phù hợp.
      if (isJson) 'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Gửi yêu cầu POST.
  /// Mặc định gửi dưới dạng JSON. Đặt [asJson] thành `false` để gửi dạng `application/x-www-form-urlencoded`.
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool asJson = true, // <-- Thêm tùy chọn này
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(isJson: asJson);

    // Nếu là JSON, encode nó. Nếu không, để nguyên (dành cho form-data).
    final Object? requestBody = asJson
        ? json.encode(body ?? <String, dynamic>{})
        : (body ?? <String, dynamic>{})
            .map((key, value) => MapEntry(key, value?.toString() ?? ''));

    return _client
        .post(uri, headers: headers, body: requestBody)
        .timeout(
          const Duration(seconds: 60), // Chờ tối đa 60 giây
          onTimeout: () {
            // Trả về lỗi timeout để presenter có thể xử lý
            return http.Response(
              json.encode({
                'message':
                    'Không nhận được phản hồi từ máy chủ. Vui lòng thử lại.',
              }),
              408,
            ); // 408 Request Timeout
          },
        );
  }

  /// Gửi yêu cầu GET.
  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();

    return _client
        .get(uri, headers: headers)
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            return http.Response(
              json.encode({
                'message':
                    'Không nhận được phản hồi từ máy chủ. Vui lòng thử lại.',
              }),
              408,
            );
          },
        );
  }
}
