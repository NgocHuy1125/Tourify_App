import 'package:tourify_app/features/tour/model/tour_model.dart';

class WishlistItem {
  final String id;
  final TourSummary tour;
  final DateTime addedAt;
  final bool available;
  final String status;

  WishlistItem({
    required this.id,
    required this.tour,
    required this.addedAt,
    required this.available,
    required this.status,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return WishlistItem(
      id: (map['id'] ?? '').toString(),
      tour: TourSummary.fromJson(
        Map<String, dynamic>.from((map['tour'] as Map?) ?? const {}),
      ),
      addedAt:
          DateTime.tryParse(map['added_at']?.toString() ?? '') ??
          DateTime.now(),
      available: map['available'] == true,
      status: (map['status'] ?? '').toString(),
    );
  }
}
