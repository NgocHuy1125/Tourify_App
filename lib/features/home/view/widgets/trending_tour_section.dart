import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourify_app/features/home/view/widgets/section_header.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class TrendingTourSection extends StatelessWidget {
  final List<TourSummary> tours;
  const TrendingTourSection({super.key, required this.tours});

  @override
  Widget build(BuildContext context) {
    if (tours.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Tour nổi bật'),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) => _TrendingCard(tour: tours[index]),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: tours.length,
          ),
        ),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final TourSummary tour;
  const _TrendingCard({required this.tour});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final destination =
        tour.destination.isNotEmpty ? tour.destination : 'Điểm đến khác';
    final bool hasPrice = tour.priceFrom > 0;
    final priceText =
        hasPrice ? formatter.format(tour.priceFrom) : 'Giá đang cập nhật';
    final bookings = tour.bookingsCount;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              tour.mediaCover ??
                  'https://via.placeholder.com/240x135.png?text=Tour',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  destination,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  tour.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (bookings != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$bookings lượt đặt',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                Text(
                  hasPrice ? 'Từ $priceText' : priceText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
