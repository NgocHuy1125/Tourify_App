import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class HeroCarousel extends StatelessWidget {
  final TourDetail detail;

  const HeroCarousel({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final media = detail.media.isNotEmpty
        ? detail.media
        : ['https://via.placeholder.com/800x500?text=Tour'];

    return Stack(
      children: [
        PageView.builder(
          itemCount: media.length,
          itemBuilder: (_, index) {
            final url = media[index];
            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 48),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${media.length} ảnh',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class TourDetailHeader extends StatelessWidget {
  final TourDetail detail;
  final TourReviewsResponse reviews;

  const TourDetailHeader({
    super.key,
    required this.detail,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final rating = reviews.average;
    final ratingCount = reviews.count;
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: detail.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(color: Color(0xFFFF5B00)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 12),
          Text(
            detail.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: Color(0xFFFFB400)),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFB400),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($ratingCount đánh giá)',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  detail.destination.isNotEmpty
                      ? detail.destination
                      : 'Đang cập nhật địa điểm',
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (detail.description.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detail.description, style: const TextStyle(height: 1.4)),
                  TextButton(
                    onPressed: () => _showDescriptionDialog(context, detail),
                    child: const Text('Xem thêm'),
                  ),
                ],
              ),
            ),
          if (detail.bookingsCount != null) ...[
            const SizedBox(height: 12),
            Text(
              'Đã có ${detail.bookingsCount} lượt đặt',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          if (detail.basePrice > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Giá cơ bản: ${currency.format(detail.basePrice)}',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDescriptionDialog(BuildContext context, TourDetail detail) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(detail.title),
        content: SingleChildScrollView(child: Text(detail.description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
