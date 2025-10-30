import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/tour.dart';
import '../../domain/repositories/tour_repository.dart';

class TourRepositoryHttp implements TourRepository {
  final http.Client _client;
  final String baseUrl;
  final String? Function()? tokenProvider; // optional

  TourRepositoryHttp(this._client, {required this.baseUrl, this.tokenProvider});

  @override
  Future<List<Tour>> search({String? q, int? minPrice, int? maxPrice}) async {
    final params = <String, String>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (minPrice != null) params['min_price'] = '$minPrice';
    if (maxPrice != null) params['max_price'] = '$maxPrice';

    final uri = Uri.parse(
      '$baseUrl/api/tours',
    ).replace(queryParameters: params);
    final headers = <String, String>{'Accept': 'application/json'};
    final t = tokenProvider?.call();
    if (t != null) headers['Authorization'] = 'Bearer $t';

    final res = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Search failed: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['items'] as List?) ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return Tour(
        id: m['id'],
        title: m['title'],
        destination: m['destination'],
        durationDays: m['duration_days'],
        priceFrom: m['price_from'],
        ratingAvg: m['rating_avg'],
      );
    }).toList();
  }

  @override
  Future<Tour> detail(String id) async {
    final uri = Uri.parse('$baseUrl/api/tours/$id');
    final headers = <String, String>{'Accept': 'application/json'};
    final t = tokenProvider?.call();
    if (t != null) headers['Authorization'] = 'Bearer $t';

    final res = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Detail failed: ${res.statusCode}');
    }
    final m = jsonDecode(res.body) as Map<String, dynamic>;
    return Tour(
      id: m['id'],
      title: m['title'],
      destination: m['destination'],
      durationDays: m['duration_days'],
      priceFrom: m['price_from'],
      ratingAvg: m['rating_avg'],
    );
  }
}
