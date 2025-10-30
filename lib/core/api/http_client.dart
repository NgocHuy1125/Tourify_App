// lib/core/api/http_client.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tourify_app/core/services/secure_storage_service.dart';

class HttpClient {
  final http.Client _client;
  final SecureStorageService _storageService;
  final String _baseUrl;

  HttpClient(this._client, this._storageService, {String? baseUrl})
    : _baseUrl = baseUrl ?? 'https://travel-backend-heov.onrender.com';

  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final token = await _storageService.getToken();
    final headers = <String, String>{
      if (isJson) 'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String endpoint) {
    final trimmed = endpoint.trim();
    if (trimmed.startsWith('http')) {
      return Uri.parse(trimmed);
    }
    if (trimmed.startsWith('/')) {
      return Uri.parse('$_baseUrl$trimmed');
    }
    return Uri.parse('$_baseUrl/$trimmed');
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool asJson = true,
  }) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders(isJson: asJson);
    final Object? requestBody =
        asJson
            ? json.encode(body ?? <String, dynamic>{})
            : (body ?? <String, dynamic>{}).map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            );

    return _client
        .post(uri, headers: headers, body: requestBody)
        .timeout(const Duration(seconds: 60), onTimeout: _timeoutResponse);
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool asJson = true,
  }) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders(isJson: asJson);
    final Object? requestBody =
        asJson
            ? json.encode(body ?? <String, dynamic>{})
            : (body ?? <String, dynamic>{}).map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            );

    return _client
        .put(uri, headers: headers, body: requestBody)
        .timeout(const Duration(seconds: 60), onTimeout: _timeoutResponse);
  }

  Future<http.Response> delete(String endpoint) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders();
    return _client
        .delete(uri, headers: headers)
        .timeout(const Duration(seconds: 60), onTimeout: _timeoutResponse);
  }

  Future<http.Response> get(String endpoint) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders();
    return _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 60), onTimeout: _timeoutResponse);
  }

  http.Response _timeoutResponse() {
    return http.Response(
      json.encode({
        'message': 'Không nhận được phản hồi từ máy chủ. Vui lòng thử lại sau.',
      }),
      408,
    );
  }
}
