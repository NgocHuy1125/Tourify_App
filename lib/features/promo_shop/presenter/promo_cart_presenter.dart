import 'package:flutter/foundation.dart';

import '../model/promo_models.dart';
import '../model/promo_repository.dart';

enum PromoCartState { initial, loading, success, error }

class PromoCartPresenter with ChangeNotifier {
  PromoCartPresenter(this._repository);

  final PromoRepository _repository;

  PromoCartState _state = PromoCartState.initial;
  PromoCartState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<PromoCartItem> _items = const [];
  List<PromoCartItem> get items => _items;

  PromoCartTotals _totals = const PromoCartTotals(
    subtotal: 0,
    discount: 0,
    shippingFee: 0,
    finalAmount: 0,
  );
  PromoCartTotals get totals => _totals;

  Future<void> loadCart() async {
    _state = PromoCartState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final cart = await _repository.fetchCart();
      _items = cart.items;
      _totals = cart.totals;
      _state = PromoCartState.success;
    } catch (e) {
      _state = PromoCartState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    _updateQuantity(productId, (current) => current + 1);
  }

  void decreaseQuantity(String productId) {
    _updateQuantity(productId, (current) => current > 1 ? current - 1 : current);
  }

  void removeItem(String productId) {
    _items = _items.where((item) => item.product.productId != productId).toList();
    _recalculateTotals();
    notifyListeners();
  }

  void _updateQuantity(String productId, int Function(int current) mutate) {
    final updated = <PromoCartItem>[];
    for (final item in _items) {
      if (item.product.productId == productId) {
        final nextQty = mutate(item.quantity);
        updated.add(
          PromoCartItem(
            product: item.product,
            quantity: nextQty,
            price: item.price,
            appliedPromotion: item.appliedPromotion,
          ),
        );
      } else {
        updated.add(item);
      }
    }
    _items = updated;
    _recalculateTotals();
    notifyListeners();
  }

  void _recalculateTotals() {
    final subtotal =
        _items.fold<double>(0, (sum, item) => sum + item.lineSubtotal);
    final discount = subtotal * 0.12;
    final shippingFee = subtotal >= 500000 ? 0 : 25000;
    final finalAmount = subtotal - discount + shippingFee;
    _totals = PromoCartTotals(
      subtotal: subtotal,
      discount: discount,
      shippingFee: shippingFee,
      finalAmount: finalAmount,
      bestPromotion: _totals.bestPromotion,
    );
  }
}
