import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';
import 'package:tourify_app/features/booking/model/booking_model.dart';
import 'package:tourify_app/features/booking/model/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final HttpClient _http;

  BookingRepositoryImpl({HttpClient? httpClient})
    : _http = httpClient ?? HttpClient(http.Client(), SecureStorageService());

  @override
  Future<BookingResponse> createBooking(BookingRequest request) async {
    final response = await _http.post('/api/bookings', body: request.toJson());
    final body = response.body;

    if (response.statusCode == 422) {
      final message =
          _extractErrorMessage(body) ??
          'Th\u00f4ng tin \u0111\u1eb7t tour kh\u00f4ng h\u1ee3p l\u1ec7.';
      throw Exception(message);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _extractErrorMessage(body) ??
          'Kh\u00f4ng th\u1ec3 t\u1ea1o \u0111\u01a1n \u0111\u1eb7t tour.';
      throw Exception(message);
    }

    if (body.isEmpty) {
      throw Exception(
        'Kh\u00f4ng nh\u1eadn \u0111\u01b0\u1ee3c ph\u1ea3n h\u1ed3i t\u1eeb m\u00e1y ch\u1ee7.',
      );
    }

    final payload = json.decode(body) as Map<String, dynamic>;
    return BookingResponse.fromJson(payload);
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
}
