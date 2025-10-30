import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

import 'tour_booking_sheet.dart';

class SectionAnchor extends StatelessWidget {
  final Widget child;

  const SectionAnchor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(top: 12), child: child);
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String description;

  const SectionTitle({super.key, required this.title, this.description = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: Colors.black54)),
        ],
      ],
    );
  }
}

class ServiceSection extends StatelessWidget {
  final TourDetail detail;
  const ServiceSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final packages = detail.packages.where((pkg) => pkg.isActive).toList();
    final schedules = detail.schedules;

    if (packages.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: const Text('Chưa có gói dịch vụ cho tour này.'),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Các gói dịch vụ',
            description: 'Chọn dịch vụ và ngày phù hợp để đặt tour.',
          ),
          const SizedBox(height: 16),
          if (schedules.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children:
                    schedules
                        .map((schedule) => _ScheduleChip(schedule: schedule))
                        .toList(),
              ),
            ),
          ...packages.map(
            (pkg) => _PackageCard(
              detail: detail,
              package: pkg,
              schedules: schedules,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  final TourSchedule schedule;
  const _ScheduleChip({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM');
    final text =
        '${dateFormat.format(schedule.startDate)} - ${dateFormat.format(schedule.endDate)}';
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFFFF5B00))),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final TourDetail detail;
  final TourPackage package;
  final List<TourSchedule> schedules;
  const _PackageCard({
    required this.detail,
    required this.package,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final childPrice = package.childPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  package.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showPackageInfo(context, package),
                child: const Text('Chi tiết'),
              ),
            ],
          ),
          if (package.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              package.description,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Người lớn: ${currency.format(package.adultPrice)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (childPrice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Trẻ em: ${currency.format(childPrice)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed:
                    () => BookingSheet.show(
                      context,
                      detail: detail,
                      package: package,
                      schedules: schedules,
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5B00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Chọn'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPackageInfo(BuildContext context, TourPackage package) {
    showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(package.name),
            content: Text(
              package.description.isNotEmpty
                  ? package.description
                  : 'Chưa có mô tả chi tiết.',
            ),
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

class ReviewSection extends StatelessWidget {
  final TourReviewsResponse reviews;
  const ReviewSection({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final average = reviews.average;
    final count = reviews.count;
    final reviewList = reviews.reviews;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Đánh giá',
            description: 'Khách đã trải nghiệm tour nói gì?',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hài lòng'),
                  Text(
                    '$count đánh giá',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reviewList.isEmpty)
            const Text('Chưa có đánh giá nào cho tour này.')
          else
            ...reviewList.take(3).map((review) => _ReviewCard(review: review)),
          if (reviewList.length > 3)
            OutlinedButton(
              onPressed: () {},
              child: const Text('Xem tất cả đánh giá'),
            ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final TourReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final dateText =
        review.createdAt != null
            ? DateFormat('dd/MM/yyyy').format(review.createdAt!)
            : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.orange.shade200,
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName.characters.first.toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (dateText.isNotEmpty)
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star
                        : Icons.star_border_outlined,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment.isNotEmpty
                ? review.comment
                : 'Khách hàng không để lại nhận xét.',
            style: const TextStyle(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  final TourDetail detail;
  const AboutSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final itineraryItems = detail.itinerary;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Về dịch vụ này',
            description: 'Tại sao bạn nên trải nghiệm tour này',
          ),
          const SizedBox(height: 16),
          if (detail.policy.isNotEmpty) ...[
            const Text(
              'Chính sách',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(detail.policy, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 16),
          ],
          if (itineraryItems.isNotEmpty) ...[
            const Text(
              'Lịch trình dự kiến',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...itineraryItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  item.toString(),
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SuggestionSection extends StatelessWidget {
  final List<TourSummary> suggestions;
  final ValueChanged<TourSummary> onTap;
  const SuggestionSection({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: const Text('Chưa có tour liên quan.'),
      );
    }

    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Bạn có thể thích',
            description: 'Những trải nghiệm tương tự dành cho bạn',
          ),
          const SizedBox(height: 16),
          ...suggestions.map(
            (tour) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  tour.mediaCover ??
                      'https://via.placeholder.com/96x72?text=Tour',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported),
                      ),
                ),
              ),
              title: Text(
                tour.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.destination,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    currency.format(tour.priceFrom),
                    style: const TextStyle(
                      color: Color(0xFFFF5B00),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onTap(tour),
            ),
          ),
        ],
      ),
    );
  }
}
