import '../entities/tour.dart';

abstract class TourRepository {
  Future<List<Tour>> search({String? q, int? minPrice, int? maxPrice});
  Future<Tour> detail(String id);
}
