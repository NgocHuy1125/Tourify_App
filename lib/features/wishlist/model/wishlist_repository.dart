import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/wishlist/model/wishlist_model.dart';

abstract class WishlistRepository {
  Future<List<WishlistItem>> fetchWishlist();
  Future<WishlistItem> addTour(String tourId);
  Future<void> removeWishlistItem(String wishlistItemId);
  Future<List<TourSummary>> fetchTrendingTours({int limit = 6});
}
