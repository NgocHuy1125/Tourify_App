import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';
import 'package:tourify_app/features/cart/model/cart_model.dart';
import 'package:tourify_app/features/cart/model/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  final HttpClient _http;

  CartRepositoryImpl({HttpClient? httpClient})
    : _http = httpClient ?? HttpClient(http.Client(), SecureStorageService());

  @override
  Future<CartData> fetchCart() async {
    final response = await _http.get('/api/cart');
    // Debug log (tạm thời để xác định cấu trúc JSON trả về)
    // Lưu ý: sau khi kiểm tra xong nên gỡ bỏ hoặc chuyển sang logger bảo mật hơn.
    // ignore: avoid_print
    print('GET /api/cart -> ${response.statusCode}');
    // ignore: avoid_print
    print(response.body);

    _ensureSuccess(response, {200}, 'Không thể tải giỏ hàng');
    final payload = jsonDecode(response.body);
    return CartData.fromJson(_extractCartMap(payload));
  }

  @override
  Future<CartData> addItem({
    required String tourId,
    String? scheduleId,
    String? packageId,
    int adults = 1,
    int children = 0,
  }) async {
    final body = <String, dynamic>{
      'tour_id': tourId,
      if (scheduleId != null && scheduleId.isNotEmpty)
        'schedule_id': scheduleId,
      if (packageId != null && packageId.isNotEmpty) 'package_id': packageId,
      'adults': adults,
      'children': children,
    };
    final response = await _http.post('/api/cart/items', body: body);
    _ensureSuccess(response, {200, 201}, 'Không thể thêm tour vào giỏ hàng');
    final payload = jsonDecode(response.body);
    return CartData.fromJson(_extractCartMap(payload));
  }

  @override
  Future<CartData> updateItem({
    required String cartItemId,
    int? quantity,
    int? adults,
    int? children,
  }) async {
    final body = <String, dynamic>{
      if (quantity != null) 'quantity': quantity,
      if (adults != null) 'adults': adults,
      if (children != null) 'children': children,
    };
    final response = await _http.put('/api/cart/items/$cartItemId', body: body);
    _ensureSuccess(response, {200}, 'Không thể cập nhật giỏ hàng');
    final payload = jsonDecode(response.body);
    return CartData.fromJson(_extractCartMap(payload));
  }

  @override
  Future<CartData> deleteItem(String cartItemId) async {
    final response = await _http.delete('/api/cart/items/$cartItemId');
    if (response.statusCode == 204 ||
        (response.statusCode == 200 && response.body.isEmpty)) {
      // Backend không trả CartData -> gọi lại fetchCart để đồng bộ
      return fetchCart();
    }
    _ensureSuccess(response, {200}, 'Không thể xóa tour khỏi giỏ hàng');
    final payload = jsonDecode(response.body);
    return CartData.fromJson(_extractCartMap(payload));
  }

  Map<String, dynamic> _extractCartMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      if (_isCartMap(payload)) return payload;

      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        if (_isCartMap(data)) return data;
        final cart = data['cart'];
        if (cart is Map<String, dynamic>) {
          return Map<String, dynamic>.from(cart);
        }
      }

      final cart = payload['cart'];
      if (cart is Map<String, dynamic>) {
        return Map<String, dynamic>.from(cart);
      }
    }

    throw Exception('Không tìm thấy dữ liệu giỏ hàng hợp lệ trong phản hồi.');
  }

  bool _isCartMap(Map<String, dynamic> map) {
    return map.containsKey('items') ||
        map.containsKey('cart_items') ||
        map.containsKey('cartItems');
  }

  void _ensureSuccess(
    http.Response response,
    Set<int> expectedStatusCodes,
    String message,
  ) {
    if (!expectedStatusCodes.contains(response.statusCode)) {
      throw Exception('$message (HTTP ${response.statusCode})');
    }
  }
}
