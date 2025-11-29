import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourify_app/core/utils/auth_guard.dart';
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
        child: const Text('Chưa có gói dịch vụ khả dụng cho tour này.'),
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
    final seats = schedule.seatsAvailable;
    final total = schedule.seatsTotal;
    final isSoldOut = seats <= 0;
    final seatsText =
        seats >= total
            ? 'Còn nhiều chỗ'
            : seats > 0
            ? 'Còn $seats/$total chỗ'
            : 'Hết chỗ';
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSoldOut ? Colors.grey.shade200 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSoldOut ? Colors.grey.shade300 : Colors.orange.shade100,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSoldOut ? Colors.black54 : const Color(0xFFFF5B00),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            seatsText,
            style: TextStyle(
              fontSize: 12,
              color: isSoldOut ? Colors.black45 : Colors.black87,
              fontWeight: isSoldOut ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
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
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final scheduleCount = schedules.length;
    final discountFactor = detail.autoPromotionFactor;
    final hasDiscount = discountFactor < 0.999;
    final hasAvailableSchedule = schedules.any((s) => s.seatsAvailable > 0);

    double applyDiscount(double price) {
      if (!hasDiscount) return price;
      return (price * discountFactor).clamp(0, price);
    }

    final adultPrice = package.adultPrice;
    final adultDiscounted = applyDiscount(adultPrice);
    final childPrice = package.childPrice;
    final double? childDiscounted =
        childPrice != null ? applyDiscount(childPrice) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  package.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (scheduleCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$scheduleCount lịch khởi hành',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (package.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              package.description,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          _PackageSummaryRow(
            label: 'Giá người lớn',
            value: currency.format(adultDiscounted),
            oldValue: hasDiscount ? currency.format(adultPrice) : null,
          ),
          if (package.childPrice != null)
            _PackageSummaryRow(
              label: 'Giá trẻ em',
              value: currency.format(childDiscounted),
              oldValue:
                  hasDiscount && childPrice != null
                      ? currency.format(childPrice)
                      : null,
            ),
          if (detail.childAgeLimit != null)
            _PackageSummaryRow(
              label: 'Áp dụng cho trẻ em',
              value: '≤ ${detail.childAgeLimit} tuổi',
            ),
          if (hasDiscount && detail.autoPromotion != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                detail.autoPromotion?.description ??
                    'Đã bao gồm ưu đãi ${detail.autoPromotion!.code}',
                style: const TextStyle(
                  color: Color(0xFFFF5B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed:
                    hasAvailableSchedule
                        ? () async {
                          final allowed = await ensureLoggedIn(
                            context,
                            message: 'Vui lòng đăng nhập để đặt tour.',
                          );
                          if (!allowed) return;
                          BookingSheet.show(
                            context,
                            detail: detail,
                            package: package,
                            schedules: schedules,
                          );
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5B00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(hasAvailableSchedule ? 'Chọn gói này' : 'Hết chỗ'),
              ),
              const SizedBox(width: 12),
              if (detail.policy.isNotEmpty)
                TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Điều khoản gói dịch vụ'),
                            content: SingleChildScrollView(
                              child: Text(detail.policy),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                    );
                  },
                  child: const Text('Xem điều khoản'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackageSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String? oldValue;

  const _PackageSummaryRow({
    required this.label,
    required this.value,
    this.oldValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          if (oldValue != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                oldValue!,
                style: const TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
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

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Đánh giá ($count)',
            description: 'Khách đã trải nghiệm nói gì về tour này?',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      average.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF5B00),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Điểm trung bình'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Tổng số $count đánh giá được xác thực từ khách đã đặt tour.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reviews.reviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tour này chưa có đánh giá. Hãy là người đầu tiên chia sẻ trải nghiệm!',
              ),
            )
          else
            Column(
              children:
                  reviews.reviews
                      .map((review) => _ReviewTile(review: review))
                      .toList(),
            ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final TourReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final date =
        review.createdAt != null
            ? DateFormat('dd/MM/yyyy').format(review.createdAt!)
            : 'Không rõ ngày';
    final scheduleDisplay = review.scheduleText;
    final scheduleText = _formatScheduleDate(scheduleDisplay);

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
              const Icon(Icons.person_outline, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.star, size: 18, color: Color(0xFFFFB400)),
              const SizedBox(width: 4),
              Text(
                review.rating.toString(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ngày đánh giá: $date',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          if (scheduleText != null) ...[
            const SizedBox(height: 4),
            Text(
              'Lịch khởi hành: $scheduleText',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            review.comment.isNotEmpty
                ? review.comment
                : 'Khách không để lại bình luận.',
            style: const TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  String? _formatScheduleDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return DateFormat('dd/MM/yyyy').format(parsed);
    }
    return raw;
  }
}

class AboutSection extends StatelessWidget {
  final TourDetail detail;
  const AboutSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      _InfoBadge(
        icon: Icons.public,
        label:
            detail.type.toLowerCase() == 'international'
                ? 'Tour quốc tế'
                : 'Tour trong nước',
        color:
            detail.type.toLowerCase() == 'international'
                ? Colors.blueAccent
                : const Color(0xFFFF5B00),
      ),
    ];
    if (detail.childAgeLimit != null) {
      badges.add(
        _InfoBadge(
          icon: Icons.child_care_outlined,
          label: 'Trẻ em ≤ ${detail.childAgeLimit} tuổi',
        ),
      );
    }
    if (detail.requiresPassport) {
      badges.add(
        const _InfoBadge(icon: Icons.badge_outlined, label: 'Yêu cầu hộ chiếu'),
      );
    }
    if (detail.requiresVisa) {
      badges.add(
        const _InfoBadge(
          icon: Icons.assignment_ind_outlined,
          label: 'Yêu cầu visa',
        ),
      );
    }

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
          const SizedBox(height: 12),
          if (badges.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: badges),
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Giới thiệu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(detail.description, style: const TextStyle(height: 1.4)),
          ],
          if (detail.cancellationPolicies.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Chính sách hủy tour',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _CancellationPolicyTable(policies: detail.cancellationPolicies),
          ],
          if (detail.policy.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Điều khoản bổ sung',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(detail.policy, style: const TextStyle(height: 1.4)),
          ],
          if (itineraryItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Lịch trình dự kiến',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...itineraryItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _describeItineraryItem(item),
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _describeItineraryItem(dynamic item) {
    if (item is String) return item;
    if (item is Map) {
      final title = item['title']?.toString() ?? '';
      final desc = item['description']?.toString() ?? '';
      if (title.isNotEmpty && desc.isNotEmpty) {
        return '$title: $desc';
      }
      return title.isNotEmpty ? title : desc;
    }
    return item?.toString() ?? '';
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoBadge({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationPolicyTable extends StatelessWidget {
  final List<TourCancellationPolicy> policies;
  const _CancellationPolicyTable({required this.policies});

  @override
  Widget build(BuildContext context) {
    final headers = ['Thời hạn thông báo', 'Tỷ lệ hoàn tiền', 'Ghi chú'];
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.4),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
      },
      border: TableBorder.all(color: Colors.grey.shade200),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFFFF4EC)),
          children:
              headers
                  .map(
                    (header) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        header,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        ...policies.map((policy) {
          return TableRow(
            children: [
              _TableCellText(_formatDays(policy.daysBefore)),
              _TableCellText(_formatRate(policy.refundRate)),
              _TableCellText(
                policy.description.isNotEmpty
                    ? policy.description
                    : 'Không có thông tin',
              ),
            ],
          );
        }),
      ],
    );
  }

  String _formatDays(int? daysBefore) {
    if (daysBefore == null) return 'Trong ngày khởi hành';
    if (daysBefore <= 0) return 'Thông báo trong ngày';
    return 'Trước ≥ $daysBefore ngày';
  }

  String _formatRate(double rate) {
    var value = rate;
    if (value <= 1) {
      value *= 100;
    }
    return '${value.toStringAsFixed(0)}%';
  }
}

class _TableCellText extends StatelessWidget {
  final String value;
  const _TableCellText(this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(value, style: const TextStyle(fontSize: 12, height: 1.4)),
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tour.type.toLowerCase() == 'international'
                              ? 'Quốc tế'
                              : 'Trong nước',
                          style: TextStyle(
                            color:
                                tour.type.toLowerCase() == 'international'
                                    ? Colors.blueAccent
                                    : const Color(0xFFFF5B00),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currency.format(tour.displayPrice),
                        style: const TextStyle(
                          color: Color(0xFFFF5B00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (tour.displayPrice < tour.priceFrom)
                        Text(
                          currency.format(tour.priceFrom),
                          style: const TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                          ),
                        ),
                    ],
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
