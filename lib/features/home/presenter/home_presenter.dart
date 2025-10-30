import 'package:flutter/foundation.dart';
import '/features/tour/model/tour_model.dart';
import '/features/home/model/home_models.dart';
import '/features/home/model/home_repository.dart';

enum HomeState { initial, loading, success, error }

class HomePresenter with ChangeNotifier {
  final HomeRepository _repository;

  HomePresenter(this._repository);

  HomeState _state = HomeState.initial;
  HomeState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<TourSummary> _tours = [];
  List<TourSummary> get tours => _tours;

  List<PromotionItem> _promotions = [];
  List<PromotionItem> get promotions => _promotions;

  List<TourSummary> _trendingTours = [];
  List<TourSummary> get trendingTours => _trendingTours;

  Future<void> fetchHome() async {
    _state = HomeState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _promotions = await _repository.fetchActivePromotions(limit: 6);
    } catch (_) {
      _promotions = [];
    }

    try {
      _tours = await _repository.fetchAllTours();
    } catch (e) {
      _errorMessage = e.toString();
      _state = HomeState.error;
      notifyListeners();
      return;
    }

    try {
      _trendingTours = await _repository.fetchTrendingTours(limit: 8, days: 30);
    } catch (_) {
      _trendingTours = [];
    }

    _state = HomeState.success;
    notifyListeners();
  }
}
