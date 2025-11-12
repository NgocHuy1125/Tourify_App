import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tourify_app/features/home/view/widgets/tour_card_price_block.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class TourCardLarge extends StatelessWidget {
  const TourCardLarge({super.key, required this.tour, this.onTap});

  final TourSummary tour;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination =
        tour.destination.isNotEmpty
            ? tour.destination
            : 'Địa điểm chưa xác định';

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(aspectRatio: 4 / 3, child: _buildCoverImage()),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tour.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRatingRow(theme),
                    const SizedBox(height: 8),
                    TourCardPriceBlock(
                      tour: tour,
                      formatter: formatter,
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

  Widget _buildRatingRow(ThemeData theme) {
    final rating = (tour.ratingAvg ?? 4.8).clamp(0, 5);
    final reviews = tour.reviewsCount > 0 ? tour.reviewsCount : 1701;
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.orange, size: 16),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1), style: theme.textTheme.bodySmall),
        const SizedBox(width: 4),
        Text(
          '(${reviews.toString()})',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCoverImage() {
    final cover = tour.mediaCover;
    if (cover == null || cover.isEmpty) {
      return Container(
        color: const Color(0xFFF2F2F2),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Image.network(
      cover,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => Container(
            color: const Color(0xFFF2F2F2),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 32,
                color: Colors.grey,
              ),
            ),
          ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFF2F2F2),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

}
