import 'package:flutter/foundation.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/wishlist/model/wishlist_model.dart';
import 'package:tourify_app/features/wishlist/model/wishlist_repository.dart';

enum WishlistState { initial, loading, success, empty, error }

class WishlistPresenter with ChangeNotifier {
  final WishlistRepository _repository;

  WishlistPresenter(this._repository);

  WishlistState _state = WishlistState.initial;
  WishlistState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<WishlistItem> _items = [];
  List<WishlistItem> get items => _items;
  List<TourSummary> _trendingTours = [];
  List<TourSummary> get trendingTours => _trendingTours;
  bool _isTrendingLoading = false;
  bool get isTrendingLoading => _isTrendingLoading;
  bool _isOnboarding = false;
  bool get isOnboarding => _isOnboarding;
  final Set<String> _compareSelection = <String>{};

  Set<String> get compareSelection => _compareSelection;
  int get compareCount => _compareSelection.length;
  bool get hasCompareSelection => _compareSelection.isNotEmpty;
  bool get canCompare => _compareSelection.length == 2;
  bool get isCompareLimitReached => _compareSelection.length >= 2;

  bool isSelectedForCompare(String tourId) =>
      _compareSelection.contains(tourId);

  Future<void> loadWishlist() async {
    _state = WishlistState.loading;
    _errorMessage = '';
    _isOnboarding = false;
    notifyListeners();
    try {
      _items = await _repository.fetchWishlist();
      _compareSelection.removeWhere(
        (tourId) => !_items.any((item) => item.tour.id == tourId),
      );
      if (_items.isEmpty) {
        _state = WishlistState.empty;
      } else {
        _state = WishlistState.success;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = WishlistState.error;
    }
    notifyListeners();
  }

  Future<void> addTour(String tourId) async {
    try {
      final item = await _repository.addTour(tourId);
      _items.insert(0, item);
      if (_state == WishlistState.empty && _isOnboarding) {
        // stay in onboarding, just refresh UI
        notifyListeners();
        return;
      }
      _state = WishlistState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = WishlistState.error;
    }
    notifyListeners();
  }

  Future<void> removeItem(String wishlistItemId) async {
    final original = List<WishlistItem>.from(_items);
    _items.removeWhere((item) => item.id == wishlistItemId);
    _compareSelection.removeWhere(
      (tourId) => !_items.any((item) => item.tour.id == tourId),
    );
    if (_items.isEmpty) {
      if (_isOnboarding) {
        _state = WishlistState.empty;
      } else {
        _state = WishlistState.empty;
        _isOnboarding = false;
      }
    }
    notifyListeners();
    try {
      await _repository.removeWishlistItem(wishlistItemId);
    } catch (e) {
      _items = original;
      _errorMessage = e.toString();
      _state = WishlistState.error;
      notifyListeners();
    }
  }

  Future<void> toggleFavouriteByTour(TourSummary tour) async {
    final existing = _items.where((item) => item.tour.id == tour.id).toList();
    if (existing.isNotEmpty) {
      await removeItem(existing.first.id);
    } else {
      await addTour(tour.id);
    }
  }

  bool isTourFavourited(String tourId) {
    return _items.any((item) => item.tour.id == tourId);
  }

  void showSavedList() {
    _isOnboarding = false;
    _state = _items.isNotEmpty ? WishlistState.success : WishlistState.empty;
    notifyListeners();
  }

  Future<void> beginOnboarding() async {
    if (_isOnboarding) return;
    _isOnboarding = true;
    if (_trendingTours.isEmpty && !_isTrendingLoading) {
      await _loadTrendingTours();
    } else {
      notifyListeners();
    }
  }

  bool toggleCompareSelection(String tourId) {
    if (_compareSelection.contains(tourId)) {
      _compareSelection.remove(tourId);
      notifyListeners();
      return true;
    }
    if (_compareSelection.length >= 2) {
      return false;
    }
    _compareSelection.add(tourId);
    notifyListeners();
    return true;
  }

  void clearCompareSelection() {
    if (_compareSelection.isEmpty) return;
    _compareSelection.clear();
    notifyListeners();
  }

  Future<List<TourDetail>> compareSelectedTours() async {
    if (_compareSelection.isEmpty) return const [];
    final ids = _compareSelection.take(2).toList();
    try {
      return await _repository.compareTours(ids);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<void> refreshTrendingTours({int limit = 6}) async {
    await _loadTrendingTours(limit: limit);
  }

  Future<void> _loadTrendingTours({int limit = 6}) async {
    _isTrendingLoading = true;
    notifyListeners();
    try {
      _trendingTours = await _repository.fetchTrendingTours(limit: limit);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isTrendingLoading = false;
      notifyListeners();
    }
  }
}
