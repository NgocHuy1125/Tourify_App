import 'tour_model.dart';

abstract class TourRepository {
  Future<List<TourSummary>> getToursForHomePage({int limit = 20});
  Future<TourDetail> getTourDetails(String tourId);
  Future<void> trackTourView(String tourId);
  Future<TourReviewsResponse> fetchTourReviews(
    String tourId, {
    int page = 1,
    int perPage = 10,
  });
  Future<List<TourSummary>> fetchSuggestedTours({
    String? excludeTourId,
    int limit = 6,
  });
}
