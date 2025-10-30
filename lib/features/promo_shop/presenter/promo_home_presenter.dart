import 'package:flutter/foundation.dart';

import '../model/promo_models.dart';
import '../model/promo_repository.dart';

enum PromoHomeState { initial, loading, success, error }

class PromoHomePresenter with ChangeNotifier {
  PromoHomePresenter(this._repository);

  final PromoRepository _repository;

  PromoHomeState _state = PromoHomeState.initial;
  PromoHomeState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  PromoHomeData _data = const PromoHomeData();
  PromoHomeData get data => _data;

  Future<void> load() async {
    _state = PromoHomeState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _data = await _repository.fetchHome();
      _state = PromoHomeState.success;
    } catch (e) {
      _state = PromoHomeState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
