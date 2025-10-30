import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/promo_models.dart';
import '../presenter/promo_home_presenter.dart';

class PromoHomeScreen extends StatefulWidget {
  const PromoHomeScreen({super.key});

  @override
  State<PromoHomeScreen> createState() => _PromoHomeScreenState();
}

class _PromoHomeScreenState extends State<PromoHomeScreen> {
  final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromoHomePresenter>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<PromoHomePresenter>();
    final theme = Theme.of(context);

    Widget body;
    if (presenter.state == PromoHomeState.loading &&
        presenter.data.spotlightPromotions.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (presenter.state == PromoHomeState.error &&
        presenter.data.spotlightPromotions.isEmpty) {
      body = _ErrorState(message: presenter.errorMessage);
    } else {
      body = RefreshIndicator(
        onRefresh: presenter.load,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 16),
            _HeroPromotions(
              promotions: presenter.data.spotlightPromotions,
            ),
            const SizedBox(height: 20),
            _CategoryStrip(categories: presenter.data.categories),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Flash sale dang dien ra',
              actionLabel: 'Xem tat ca',
              onAction: () {},
            ),
            _HorizontalProductList(
              products: presenter.data.featuredProducts,
              currency: _currency,
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Combo tiet kiem',
              actionLabel: 'Xem them',
              onAction: () {},
            ),
            _HorizontalProductList(
              products: presenter.data.trendingCombos,
              currency: _currency,
            ),
            const SizedBox(height: 24),
            _MembershipHighlight(
              promotion: presenter.data.spotlightPromotions
                  .firstWhere(
                    (p) => p.promoId == 'PRM_MEMBER',
                    orElse: () => presenter.data.spotlightPromotions.isNotEmpty
                        ? presenter.data.spotlightPromotions.first
                            : const Promotion(
                                promoId: 'PRM_PLACEHOLDER',
                                title: 'Uu dai dac biet',
                                type: 'info',
                                minOrder: 0,
                                rewardType: 'info',
                                startDate: DateTime.now(),
                                endDate: DateTime.now(),
                                status: 'ACTIVE',
                                autoApply: true,
                            stackable: true,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                  ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PromoShop',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Quan ly khuyen mai cho ban',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 46,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tim san pham, ma khuyen mai...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}

class _HeroPromotions extends StatefulWidget {
  const _HeroPromotions({required this.promotions});

  final List<Promotion> promotions;

  @override
  State<_HeroPromotions> createState() => _HeroPromotionsState();
}

class _HeroPromotionsState extends State<_HeroPromotions> {
  final _controller = PageController(viewportFraction: 0.88);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promotions = widget.promotions;
    if (promotions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.blueGrey.shade50,
          ),
          child: const Center(
            child: Text('Chua co khuyen mai noi bat'),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _controller,
            itemCount: promotions.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final item = promotions[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: _heroColors[index % _heroColors.length],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.badge!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          item.tiers.isNotEmpty
                              ? item.tiers
                                  .map((tier) => tier.label)
                                  .join(' · ')
                              : item.rewardType,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                              ),
                              child: const Text('San deal ngay'),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            promotions.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _index == i ? 24 : 10,
              decoration: BoxDecoration(
                color:
                    _index == i
                        ? Colors.orangeAccent
                        : Colors.orangeAccent.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories});

  final List<PromoCategory> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Column(
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEE1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _iconFromName(category.icon),
                  color: const Color(0xFFFF6A3D),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 80,
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemCount: categories.length,
      ),
    );
  }
}

class _HorizontalProductList extends StatelessWidget {
  const _HorizontalProductList({
    required this.products,
    required this.currency,
  });

  final List<PromoProduct> products;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('Danh sach dang duoc cap nhat...'),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 200,
            child: Card(
              elevation: 3,
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported_outlined),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currency.format(product.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6A3D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              product.promotions
                                  .take(2)
                                  .map(
                                    (promo) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0E5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        promo.title,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFFF6A3D),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemCount: products.length,
      ),
    );
  }
}

class _MembershipHighlight extends StatelessWidget {
  const _MembershipHighlight({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF1F2937),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Membership tiers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              promotion.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  promotion.tiers
                      .map(
                        (tier) => _TierChip(
                          label: tier.label,
                          description: _formatTier(tier),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTier(PromotionTier tier) {
    final parts = <String>[];
    if (tier.discountPercent != null) {
      parts.add('${tier.discountPercent}% off');
    }
    if (tier.discountAmount != null) {
      parts.add(
        'Giam ${NumberFormat.compactCurrency(
          locale: 'vi',
          symbol: 'VND',
          decimalDigits: 0,
        ).format(tier.discountAmount)}',
      );
    }
    if (tier.freeship) {
      parts.add('Freeship');
    }
    if (tier.giftProductId != null) {
      parts.add('Qua tang');
    }
    if (parts.isEmpty) {
      return 'Uu dai tuy chon';
    }
    return parts.join(' · ');
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              message.isEmpty ? 'Khong the tai du lieu' : message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.read<PromoHomePresenter>().load(),
              child: const Text('Thu lai'),
            ),
          ],
        ),
      ),
    );
  }
}

final _heroColors = [
  [const Color(0xFFFA709A), const Color(0xFFFEE140)],
  [const Color(0xFF667EEA), const Color(0xFF764BA2)],
  [const Color(0xFF30CFD0), const Color(0xFF330867)],
];

IconData _iconFromName(String name) {
  switch (name) {
    case 'devices':
      return Icons.devices_other;
    case 'spa':
      return Icons.spa_outlined;
    case 'local_grocery_store':
      return Icons.local_grocery_store_outlined;
    case 'redeem':
      return Icons.redeem_outlined;
    case 'self_improvement':
      return Icons.self_improvement;
    default:
      return Icons.category_outlined;
  }
}
