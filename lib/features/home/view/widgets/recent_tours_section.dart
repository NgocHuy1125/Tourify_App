import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/features/home/model/home_models.dart';
import 'package:tourify_app/features/home/presenter/home_presenter.dart';
import 'package:tourify_app/features/tour/view/tour_detail_page.dart';

class RecentToursSection extends StatelessWidget {
  const RecentToursSection({
    super.key,
    required this.items,
    required this.isLoading,
    required this.message,
  });

  final List<RecentTourItem> items;
  final bool isLoading;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Đã xem gần đây',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: Builder(
            builder: (context) {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (items.isEmpty) {
                return _RecentEmptyState(message: message);
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _RecentTourCard(item: item);
                },
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemCount: items.length,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentTourCard extends StatelessWidget {
  const _RecentTourCard({required this.item});

  final RecentTourItem item;

  @override
  Widget build(BuildContext context) {
    final tour = item.tour;
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final priceText = tour.displayPrice > 0
        ? currency.format(tour.displayPrice)
        : 'Liên hệ để nhận giá';
    final hasDiscount = tour.displayPrice < tour.priceFrom;

    final viewedAt = _formatViewedAt(item.viewedAt);
    final viewCount = NumberFormat.decimalPattern('vi_VN').format(
      item.viewCount > 0 ? item.viewCount : 1,
    );

    return SizedBox(
      width: 190,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (tour.id.isEmpty) return;
            final presenter = context.read<HomePresenter>();
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TourDetailPage(id: tour.id)),
            );
            await presenter.refreshRecentTours();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 2,
                  child: _CoverImage(url: tour.mediaCover),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _InfoRow(
                          icon: Icons.visibility_outlined,
                          label: '$viewCount lượt xem',
                        ),
                        const SizedBox(height: 2),
                        _InfoRow(
                          icon: Icons.history,
                          label: viewedAt,
                        ),
                        const Spacer(),
                        Text(
                          priceText,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4E54C8),
                          ),
                        ),
                        if (hasDiscount)
                          Text(
                            currency.format(tour.priceFrom),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        if (tour.hasAutoPromotion)
                          Text(
                            tour.autoPromotion?.description ??
                                'Giảm ${currency.format(tour.autoPromotion!.discountAmount)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFF5B00),
                              fontSize: 11,
                            ),
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

  String _formatViewedAt(DateTime? value) {
    if (value == null) return 'Vừa xem';
    final local = value.toLocal();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return 'Xem lúc ${formatter.format(local)}';
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentEmptyState extends StatelessWidget {
  const _RecentEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final displayMessage =
        message.isNotEmpty
            ? message
            : 'Chưa có tour nào trong lịch sử xem gần đây.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 6),
            if (message.isEmpty)
              Text(
                'Khám phá thêm và mở tour để lưu vào danh sách này nhé!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
