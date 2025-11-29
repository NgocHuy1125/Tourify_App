import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/home/model/home_models.dart';
import 'package:tourify_app/features/home/presenter/home_presenter.dart';

class PromotionsListScreen extends StatelessWidget {
  const PromotionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FE),
      appBar: AppBar(
        title: const Text('Mã giảm giá'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Consumer<HomePresenter>(
        builder: (context, presenter, _) {
          final isLoading =
              presenter.state == HomeState.loading &&
              presenter.promotions.isEmpty;
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (presenter.promotions.isEmpty) {
            return const _EmptyPromotions();
          }
          final promos = presenter.promotions;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth > 760;
                    final itemWidth =
                        twoColumns
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children:
                          promos
                              .map(
                                (promo) => SizedBox(
                                  width: itemWidth,
                                  child: _PromotionCard(item: promo),
                                ),
                              )
                              .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.item});
  final PromotionItem item;

  String _discountText(NumberFormat currency) {
    if (item.discountType == 'fixed') {
      return 'Giảm ${currency.format(item.value)}';
    }
    return 'Giảm ${item.value.toInt()}%';
  }

  String _validityText(DateFormat fmt) {
    final from =
        item.validFrom != null ? fmt.format(item.validFrom!) : 'Không rõ';
    final to = item.validTo != null ? fmt.format(item.validTo!) : 'Không rõ';
    return '$from - $to';
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('d/M/yyyy');
    final accent = const Color(0xFFFF5B00);
    final shadow = Colors.orange.shade50;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shadow),
        boxShadow: [
          BoxShadow(
            // Đã sửa: Colors.black.withOpacity(0.1) -> Colors.black.withValues(alpha: 0.1)
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: shadow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: Color(0xFFFF5B00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.code,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accent,
                          style: BorderStyle.solid,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mã ưu đãi:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.code,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _discountText(currency),
                style: TextStyle(color: accent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Giảm giá:', value: _discountText(currency)),
          _InfoRow(label: 'Hiệu lực:', value: _validityText(dateFmt)),
          const _InfoRow(
            label: 'Giới hạn:',
            value: 'Theo điều kiện nhà cung cấp',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: item.code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã lưu mã ${item.code} vào bộ nhớ tạm'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Lưu mã',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPromotions extends StatelessWidget {
  const _EmptyPromotions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Hiện chưa có khuyến mãi nào.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Quay lại sau nhé, ưu đãi mới sẽ được cập nhật sớm!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
