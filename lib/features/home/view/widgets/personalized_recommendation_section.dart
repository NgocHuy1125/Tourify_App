import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tourify_app/features/home/model/home_models.dart';
import 'package:tourify_app/features/home/presenter/home_presenter.dart';
import 'package:tourify_app/features/tour/view/tour_detail_page.dart';

class PersonalizedRecommendationSection extends StatelessWidget {
  const PersonalizedRecommendationSection({super.key, required this.presenter});

  final HomePresenter presenter;

  @override
  Widget build(BuildContext context) {
    final recommendations = presenter.recommendations;
    final isLoading =
        presenter.recommendationsLoading &&
        presenter.state == HomeState.loading;
    final message = presenter.recommendationsMessage;
    final meta = presenter.recommendationsMeta;
    final showPersonalized =
        meta.personalizedResults && recommendations.isNotEmpty;
    final generatedAt = meta.generatedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tour dành cho bạn', // Đã sửa: 'Tour dành cho bạn'
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (showPersonalized)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Đã cá nhân hóa', // Đã sửa: 'Đã cá nhân hóa'
                        style: TextStyle(
                          color: Color(0xFFFF5B00),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (showPersonalized) const SizedBox(width: 8),
                  if (generatedAt != null)
                    Text(
                      'Cập nhật ', // Đã sửa: 'Cập nhật '
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (recommendations.isEmpty)
          _EmptyRecommendation(message: message)
        else
          SizedBox(
            height: 350,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final item = recommendations[index];
                return _RecommendationCard(
                  item: item,
                  onTap: () => _openDetail(context, item),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemCount: recommendations.length,
            ),
          ),
      ],
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    RecommendationItem item,
  ) async {
    if (item.tour.id.isEmpty) return;
    presenter.trackRecommendationClick(item);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TourDetailPage(id: item.tour.id)));
    await presenter.refreshRecentTours();
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onTap});

  final RecommendationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tour = item.tour;
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final reasons = item.reasonBadges(limit: 2);

    return SizedBox(
      width: 260,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.1,
                  ), // Sử dụng withOpacity
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: _CoverImage(url: tour.mediaCover),
                    ),
                    if (reasons.isNotEmpty)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        right: 8,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              reasons
                                  .map(
                                    (reason) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        reason,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4E54C8),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tour.destination.isNotEmpty
                                    ? tour.destination
                                    : 'Địa điểm đang cập nhật', // Đã sửa
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tour.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tour.duration > 0
                                  ? '${tour.duration} ngày' // Đã sửa
                                  : 'Lịch trình linh hoạt', // Đã sửa
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tour.displayPrice > 0
                                  ? formatter.format(tour.displayPrice)
                                  : 'Liên hệ để nhận giá', // Đã sửa
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4E54C8),
                              ),
                            ),
                            if (tour.displayPrice < tour.priceFrom)
                              Text(
                                formatter.format(tour.priceFrom),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            if (tour.hasAutoPromotion)
                              Text(
                                tour.autoPromotion?.description ??
                                    'Giảm ${formatter.format(tour.autoPromotion!.discountAmount)}', // Đã sửa
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFFFF5B00),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: const Color(0xFFF2F2F2),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFF2F2F2),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFF2F2F2),
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        );
      },
    );
  }
}

class _EmptyRecommendation extends StatelessWidget {
  const _EmptyRecommendation({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final displayMessage =
        message.isNotEmpty
            ? message
            : 'Hãy xem và thêm một vài tour vào yêu thích để gợi ý chính xác hơn.'; // Đã sửa
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF4E54C8)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4E54C8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
