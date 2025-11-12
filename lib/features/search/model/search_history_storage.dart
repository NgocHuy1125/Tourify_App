import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchHistoryStorage {
  static const _key = 'search_history_keywords_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<String>> get() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = json.decode(raw);
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(String keyword) async {
    if (keyword.trim().isEmpty) return;
    final list = await get();
    list.removeWhere((e) => e.toLowerCase() == keyword.toLowerCase());
    list.insert(0, keyword);
    if (list.length > 10) list.removeRange(10, list.length);
    await _storage.write(key: _key, value: json.encode(list));
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
