import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';
import 'package:tourify_app/features/home/model/home_models.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

const _baseHost = 'https://travel-backend-heov.onrender.com';

abstract class HomeRepository {
  Future<List<PromotionItem>> fetchActivePromotions({int limit = 5});
  Future<List<TourSummary>> fetchAllTours({int limit = 20});
  Future<List<TourSummary>> fetchTrendingTours({int limit = 8, int days = 30});
}

class HomeRepositoryImpl implements HomeRepository {
  late final HttpClient _http;

  HomeRepositoryImpl() {
    _http = HttpClient(http.Client(), SecureStorageService());
  }

  @override
  Future<List<PromotionItem>> fetchActivePromotions({int limit = 5}) async {
    final res = await _http.get('/api/promotions/active?limit=$limit');
    if (res.statusCode != 200) {
      return [];
    }
    final payload = json.decode(res.body);
    final list = _extractList(
      payload,
      preferredKeys: const ['promotions', 'data', 'items'],
    );
    return list
        .map((e) => PromotionItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<TourSummary>> fetchAllTours({int limit = 20}) async {
    final res = await _http.get('/api/tours?limit=$limit');
    if (res.statusCode != 200) {
      throw Exception('Failed to load tours:  ');
    }
    final payload = json.decode(res.body);
    final list = _extractList(
      payload,
      preferredKeys: const ['data', 'items', 'tours'],
    );
    return list
        .map((e) => TourSummary.fromJson(_normalizeTourJson(e)))
        .toList();
  }

  @override
  Future<List<TourSummary>> fetchTrendingTours({
    int limit = 8,
    int days = 30,
  }) async {
    final res = await _http.get('/api/tours/trending?limit=$limit&days=$days');
    if (res.statusCode != 200) {
      return [];
    }
    final payload = json.decode(res.body);
    final list = _extractList(
      payload,
      preferredKeys: const ['data', 'items', 'trending'],
    );
    return list
        .map((e) => TourSummary.fromJson(_normalizeTourJson(e)))
        .toList();
  }

  List<dynamic> _extractList(
    dynamic payload, {
    List<String> preferredKeys = const [],
  }) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      for (final key in [...preferredKeys, 'results', 'list']) {
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

  Map<String, dynamic> _normalizeTourJson(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);

    map['id'] =
        (map['id'] ?? map['slug'] ?? map['code'] ?? map['uuid'] ?? '')
            .toString();
    map['title'] =
        (map['title'] ?? map['name'] ?? map['tour_name'] ?? 'Tour').toString();
    map['destination'] =
        (map['destination'] ??
                map['location'] ??
                map['city'] ??
                map['province'] ??
                '')
            .toString();

    final priceSource =
        map['priceFrom'] ??
        map['price_from'] ??
        map['base_price'] ??
        map['min_price'];
    if (priceSource != null) {
      final value =
          priceSource is num
              ? priceSource.toDouble()
              : double.tryParse(priceSource.toString());
      if (value != null) {
        map['priceFrom'] = value;
        map['base_price'] = value;
      }
    }

    final durationSource =
        map['duration'] ?? map['duration_days'] ?? map['duration_day'];
    if (durationSource != null) {
      final value =
          durationSource is num
              ? durationSource.toInt()
              : int.tryParse(durationSource.toString());
      if (value != null) {
        map['duration'] = value;
      }
    }

    final cover =
        map['media_cover'] ??
        map['cover_image'] ??
        map['coverImage'] ??
        map['cover'] ??
        map['thumbnail'] ??
        map['image'] ??
        map['image_url'] ??
        map['thumbnail_url'];
    if (map['media'] == null && cover != null) {
      map['media'] = [_resolveUrl(cover.toString())];
    } else if (map['media'] is String) {
      map['media'] = [_resolveUrl(map['media'].toString())];
    } else if (map['media'] is List) {
      map['media'] =
          (map['media'] as List).map((e) => _resolveUrl(e.toString())).toList();
    }

    if (map['rating_avg'] == null && map['ratingAvg'] != null) {
      map['rating_avg'] = map['ratingAvg'];
    }
    if (map['reviews_count'] == null && map['reviews'] is List) {
      map['reviews_count'] = (map['reviews'] as List).length;
    }
    if (map['bookings_count'] == null && map['bookingsCount'] != null) {
      map['bookings_count'] = map['bookingsCount'];
    }

    return map;
  }

  String _resolveUrl(String value) {
    if (value.isEmpty) return value;
    if (value.startsWith('http')) return value;
    if (value.startsWith('/')) return '$_baseHost$value';
    return '$_baseHost/$value';
  }
}
