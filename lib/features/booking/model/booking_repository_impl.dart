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
    final res = await _http.post('/api/bookings', body: request.toJson());
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Không thể tạo đơn đặt tour.');
    }
    final payload = json.decode(res.body) as Map<String, dynamic>;
    return BookingResponse.fromJson(payload);
  }
}
