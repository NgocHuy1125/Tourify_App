import 'package:tourify_app/features/cart/model/cart_model.dart';

abstract class CartRepository {
  Future<CartData> fetchCart();
  Future<CartData> addItem({
    required String tourId,
    String? scheduleId,
    String? packageId,
    int adults = 1,
    int children = 0,
  });
  Future<CartData> updateItem({
    required String cartItemId,
    int? quantity,
    int? adults,
    int? children,
  });
  Future<CartData> deleteItem(String cartItemId);
}
