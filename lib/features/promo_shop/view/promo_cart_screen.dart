import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/promo_models.dart';
import '../presenter/promo_cart_presenter.dart';

class PromoCartScreen extends StatefulWidget {
  const PromoCartScreen({super.key});

  @override
  State<PromoCartScreen> createState() => _PromoCartScreenState();
}

class _PromoCartScreenState extends State<PromoCartScreen> {
  final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromoCartPresenter>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<PromoCartPresenter>();

    Widget body;
    if (presenter.state == PromoCartState.loading && presenter.items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (presenter.state == PromoCartState.error &&
        presenter.items.isEmpty) {
      body = _ErrorView(message: presenter.errorMessage);
    } else if (presenter.items.isEmpty) {
      body = const _EmptyCart();
    } else {
      body = RefreshIndicator(
        onRefresh: presenter.loadCart,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = presenter.items[index];
            return _CartItemTile(
              item: item,
              currency: _currency,
              onIncrease: () =>
                  presenter.increaseQuantity(item.product.productId),
              onDecrease: () =>
                  presenter.decreaseQuantity(item.product.productId),
              onRemove: () =>
                  presenter.removeItem(item.product.productId),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemCount: presenter.items.length,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Gio hang',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: body,
      bottomNavigationBar:
          presenter.items.isEmpty
              ? null
              : _SummaryBar(totals: presenter.totals, currency: _currency),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.currency,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final PromoCartItem item;
  final NumberFormat currency;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.product.imageUrl,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 96,
                  height: 96,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currency.format(item.price),
                    style: const TextStyle(
                      color: Color(0xFFFF6A3D),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item.appliedPromotion != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_offer_outlined,
                            color: Color(0xFFFF6A3D),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.appliedPromotion!.title,
                            style: const TextStyle(
                              color: Color(0xFFFF6A3D),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _QuantityButton(
                        icon: Icons.remove,
                        onTap: onDecrease,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _QuantityButton(
                        icon: Icons.add,
                        onTap: onIncrease,
                      ),
                      const Spacer(),
                      Text(
                        currency.format(item.lineSubtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.totals, required this.currency});

  final PromoCartTotals totals;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totals.bestPromotion != null)
            _PromoApplied(promotion: totals.bestPromotion!),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tam tinh'),
              Text(currency.format(totals.subtotal)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Giam gia'),
              Text('-${currency.format(totals.discount)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Phi van chuyen'),
              Text(currency.format(totals.shippingFee)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thanh tien',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      currency.format(totals.finalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Dat hang'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoApplied extends StatelessWidget {
  const _PromoApplied({required this.promotion});

  final PromotionSummary promotion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xFF0F9D58), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dang ap dung: ${promotion.title}',
              style: const TextStyle(color: Color(0xFF0F9D58)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 64),
            const SizedBox(height: 12),
            Text(
              'Gio hang dang trong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Bat dau them san pham va khuyen mai de dat hang nhanh hon.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () {}, child: const Text('Mua sam ngay')),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              message.isEmpty ? 'Khong the tai gio hang' : message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.read<PromoCartPresenter>().loadCart(),
              child: const Text('Thu lai'),
            ),
          ],
        ),
      ),
    );
  }
}
