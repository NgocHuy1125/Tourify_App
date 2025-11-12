import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tourify_app/features/tour/model/tour_model.dart';

class TourCardPriceBlock extends StatelessWidget {
  const TourCardPriceBlock({
    super.key,
    required this.tour,
    required this.formatter,
  });

  final TourSummary tour;
  final NumberFormat formatter;

  static const Color _primaryPriceColor = Color(0xFFE53935);
  static const Color _promotionBadgeColor = Color(0xFFFFF2E8);
  static const Color _promotionTextColor = Color(0xFFFF5B00);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceText =
        tour.displayPrice > 0
            ? 'Từ ${formatter.format(tour.displayPrice)}'
            : 'Giá đang cập nhật';
    final hasDiscount = tour.displayPrice > 0 && tour.displayPrice < tour.priceFrom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                priceText,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _primaryPriceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (hasDiscount)
              Text(
                formatter.format(tour.priceFrom),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black38,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        if (tour.hasAutoPromotion)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _promotionBadgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _promotionLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _promotionTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _promotionLabel() {
    final promotion = tour.autoPromotion;
    if (promotion == null) return '';
    final discountText =
        promotion.discountAmount > 0
            ? formatter.format(promotion.discountAmount)
            : '${promotion.value}${promotion.discountType == 'percent' ? '%' : ''}';
    final code = promotion.code.isNotEmpty ? promotion.code : 'Ưu đãi';
    return '$code • giảm $discountText';
  }
}
