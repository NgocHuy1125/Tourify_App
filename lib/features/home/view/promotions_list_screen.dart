import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tourify_app/features/home/presenter/home_presenter.dart';
import 'package:tourify_app/features/home/model/home_models.dart';

class PromotionsListScreen extends StatelessWidget {
  const PromotionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ưu đãi hấp dẫn')),
      body: Consumer<HomePresenter>(
        builder: (context, presenter, _) {
          if (presenter.state == HomeState.loading &&
              presenter.promotions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (presenter.promotions.isEmpty) {
            return const _EmptyPromotions();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) {
              final promo = presenter.promotions[index];
              return _PromotionCard(item: promo);
            },
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemCount: presenter.promotions.length,
          );
        },
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final PromotionItem item;
  const _PromotionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final valueText =
        item.discountType == 'fixed'
            ? 'Giảm ${currency.format(item.value)}'
            : 'Giảm ${item.value.toInt()}%';
    final dateFormat = DateFormat('dd/MM/yyyy');
    final validFrom =
        item.validFrom != null
            ? dateFormat.format(item.validFrom!)
            : 'Không rõ';
    final validTo =
        item.validTo != null ? dateFormat.format(item.validTo!) : 'Không rõ';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF8A56F5), Color(0xFFFF5B00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.code,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valueText,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            'Hiệu lực: $validFrom - $validTo',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF5B00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Săn deal ngay'),
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
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hiện chưa có khuyến mãi nào.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quay lại sau nhé, Tourify sẽ cập nhật deal hấp dẫn sớm thôi!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
