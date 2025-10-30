import 'package:flutter/foundation.dart';
import 'package:tourify_app/features/cart/model/cart_model.dart';
import 'package:tourify_app/features/cart/model/cart_repository.dart';

enum CartState { initial, loading, success, error }

class CartEntry {
  CartItem item;
  bool selected;
  CartEntry({required this.item, this.selected = false});
}

class CartPresenter with ChangeNotifier {
  final CartRepository _repository;
  CartPresenter(this._repository);

  CartState _state = CartState.initial;
  CartState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<CartEntry> _entries = [];
  List<CartEntry> get entries => _entries;

  double _totalPrice = 0;
  double get totalPrice => _totalPrice;

  Future<void> loadCart({bool showLoading = true}) async {
    _errorMessage = '';
    if (showLoading) {
      _state = CartState.loading;
      notifyListeners();
    }
    try {
      final data = await _repository.fetchCart();
      _applyData(data);
      _state = CartState.success;
    } catch (e) {
      _state = CartState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void toggleSelectAll(bool value) {
    for (final entry in _entries) {
      entry.selected = value;
    }
    notifyListeners();
  }

  void toggleItem(String id, bool value) {
    for (final entry in _entries) {
      if (entry.item.id == id) {
        entry.selected = value;
        notifyListeners();
        break;
      }
    }
  }

  bool get isAllSelected =>
      _entries.isNotEmpty && _entries.every((e) => e.selected);

  int get selectedCount => _entries.where((e) => e.selected).length;

  int get selectedQuantity =>
      _entries
          .where((e) => e.selected)
          .fold<int>(
            0,
            (sum, entry) =>
                sum + (entry.item.quantity > 0 ? entry.item.quantity : 1),
          );

  int get totalItems =>
      _entries.fold(0, (sum, entry) => sum + entry.item.quantity);

  double get selectedTotal =>
      _entries.where((e) => e.selected).fold(0, (sum, entry) {
        final item = entry.item;
        if (item.price != 0) {
          return sum + item.price;
        }
        final subtotal = item.adultSubtotal + item.childSubtotal;
        if (subtotal != 0) {
          return sum + subtotal;
        }
        final basePrice = item.tour?.priceFrom ?? 0;
        final passengers = item.adults + item.children;
        final fallbackTotal =
            (passengers > 0 ? passengers : item.quantity) * basePrice;
        return sum + fallbackTotal;
      });

  double get effectiveTotal {
    final total = selectedTotal;
    if (total == 0 && _entries.isNotEmpty && selectedCount == _entries.length) {
      return _totalPrice;
    }
    return total;
  }

  Future<void> increaseQuantity(CartItem item) async {
    final currentAdults = item.adults > 0 ? item.adults : item.quantity;
    final nextAdults = currentAdults + 1;
    final nextQuantity = nextAdults + item.children;
    await _updateItemCounts(
      item,
      adults: nextAdults,
      children: item.children,
      quantity: nextQuantity,
    );
  }

  Future<void> decreaseQuantity(CartItem item) async {
    var adults = item.adults > 0 ? item.adults : item.quantity;
    var children = item.children;
    final totalPassengers = adults + children;
    if (totalPassengers <= 1) {
      await removeItem(item.id);
      return;
    }
    if (adults > 0) {
      adults -= 1;
    } else if (children > 0) {
      children -= 1;
    }
    final nextQuantity = adults + children;
    await _updateItemCounts(
      item,
      adults: adults,
      children: children,
      quantity: nextQuantity,
    );
  }

  Future<void> _updateItemCounts(
    CartItem item, {
    int? adults,
    int? children,
    int? quantity,
  }) async {
    try {
      final payloadQuantity =
          quantity ?? ((adults ?? item.adults) + (children ?? item.children));
      final data = await _repository.updateItem(
        cartItemId: item.id,
        adults: adults,
        children: children,
        quantity: payloadQuantity > 0 ? payloadQuantity : null,
      );
      _applyData(data, preserveSelection: true);
      _state = CartState.success;
    } catch (e) {
      _state = CartState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> removeItem(String id) async {
    try {
      final data = await _repository.deleteItem(id);
      _applyData(data);
      _state = CartState.success;
    } catch (e) {
      _state = CartState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> addItemToCart({
    required String tourId,
    String? scheduleId,
    String? packageId,
    int adults = 1,
    int children = 0,
  }) async {
    try {
      final data = await _repository.addItem(
        tourId: tourId,
        scheduleId: scheduleId,
        packageId: packageId,
        adults: adults,
        children: children,
      );
      _applyData(data, preserveSelection: true);
      _state = CartState.success;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _state = CartState.error;
    }
    notifyListeners();
  }

  void _applyData(CartData data, {bool preserveSelection = false}) {
    final oldSelections = {
      for (final entry in _entries) entry.item.id: entry.selected,
    };
    _entries =
        data.items
            .map(
              (item) => CartEntry(
                item: item,
                selected:
                    preserveSelection && oldSelections.containsKey(item.id)
                        ? oldSelections[item.id]!
                        : true,
              ),
            )
            .toList();
    _totalPrice = data.totalPrice;
  }
}
