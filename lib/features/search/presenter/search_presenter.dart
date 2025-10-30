import 'package:flutter/foundation.dart';
import '../../../domain/entities/tour.dart';
import '../../../domain/repositories/tour_repository.dart';

class SearchState {
  final bool loading;
  final String? error;
  final List<Tour> items;
  const SearchState({this.loading=false, this.error, this.items=const []});

  SearchState copy({bool? loading, String? error, List<Tour>? items}) => 
    SearchState(loading: loading ?? this.loading, error: error, items: items ?? this.items);
}

class SearchPresenter extends ChangeNotifier {
  final TourRepository repo;
  SearchState state = const SearchState();
  SearchPresenter(this.repo);

  Future<void> search({String? q}) async {
    state = state.copy(loading: true, error: null); notifyListeners();
    try {
      final data = await repo.search(q: q);
      state = state.copy(loading: false, items: data); notifyListeners();
    } catch (e) {
      state = state.copy(loading: false, error: e.toString()); notifyListeners();
    }
  }
}
