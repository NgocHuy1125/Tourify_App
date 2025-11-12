import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tourify_app/features/tour/model/tour_model.dart';

class TourCard extends StatelessWidget {
  const TourCard({super.key, required this.tour});

  final TourSummary tour;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final hasDiscount = tour.displayPrice < tour.priceFrom;
    final priceText =
        tour.displayPrice > 0
            ? formatter.format(tour.displayPrice)
            : 'Giá đang cập nhật';

    return GestureDetector(
      onTap: () {
        debugPrint('Tapped on tour: ${tour.title}');
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 3,
                child: Image.network(
                  tour.mediaCover ??
                      'https://via.placeholder.com/150x100.png?text=Tourify',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    tour.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFFFF5B00),
                      ),
                    ),
                    if (hasDiscount)
                      Text(
                        formatter.format(tour.priceFrom),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (tour.hasAutoPromotion)
                      Text(
                        tour.autoPromotion?.description ??
                            'Giảm ${formatter.format(tour.autoPromotion!.discountAmount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF5B00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
