import 'dart:convert';
import 'package:http/http.dart' as http;
import '/features/tour/model/tour_model.dart';

class ToursApi {
  final http.Client _client;
  final String baseUrl;
  final String? Function()? tokenProvider; // optional

  ToursApi(this._client, {required this.baseUrl, this.tokenProvider});

  Map<String, String> _headers({bool auth = false}) {
    final h = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final t = tokenProvider?.call();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Future<List<TourSummary>> search({
    String? q,
    String? destination,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int limit = 20,
    String sort = 'trending',
  }) async {
    final qp = {
      if (q?.isNotEmpty == true) 'q': q!,
      if (destination?.isNotEmpty == true) 'destination': destination!,
      if (categoryId?.isNotEmpty == true) 'category_id': categoryId!,
      if (dateFrom != null)
        'date_from': dateFrom.toIso8601String().substring(0, 10),
      if (dateTo != null) 'date_to': dateTo.toIso8601String().substring(0, 10),
      'page': '$page',
      'limit': '$limit',
      'sort': sort,
    };
    final uri = Uri.parse('$baseUrl/tours').replace(queryParameters: qp);
    final res = await _client.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Search failed ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as List;
    return data.map((e) => TourSummary.fromJson(e)).toList();
  }

  Future<TourDetail> getDetail(String id) async {
    final uri = Uri.parse('$baseUrl/tours/$id');
    final res = await _client.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Detail failed');
    }
    return TourDetail.fromJson(jsonDecode(res.body));
  }

  Future<void> toggleWishlist(String tourId, {required bool add}) async {
    final uri =
        add
            ? Uri.parse('$baseUrl/wishlist')
            : Uri.parse('$baseUrl/wishlist/$tourId');
    final res =
        add
            ? await _client.post(
              uri,
              headers: _headers(auth: true),
              body: jsonEncode({'tour_id': tourId}),
            )
            : await _client.delete(uri, headers: _headers(auth: true));
    if (res.statusCode >= 300) throw Exception('Wishlist failed');
  }
}
