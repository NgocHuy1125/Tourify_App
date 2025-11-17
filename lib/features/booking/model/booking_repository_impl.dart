import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';
import 'package:tourify_app/features/booking/model/booking_model.dart';
import 'package:tourify_app/features/booking/model/booking_repository.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({HttpClient? httpClient})
    : _http = httpClient ?? HttpClient(http.Client(), SecureStorageService());

  final HttpClient _http;

  @override
  Future<List<BookingSummary>> fetchBookings({String? status}) async {
    final trimmed = status?.trim() ?? '';
    final query =
        trimmed.isNotEmpty
            ? '?status=${Uri.encodeQueryComponent(trimmed)}'
            : '';
    final response = await _http.get('/api/bookings$query');

    if (response.statusCode == 401) {
      throw Exception('Vui lòng đăng nhập để xem chuyến đi của bạn.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _extractErrorMessage(response.body) ??
          'Không thể tải danh sách chuyến đi.';
      throw Exception(message);
    }

    final body = response.body.trim();
    if (body.isEmpty) return const [];

    final decoded = json.decode(body);
    final list = _extractList(decoded);
    return list
        .whereType<Map>()
        .map((e) => BookingSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<BookingResponse> createBooking(BookingRequest request) async {
    final response = await _http.post('/api/bookings', body: request.toJson());
    final body = response.body;

    if (response.statusCode == 422) {
      final message =
          _extractErrorMessage(body) ?? 'Thông tin đặt tour không hợp lệ.';
      throw Exception(message);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _extractErrorMessage(body) ?? 'Không thể tạo đơn đặt tour.';
      throw Exception(message);
    }

    if (body.isEmpty) {
      throw Exception('Không nhận được phản hồi từ máy chủ.');
    }

    final payload = json.decode(body) as Map<String, dynamic>;
    return BookingResponse.fromJson(payload);
  }

  @override
  Future<TourReview> createReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final response = await _http.post(
      '/api/reviews',
      body: {
        'booking_id': bookingId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
    );

    if (response.statusCode != 201) {
      final message =
          _extractErrorMessage(response.body) ?? 'Không thể gửi đánh giá.';
      throw Exception(message);
    }

    final payload = json.decode(response.body);
    final reviewMap = (payload['review'] ?? payload) as Map;
    return TourReview.fromJson(Map<String, dynamic>.from(reviewMap));
  }

  @override
  Future<TourReview> updateReview(
    String reviewId, {
    int? rating,
    String? comment,
  }) async {
    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (comment != null) body['comment'] = comment;

    final response = await _http.put('/api/reviews/$reviewId', body: body);

    if (response.statusCode != 200) {
      final message =
          _extractErrorMessage(response.body) ?? 'Không thể cập nhật đánh giá.';
      throw Exception(message);
    }

    final payload = json.decode(response.body);
    final reviewMap = (payload['review'] ?? payload) as Map;
    return TourReview.fromJson(Map<String, dynamic>.from(reviewMap));
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    final response = await _http.delete('/api/reviews/$reviewId');

    if (response.statusCode != 200) {
      final message =
          _extractErrorMessage(response.body) ?? 'Không thể xóa đánh giá.';
      throw Exception(message);
    }
  }

  @override
  Future<BookingPaymentIntent> createPayLater(String bookingId) async {
    final response = await _http.post('/api/bookings/$bookingId/pay-later');
    if (response.statusCode == 401) {
      throw Exception('Vui lòng đăng nhập để thanh toán.');
    }
    if (response.statusCode == 422) {
      final message =
          _extractErrorMessage(response.body) ?? 'Không thể tạo link thanh toán.';
      throw Exception(message);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _extractErrorMessage(response.body) ?? 'Không thể tạo link thanh toán.';
      throw Exception(message);
    }
    final payload = json.decode(response.body) as Map<String, dynamic>;
    return BookingPaymentIntent.fromJson(payload);
  }

  @override
  Future<BookingPaymentIntent> fetchPaymentStatus(String bookingId) async {
    final response = await _http.get('/api/bookings/$bookingId/payment-status');
    if (response.statusCode == 401) {
      throw Exception('Vui lòng đăng nhập để kiểm tra thanh toán.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _extractErrorMessage(response.body) ??
          'Không thể kiểm tra trạng thái thanh toán.';
      throw Exception(message);
    }
    final payload = json.decode(response.body) as Map<String, dynamic>;
    return BookingPaymentIntent.fromJson(payload);
  }

  @override
  Future<RefundRequest> submitRefundRequest(
    String bookingId, {
    required String bankAccountName,
    required String bankAccountNumber,
    required String bankName,
    required String bankBranch,
    double? amount,
    String currency = 'VND',
    String? customerMessage,
  }) async {
    final body = {
      'bank_account_name': bankAccountName,
      'bank_account_number': bankAccountNumber,
      'bank_name': bankName,
      'bank_branch': bankBranch,
      if (amount != null) 'amount': amount,
      'currency': currency,
      if (customerMessage != null && customerMessage.trim().isNotEmpty)
        'customer_message': customerMessage,
    };

    final response =
        await _http.post('/api/bookings/$bookingId/refund-request', body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _extractErrorMessage(response.body) ??
          'Không thể gửi yêu cầu hoàn tiền.';
      throw Exception(message);
    }
    final payload = json.decode(response.body) as Map<String, dynamic>;
    final data = payload['refund'] ?? payload['data'] ?? payload;
    return RefundRequest.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> confirmRefundRequest(String refundRequestId) async {
    final response =
        await _http.post('/api/refund-requests/$refundRequestId/confirm');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _extractErrorMessage(response.body) ??
          'Không thể xác nhận hoàn tiền.';
      throw Exception(message);
    }
  }

  @override
  Future<BookingInvoice?> fetchInvoice(String bookingId) async {
    final response = await _http.get('/api/bookings/$bookingId/invoice');
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _extractErrorMessage(response.body) ??
          'Không thể tải thông tin hóa đơn.';
      throw Exception(message);
    }
    if (response.body.trim().isEmpty) return null;
    final payload = json.decode(response.body);
    if (payload == null) return null;
    final map =
        payload is Map<String, dynamic>
            ? payload
            : payload is Map
                ? Map<String, dynamic>.from(payload)
                : <String, dynamic>{};
    if (map.isEmpty) return null;
    return BookingInvoice.fromJson(map);
  }

  @override
  Future<BookingInvoice> requestInvoice(
    String bookingId, {
    required String customerName,
    required String taxCode,
    required String address,
    required String email,
    required String deliveryMethod,
  }) async {
    final response = await _http.post(
      '/api/bookings/$bookingId/invoice-request',
      body: {
        'customer_name': customerName,
        'customer_tax_code': taxCode,
        'customer_address': address,
        'customer_email': email,
        'delivery_method': deliveryMethod,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _extractErrorMessage(response.body) ??
          'Không thể gửi yêu cầu hóa đơn.';
      throw Exception(message);
    }
    final payload = json.decode(response.body) as Map<String, dynamic>;
    final data = payload['invoice'] ?? payload['data'] ?? payload;
    return BookingInvoice.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<BookingCancellationResult> cancelBooking(String bookingId) async {
    final response = await _http.post('/api/bookings/$bookingId/cancel');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _extractErrorMessage(response.body) ?? 'Không thể hủy tour.';
      throw Exception(message);
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      return BookingCancellationResult(message: 'Đã hủy tour.');
    }

    final decoded = json.decode(body);
    final map =
        decoded is Map<String, dynamic>
            ? decoded
            : decoded is Map
                ? Map<String, dynamic>.from(decoded.cast())
                : <String, dynamic>{};
    final message = map['message']?.toString() ?? 'Đã hủy tour.';
    BookingRefundInfo? refund;
    final refundMap = map['refund'];
    if (refundMap is Map) {
      refund = BookingRefundInfo.fromJson(
        Map<String, dynamic>.from(refundMap),
      );
    }
    return BookingCancellationResult(message: message, refund: refund);
  }

  String? _extractErrorMessage(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return null;

    dynamic probe(dynamic value) {
      if (value is Map) {
        for (final key in ['message', 'error', 'detail', 'title']) {
          final candidate = value[key];
          if (candidate is String && candidate.trim().isNotEmpty) {
            return candidate.trim();
          }
        }
        for (final nested in value.values) {
          final result = probe(nested);
          if (result is String && result.trim().isNotEmpty) {
            return result.trim();
          }
        }
      } else if (value is Iterable) {
        for (final element in value) {
          final result = probe(element);
          if (result is String && result.trim().isNotEmpty) {
            return result.trim();
          }
        }
      } else if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      return null;
    }

    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        final decoded = json.decode(trimmed);
        final message = probe(decoded);
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      } catch (_) {
        // ignore JSON parse errors
      }
    }

    return trimmed;
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      for (final key in ['data', 'items', 'results', 'bookings', 'list']) {
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
