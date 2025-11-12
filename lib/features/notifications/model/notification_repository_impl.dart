import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';

import 'notification_model.dart';
import 'notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl()
    : _http = HttpClient(http.Client(), SecureStorageService());

  final HttpClient _http;

  @override
  Future<NotificationPage> fetchNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final query = '?per_page=$perPage&page=$page';
    final response = await _http.get('/api/notifications$query');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(response.body) ??
            'Không thể tải danh sách thông báo.',
      );
    }

    final decoded = json.decode(response.body);
    final list = _extractList(
      decoded,
      preferredKeys: const ['notifications', 'data', 'items'],
    );

    final notifications = list
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    final pagination = _extractMap(
      decoded,
      preferredKeys: const ['meta', 'pagination'],
    );

    final currentPage = pagination['current_page'] is num
        ? (pagination['current_page'] as num).toInt()
        : page;
    final lastPage = pagination['last_page'] is num
        ? (pagination['last_page'] as num).toInt()
        : null;
    final hasMore =
        lastPage != null
            ? currentPage < lastPage
            : notifications.length >= perPage;

    return NotificationPage(
      items: notifications,
      page: currentPage,
      hasMore: hasMore,
    );
  }

  @override
  Future<int> fetchUnreadCount() async {
    final response = await _http.get('/api/notifications/unread-count');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 0;
    }
    final decoded = json.decode(response.body);
    final map = _extractMap(decoded);
    final unread = map['unread'] ?? map['count'] ?? map['unread_count'];
    if (unread is num) return unread.toInt();
    return int.tryParse(unread?.toString() ?? '') ?? 0;
  }

  @override
  Future<void> markAsRead(String id) async {
    if (id.isEmpty) return;
    final response = await _http.post('/api/notifications/$id/read');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(response.body) ??
            'Không thể đánh dấu thông báo đã đọc.',
      );
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final response = await _http.post('/api/notifications/read-all');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(response.body) ??
            'Không thể đánh dấu tất cả thông báo.',
      );
    }
  }

  @override
  Future<bool> toggleNotifications(bool enabled) async {
    final response = await _http.post(
      '/api/notifications/toggle',
      body: {'enabled': enabled},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(response.body) ??
            'Không thể cập nhật cài đặt thông báo.',
      );
    }
    final decoded = json.decode(response.body);
    final map = _extractMap(decoded);
    final value =
        map['enabled'] ??
        map['notifications_enabled'] ??
        map['data']?['enabled'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'on';
    }
    return enabled;
  }

  @override
  Future<bool?> fetchNotificationsEnabled() async {
    final response = await _http.get('/api/profile');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final decoded = json.decode(response.body);
    final map = _extractMap(decoded);
    final value =
        map['notifications_enabled'] ??
        map['notificationsEnabled'] ??
        map['notification_enabled'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'on') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'off') {
        return false;
      }
    }
    return null;
  }

  List<dynamic> _extractList(
    dynamic payload, {
    List<String> preferredKeys = const [],
  }) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      for (final key in [...preferredKeys, 'data', 'items', 'results']) {
        final value = map[key];
        if (value is List) return value;
        if (value is Map) {
          final nested = _extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(
    dynamic payload, {
    List<String> preferredKeys = const [],
  }) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    if (payload is Iterable) {
      for (final element in payload) {
        final map = _extractMap(element);
        if (map.isNotEmpty) return map;
      }
    }
    if (preferredKeys.isNotEmpty && payload is Map<String, dynamic>) {
      for (final key in preferredKeys) {
        final nested = payload[key];
        if (nested is Map<String, dynamic>) return nested;
      }
    }
    return const {};
  }

  String? _extractMessage(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return null;
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        final decoded = json.decode(trimmed);
        final map = _extractMap(decoded);
        for (final key in ['message', 'error', 'detail']) {
          final value = map[key];
          if (value is String && value.isNotEmpty) return value;
        }
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }
}
