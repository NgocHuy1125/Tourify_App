import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/wishlist/model/wishlist_model.dart';
import 'package:tourify_app/features/wishlist/model/wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  late final HttpClient _http;

  WishlistRepositoryImpl() {
    _http = HttpClient(http.Client(), SecureStorageService());
  }

  @override
  Future<List<WishlistItem>> fetchWishlist() async {
    final res = await _http.get('/api/wishlist');
    if (res.statusCode != 200) {
      if (res.statusCode == 404) return [];
      throw Exception('Không thể tải danh sách yêu thích: ');
    }
    final payload = json.decode(res.body);
    final items = _extractList(payload, preferredKeys: const ['items', 'data']);
    return items
        .map((e) => WishlistItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((item) => item.tour.id.isNotEmpty)
        .toList();
  }

  @override
  Future<WishlistItem> addTour(String tourId) async {
    final res = await _http.post('/api/wishlist', body: {'tour_id': tourId});
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Không thể thêm tour vào danh sách yêu thích: ');
    }
    final payload = json.decode(res.body);
    final item = payload['item'] ?? payload;
    return WishlistItem.fromJson(Map<String, dynamic>.from(item as Map));
  }

  @override
  Future<void> removeWishlistItem(String wishlistItemId) async {
    final res = await _http.delete('/api/wishlist/$wishlistItemId');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Không thể xóa khỏi danh sách yêu thích: ');
    }
  }

  @override
  Future<List<TourSummary>> fetchTrendingTours({int limit = 6}) async {
    final res = await _http.get('/api/tours/trending?limit=$limit');
    if (res.statusCode != 200) {
      return [];
    }
    final payload = json.decode(res.body);
    final list = _extractList(payload, preferredKeys: const ['items', 'data']);
    return list
        .whereType<Map>()
        .map((e) => TourSummary.fromJson(Map<String, dynamic>.from(e)))
        .where((tour) => tour.id.isNotEmpty)
        .toList();
  }

  @override
  Future<List<TourDetail>> compareTours(List<String> tourIds) async {
    if (tourIds.isEmpty) return const [];
    final payload = {'tour_ids': tourIds.take(2).toList()};
    final res = await _http.post('/api/wishlist/compare', body: payload);

    final decoded = _tryDecode(res.body);
    if (res.statusCode != 200) {
      final message =
          _extractErrorMessage(decoded) ?? 'Không thể so sánh tour lúc này.';
      throw Exception(message);
    }

    final tours = _extractList(decoded, preferredKeys: const ['tours', 'data']);
    return tours
        .whereType<Map>()
        .map((map) => TourDetail.fromJson(Map<String, dynamic>.from(map)))
        .where((detail) => detail.id.isNotEmpty)
        .toList();
  }

  List<dynamic> _extractList(
    dynamic payload, {
    List<String> preferredKeys = const [],
  }) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      for (final key in [
        ...preferredKeys,
        'data',
        'items',
        'results',
        'list',
      ]) {
        final value = map[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  Map<String, dynamic> _tryDecode(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List) return {'data': decoded};
    } catch (_) {}
    return const {};
  }

  String? _extractErrorMessage(Map<String, dynamic> payload) {
    if (payload.isEmpty) return null;
    for (final key in ['message', 'error', 'detail']) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    final errors = payload['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is Map) {
        for (final value in first.values) {
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    } else if (errors is Map) {
      for (final value in errors.values) {
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) return first.trim();
        }
      }
    }
    return null;
  }
}
