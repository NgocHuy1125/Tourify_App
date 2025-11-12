import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';

import 'tour_model.dart';
import 'tour_repository.dart';

class TourRepositoryImpl implements TourRepository {
  TourRepositoryImpl() {
    _http = HttpClient(http.Client(), SecureStorageService());
  }

  late final HttpClient _http;

  @override
  Future<List<TourSummary>> getToursForHomePage({int limit = 20}) async {
    return _fetchSummaryList('/api/tours?limit=$limit');
  }

  @override
  Future<TourDetail> getTourDetails(String tourId) async {
    final res = await _http.get('/api/tours/$tourId');
    if (res.statusCode != 200) {
      throw Exception('Không thể tải chi tiết tour.');
    }
    final payload = json.decode(res.body);
    final map = _extractMap(payload);
    return TourDetail.fromJson(map);
  }

  @override
  Future<void> trackTourView(String tourId) async {
    try {
      final response = await _http.post('/api/tours/$tourId/view');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
    } catch (_) {
      // ignore tracking failures
    }
  }

  @override
  Future<TourReviewsResponse> fetchTourReviews(
    String tourId, {
    int page = 1,
    int perPage = 10,
  }) async {
    final res = await _http.get(
      '/api/tours/$tourId/reviews?page=$page&per_page=$perPage',
    );
    if (res.statusCode != 200) {
      throw Exception('Không thể tải đánh giá.');
    }
    final payload = json.decode(res.body);

    final reviewsContainer =
        (payload['reviews'] is Map) ? payload['reviews'] as Map : payload;
    final reviewItems =
        (reviewsContainer is Map ? reviewsContainer['data'] : reviewsContainer)
            as List? ??
        const [];
    final reviews =
        reviewItems
            .whereType<Map>()
            .map((e) => TourReview.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    final ratingBlock = payload['rating'] as Map?;
    final average =
        (ratingBlock?['average'] as num?)?.toDouble() ??
        (payload['rating_average'] as num?)?.toDouble() ??
        (payload['average'] as num?)?.toDouble() ??
        (reviews.isEmpty
            ? 0
            : reviews.map((e) => e.rating).fold<double>(0, (a, b) => a + b) /
                reviews.length);
    final count =
        (ratingBlock?['count'] as num?)?.toInt() ??
        (payload['rating_count'] as num?)?.toInt() ??
        (reviewsContainer is Map && reviewsContainer['meta'] is Map
            ? (reviewsContainer['meta']['total'] as num?)?.toInt()
            : null) ??
        reviews.length;

    return TourReviewsResponse(
      reviews: reviews,
      average: average,
      count: count,
    );
  }

  @override
  Future<List<TourSummary>> fetchSuggestedTours({
    String? excludeTourId,
    int limit = 6,
  }) async {
    final query = excludeTourId == null ? '' : '&exclude=$excludeTourId';
    final endpoint = '/api/tours/trending?limit=$limit$query';
    final list = await _fetchSummaryList(endpoint);
    if (excludeTourId == null) return list;
    return list.where((tour) => tour.id != excludeTourId).toList();
  }

  Future<List<TourSummary>> _fetchSummaryList(String endpoint) async {
    final res = await _http.get(endpoint);
    if (res.statusCode != 200) {
      throw Exception('Không thể tải danh sách tour.');
    }
    final payload = json.decode(res.body);
    final list = _extractList(payload);
    return list
        .whereType<Map>()
        .map((item) => TourSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      for (final key in ['data', 'items', 'tours', 'results', 'list']) {
        final value = payload[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      for (final key in ['data', 'tour']) {
        final value = payload[key];
        if (value is Map) return Map<String, dynamic>.from(value);
      }
      return payload;
    }
    throw Exception('Cấu trúc dữ liệu không hợp lệ.');
  }
}
