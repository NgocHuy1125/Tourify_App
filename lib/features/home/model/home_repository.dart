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
  Future<List<TourSummary>> fetchToursByCategory(
    String categoryId, {
    String? slug,
    int limit = 100,
  });
  Future<List<TourSummary>> fetchTrendingTours({int limit = 8, int days = 30});
  Future<List<CategoryItem>> fetchHighlightCategories({int limit = 6});
  Future<List<DestinationHighlight>> fetchDestinationHighlights({
    int limit = 10,
  });
  Future<List<RecommendationItem>> fetchRecommendations({int limit = 10});
  Future<List<RecentTourItem>> fetchRecentTours({int limit = 10});
  Future<ChatbotReply> sendChatbotMessage(
    String message, {
    String language = 'vi',
  });
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
    final query =
        limit > 0 ? '?per_page=$limit' : '';
    final res = await _http.get('/api/tours$query');
    if (res.statusCode != 200) {
      throw Exception('Không thể tải danh sách tour (mã ${res.statusCode}).');
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

  @override
  Future<List<CategoryItem>> fetchHighlightCategories({int limit = 6}) async {
    final res = await _http.get('/api/home/highlight-categories?limit=$limit');
    if (res.statusCode != 200) {
      return const [];
    }
    final payload = json.decode(res.body);
    var categories =
        _extractList(
              payload,
              preferredKeys: const ['data', 'categories', 'items'],
            )
            .whereType<Map>()
            .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e)))
            .where((item) => item.id.isNotEmpty)
            .toList();

    final needsCover =
        categories
            .where(
              (item) =>
                  (item.coverImage == null || item.coverImage!.isEmpty) &&
                  (item.imageUrl == null || item.imageUrl!.isEmpty),
            )
            .toList();

    if (needsCover.isNotEmpty) {
      final updated = await Future.wait(
        needsCover.map((item) async {
          final cover = await _fetchCategoryCover(item);
          return cover == null ? item : item.copyWith(coverImage: cover);
        }),
      );
      final map = {for (final item in updated) item.id: item};
      categories = categories.map((item) => map[item.id] ?? item).toList();
    }

    return categories;
  }

  Future<String?> _fetchCategoryCover(CategoryItem category) async {
    final queries = <String>[];
    if (category.id.isNotEmpty) {
      queries.add('category_id=${Uri.encodeQueryComponent(category.id)}');
    }
    if (category.slug?.isNotEmpty ?? false) {
      queries.add('category=${Uri.encodeQueryComponent(category.slug!)}');
    }
    if (category.name.isNotEmpty) {
      queries.add('category_name=${Uri.encodeQueryComponent(category.name)}');
    }

    for (final query in queries) {
      final res = await _http.get('/api/tours?limit=1&$query');
      if (res.statusCode != 200) continue;
      final payload = json.decode(res.body);
      final list = _extractList(
        payload,
        preferredKeys: const ['data', 'items', 'tours'],
      );
      if (list.isEmpty) continue;
      final first = list.first;
      if (first is Map) {
        final summary = TourSummary.fromJson(_normalizeTourJson(first));
        if (summary.mediaCover != null && summary.mediaCover!.isNotEmpty) {
          return summary.mediaCover;
        }
      }
    }
    return null;
  }

  @override
  Future<List<DestinationHighlight>> fetchDestinationHighlights({
    int limit = 10,
  }) async {
    final res = await _http.get('/api/tours?limit=$limit');
    if (res.statusCode != 200) {
      return const [];
    }
    final payload = json.decode(res.body);
    final tours =
        _extractList(payload, preferredKeys: const ['data', 'items', 'tours'])
            .whereType<Map>()
            .map((e) => TourSummary.fromJson(_normalizeTourJson(e)))
            .toList();

    final map = <String, DestinationHighlight>{};
    for (final tour in tours) {
      final key = tour.destination.trim();
      if (key.isEmpty) continue;
      map.putIfAbsent(
        key,
        () => DestinationHighlight(name: key, imageUrl: tour.mediaCover ?? ''),
      );
    }
    return map.values.take(limit).toList();
  }

  @override
  Future<List<RecommendationItem>> fetchRecommendations({
    int limit = 10,
  }) async {
    final res = await _http.get('/api/recommendations?limit=$limit');
    if (res.statusCode == 401) {
      return const [];
    }
    if (res.statusCode != 200) {
      return const [];
    }
    final payload = json.decode(res.body);
    final list = _extractList(
      payload,
      preferredKeys: const ['data', 'items', 'recommendations'],
    );
    return list
        .whereType<Map>()
        .map((e) => RecommendationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<TourSummary>> fetchToursByCategory(
    String categoryId, {
    String? slug,
    int limit = 100,
  }) async {
    if (categoryId.isEmpty && (slug == null || slug.isEmpty)) {
      return fetchAllTours(limit: limit);
    }

    final params = <String, String>{
      if (limit > 0) 'per_page': '$limit',
      if (categoryId.isNotEmpty) 'category_id': categoryId,
      if (slug != null && slug.isNotEmpty) 'category': slug,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final res = await _http.get('/api/tours?${query}');
    if (res.statusCode != 200) {
      throw Exception('Không thể tải tour theo danh mục.');
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
  Future<List<RecentTourItem>> fetchRecentTours({int limit = 10}) async {
    final query = limit > 0 ? '?limit=$limit' : '';
    final res = await _http.get('/api/recent-tours$query');
    if (res.statusCode == 401) {
      throw const UnauthorizedHomeException(
        'Bạn cần đăng nhập để xem lịch sử tour đã xem gần đây.',
      );
    }
    if (res.statusCode != 200) {
      throw Exception('Không thể tải danh sách tour đã xem (mã ${res.statusCode}).');
    }
    final payload = json.decode(res.body);
    final list = _extractList(
      payload,
      preferredKeys: const ['data', 'items', 'recent', 'tours'],
    );
    return list
        .whereType<Map>()
        .map((e) => _mapRecentTour(Map<String, dynamic>.from(e)))
        .whereType<RecentTourItem>()
        .toList();
  }

  RecentTourItem? _mapRecentTour(Map<String, dynamic> raw) {
    Map<String, dynamic> tourMap = {};
    final tourData = raw['tour'] ?? raw['tour_data'] ?? raw['tour_info'];
    if (tourData is Map<String, dynamic>) {
      tourMap = Map<String, dynamic>.from(tourData);
    } else if (tourData is Map) {
      tourMap = Map<String, dynamic>.from(tourData.cast());
    }

    if (tourMap.isEmpty) {
      tourMap = Map<String, dynamic>.from(raw);
    }

    if (tourMap.isEmpty) {
      return null;
    }

    final summary = TourSummary.fromJson(_normalizeTourJson(tourMap));

    final viewedAt = _parseDateTime(
      raw['viewed_at'] ??
          raw['viewedAt'] ??
          raw['last_viewed_at'] ??
          raw['lastViewedAt'],
    );

    final viewCount = _parseInt(
      raw['view_count'] ??
          raw['viewCount'] ??
          raw['views'] ??
          raw['total_views'] ??
          raw['viewed'],
    );

    return RecentTourItem(
      tour: summary,
      viewedAt: viewedAt?.toLocal(),
      viewCount: viewCount,
    );
  }

  @override
  Future<ChatbotReply> sendChatbotMessage(
    String message, {
    String language = 'vi',
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw Exception('Hãy nhập nội dung trước khi gửi cho chatbot.');
    }

    final response = await _http.post(
      '/api/chatbot',
      body: {
        'message': trimmed,
        if (language.trim().isNotEmpty) 'language': language.trim(),
      },
    );

    if (response.statusCode == 429) {
      throw ChatbotRateLimitException(
        _extractMessage(response.body) ??
            'Bạn đang hỏi quá nhanh. Vui lòng thử lại sau ít phút.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final messageText =
          _extractMessage(response.body) ??
          'Chatbot đang bận. Vui lòng thử lại sau.';
      throw Exception(messageText);
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      throw Exception('Chatbot chưa phản hồi. Vui lòng thử lại.');
    }

    final decoded = json.decode(body);
    final map =
        decoded is Map<String, dynamic>
            ? decoded
            : decoded is Map
                ? Map<String, dynamic>.from(decoded.cast())
                : <String, dynamic>{};

    if (map.isEmpty) {
      throw Exception('Không thể đọc phản hồi từ chatbot.');
    }

    return ChatbotReply.fromJson(map);
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

  String? _extractMessage(dynamic source) {
    if (source == null) return null;
    if (source is String) {
      final trimmed = source.trim();
      if (trimmed.isEmpty) return null;
      final isJson =
          (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'));
      if (isJson) {
        try {
          final decoded = json.decode(trimmed);
          return _extractMessage(decoded);
        } catch (_) {
          return trimmed;
        }
      }
      return trimmed;
    }
    if (source is Map) {
      for (final key in ['message', 'error', 'detail', 'title']) {
        final value = source[key];
        final message = _extractMessage(value);
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      for (final value in source.values) {
        final message = _extractMessage(value);
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    }
    if (source is Iterable) {
      for (final value in source) {
        final message = _extractMessage(value);
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString();
    if (text.isEmpty) return null;
    try {
      return DateTime.parse(text);
    } catch (_) {
      return null;
    }
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
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
        map.putIfAbsent('price_after_discount', () => value);
      }
    }

    final discountedSource = map['price_after_discount'];
    if (discountedSource != null) {
      final discountedValue =
          discountedSource is num
              ? discountedSource.toDouble()
              : double.tryParse(discountedSource.toString());
      if (discountedValue != null) {
        map['price_after_discount'] = discountedValue;
      } else if (map['priceFrom'] is num) {
        map['price_after_discount'] = map['priceFrom'];
      }
    } else if (map['priceFrom'] is num) {
      map['price_after_discount'] = map['priceFrom'];
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

class UnauthorizedHomeException implements Exception {
  const UnauthorizedHomeException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'Không có quyền thực hiện thao tác này.';
}

class ChatbotRateLimitException implements Exception {
  const ChatbotRateLimitException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'Bạn đang hỏi quá nhanh, vui lòng thử lại sau.';
}
