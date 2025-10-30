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
    if (keyword.trim().isEmpty) return [];
    final res = await _http.get('/api/search/suggestions?keyword=${Uri.encodeQueryComponent(keyword)}');
    if (res.statusCode != 200) return [];
    final decoded = json.decode(res.body);
    final List list = decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
    return list.map((e) => SearchSuggestion.fromJson((e as Map).cast<String, dynamic>())).toList();
  }
}

