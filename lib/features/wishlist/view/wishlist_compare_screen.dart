import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class WishlistCompareScreen extends StatelessWidget {
  final List<TourDetail> tours;

  const WishlistCompareScreen({super.key, required this.tours});

  @override
  Widget build(BuildContext context) {
    final comparedTours = tours.take(2).toList();
    if (comparedTours.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('So sánh tour')),
        body: const Center(child: Text('Không có dữ liệu để so sánh.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('So sánh tour')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720 && comparedTours.length > 1;
          final children =
              comparedTours
                  .mapIndexed(
                    (index, detail) => _TourComparisonColumn(
                      detail: detail,
                      accent:
                          index == 0 ? Colors.orangeAccent : Colors.blueAccent,
                    ),
                  )
                  .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
                isWide
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 16),
                        if (children.length > 1) Expanded(child: children[1]),
                      ],
                    )
                    : Column(
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          children[i],
                          if (i != children.length - 1)
                            const SizedBox(height: 16),
                        ],
                      ],
                    ),
          );
        },
      ),
    );
  }
}

class _TourComparisonColumn extends StatelessWidget {
  final TourDetail detail;
  final Color accent;

  _TourComparisonColumn({required this.detail, required this.accent});

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final cover =
        detail.media.isNotEmpty
            ? detail.media.first
            : 'https://via.placeholder.com/600x360?text=Tour';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                cover,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              detail.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.public,
                  label:
                      detail.type.toLowerCase() == 'international'
                          ? 'Tour quốc tế'
                          : 'Tour trong nước',
                  color: accent,
                ),
                if (detail.childAgeLimit != null)
                  _InfoPill(
                    icon: Icons.child_care_outlined,
                    label: 'Trẻ em ≤ ${detail.childAgeLimit}',
                  ),
                if (detail.requiresPassport)
                  const _InfoPill(
                    icon: Icons.badge_outlined,
                    label: 'Cần hộ chiếu',
                  ),
                if (detail.requiresVisa)
                  const _InfoPill(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Cần visa',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _ComparisonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Thông tin chính'),
                  const SizedBox(height: 10),
                  _ComparisonRow(
                    label: 'Điểm đến',
                    value: detail.destination,
                    accent: accent,
                  ),
                  _ComparisonRow(
                    label: 'Thời lượng',
                    value: '${detail.duration} ngày',
                  ),
                  _ComparisonRow(
                    label: 'Giá từ',
                    value: _currency.format(detail.basePrice),
                  ),
                  _ComparisonRow(
                    label: 'Đánh giá',
                    value:
                        detail.ratingAvg != null
                            ? '${detail.ratingAvg!.toStringAsFixed(1)} (${detail.reviewsCount} đánh giá)'
                            : 'Chưa có',
                  ),
                  _ComparisonRow(
                    label: 'Số lượt đặt',
                    value: detail.bookingsCount?.toString() ?? 'Chưa có',
                  ),
                ],
              ),
            ),
            if (detail.schedules.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ComparisonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Lịch khởi hành'),
                    const SizedBox(height: 10),
                    for (final schedule in detail.schedules)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.flight_takeoff, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_dateFormat.format(schedule.startDate)} - ${_dateFormat.format(schedule.endDate)} · ${schedule.seatsAvailable}/${schedule.seatsTotal} chỗ',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (detail.cancellationPolicies.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ComparisonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Chính sách hủy'),
                    const SizedBox(height: 10),
                    _CancellationPolicyTable(
                      policies: detail.cancellationPolicies,
                    ),
                  ],
                ),
              ),
            ],
            if (detail.itinerary.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ComparisonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Lịch trình nổi bật'),
                    const SizedBox(height: 10),
                    for (final item in detail.itinerary.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _describeItineraryItem(item),
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _describeItineraryItem(dynamic item) {
    if (item is String) return item;
    if (item is Map) {
      final title = item['title']?.toString() ?? '';
      final desc = item['description']?.toString() ?? '';
      if (title.isNotEmpty && desc.isNotEmpty) {
        return '$title: ${_trim(desc, 200)}';
      }
      return title.isNotEmpty ? title : _trim(desc, 200);
    }
    return item?.toString() ?? '';
  }

  String _trim(String value, int max) {
    if (value.length <= max) return value;
    return value.substring(0, math.min(max, value.length)).trimRight() + '…';
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _ComparisonRow({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: accent ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final Widget child;
  const _ComparisonCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Colors.black54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
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
              fontWeight: FontWeight.w500,
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
          children: const [
            _TableCellText('Thời hạn thông báo'),
            _TableCellText('Tỷ lệ hoàn tiền'),
            _TableCellText('Ghi chú'),
          ],
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

  static String _formatDays(int? daysBefore) {
    if (daysBefore == null) return 'Trong ngày khởi hành';
    if (daysBefore <= 0) return 'Thông báo trong ngày';
    return 'Trước ≥ $daysBefore ngày';
  }

  static String _formatRate(double rate) {
    var value = rate;
    if (value <= 1) value *= 100;
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

extension<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T value) convert) sync* {
    var i = 0;
    for (final element in this) {
      yield convert(i, element);
      i++;
    }
  }
}
