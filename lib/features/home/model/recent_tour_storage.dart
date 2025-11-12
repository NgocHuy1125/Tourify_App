import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'home_models.dart';

class RecentTourStorage {
  RecentTourStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'recent_tours_cache_v1';

  Future<List<RecentTourItem>> getAll() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (e) => RecentTourItem.fromStorageJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .where((item) => item.tour.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsert(RecentTourItem item, {int maxItems = 12}) async {
    final current = await getAll();
    final normalized = item.copyWith(
      viewedAt: item.viewedAt ?? DateTime.now(),
    );
    final updated = [
      normalized,
      ...current.where((entry) => entry.tour.id != normalized.tour.id),
    ];
    final limited = updated.take(maxItems).toList();
    final payload =
        json.encode(limited.map((e) => e.toStorageJson()).toList());
    await _storage.write(key: _key, value: payload);
  }

  Future<void> replaceAll(List<RecentTourItem> items, {int maxItems = 12}) {
    final limited = items.take(maxItems).toList();
    if (limited.isEmpty) {
      return _storage.delete(key: _key);
    }
    final payload =
        json.encode(limited.map((e) => e.toStorageJson()).toList());
    return _storage.write(key: _key, value: payload);
  }

  Future<void> clear() => _storage.delete(key: _key);
}
