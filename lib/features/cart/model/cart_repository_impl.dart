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
    _ensureSuccess(response, {200}, 'Không thể tải giỏ hàng');
    final payload = jsonDecode(response.body);
    return CartData.fromJson(_extractMap(payload));
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
    return CartData.fromJson(_extractMap(payload));
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
    return CartData.fromJson(_extractMap(payload));
  }

  @override
  Future<CartData> deleteItem(String cartItemId) async {
    final response = await _http.delete('/api/cart/items/$cartItemId');
    // SỬA ĐỔI: Xử lý 204 (No Content) hoặc 200 (OK) với body rỗng
    if (response.statusCode == 204 ||
        (response.statusCode == 200 && response.body.isEmpty)) {
      return fetchCart();
    }
    _ensureSuccess(response, {200}, 'Không thể xóa tour khỏi giỏ hàng');
    final payload = jsonDecode(response.body);
    return CartData.fromJson(_extractMap(payload));
  }

  // SỬA ĐỔI: Logic _extractMap đơn giản và chặt chẽ hơn
  Map<String, dynamic> _extractMap(dynamic payload) {
    if (payload is! Map) {
      throw Exception(
        'Dữ liệu giỏ hàng không đúng định dạng (không phải Map).',
      );
    }

    final map = Map<String, dynamic>.from(payload);

    // Ưu tiên 1: { "data": { "cart": { ... } } }
    final data = map['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      final cart = dataMap['cart'];
      if (cart is Map) {
        return Map<String, dynamic>.from(cart);
      }
      // Ưu tiên 2: { "data": { ... } } (nếu data là giỏ hàng)
      if (_isCartMap(dataMap)) {
        return dataMap;
      }
    }

    // Ưu tiên 3: { "cart": { ... } }
    final cart = map['cart'];
    if (cart is Map) {
      return Map<String, dynamic>.from(cart);
    }

    // Ưu tiên 4: { ... } (root là giỏ hàng)
    if (_isCartMap(map)) {
      return map;
    }

    throw Exception('Không tìm thấy dữ liệu giỏ hàng trong phản hồi.');
  }

  // SỬA ĐỔI: Đổi tên _looksLikeCart -> _isCartMap và làm chặt chẽ hơn
  // Giỏ hàng BẮT BUỘC phải có 'items' hoặc 'cart_items'
  bool _isCartMap(Map<String, dynamic> map) {
    return map.containsKey('items') || map.containsKey('cart_items');
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
