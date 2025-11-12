import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';
import 'package:tourify_app/features/search/model/search_suggestion.dart';

class SearchRepository {
  late final HttpClient _http;
  SearchRepository() {
    _http = HttpClient(http.Client(), SecureStorageService());
  }

  Future<List<SearchSuggestion>> suggestions(String keyword) async {
    final query = keyword.trim();
    final endpoint =
        query.isEmpty
            ? '/api/search/suggestions'
            : '/api/search/suggestions?keyword=${Uri.encodeQueryComponent(query)}';

    final res = await _http.get(endpoint);
    if (res.statusCode != 200) return const [];
    final decoded = json.decode(res.body);
    final suggestions = _extractList(decoded);
    return suggestions
        .whereType<Map>()
        .map((e) => SearchSuggestion.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.title.isNotEmpty)
        .toList();
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      for (final key in ['data', 'suggestions', 'items', 'results', 'list']) {
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
}
