import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tourify_app/features/home/model/home_models.dart';
import 'package:tourify_app/features/home/view/promotions_list_screen.dart';

class PromotionsSection extends StatelessWidget {
  const PromotionsSection({super.key, required this.promotions});

  final List<PromotionItem> promotions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Ưu đãi dành cho bạn',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child:
              promotions.isEmpty
                  ? const Center(child: Text('Hiện không có ưu đãi nào'))
                  : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder:
                        (context, index) => _PromotionCard(
                          item: promotions[index],
                          index: index,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PromotionsListScreen(),
                              ),
                            );
                          },
                        ),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: promotions.length,
                  ),
        ),
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  final PromotionItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palettes = [
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      [const Color(0xFFFF512F), const Color(0xFFF09819)],
      [const Color(0xFF36D1DC), const Color(0xFF5B86E5)],
    ];
    final colors = palettes[index % palettes.length];

    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final type = item.discountType.toLowerCase();
    final isPercent = type.contains('percent');
    final valueText =
        isPercent
            ? '${item.value.toStringAsFixed(0)}%'
            : currency.format(item.value);
    final headline = 'Giảm $valueText';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: colors),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                headline,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              item.code.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Khám phá ngay',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
