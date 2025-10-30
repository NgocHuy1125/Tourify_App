import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/cart/presenter/cart_presenter.dart';
import 'package:tourify_app/features/cart/view/widgets/cart_empty_view.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartPresenter>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<CartPresenter>();
    final hasItems = presenter.entries.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Gi? h�ng',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: hasItems
            ? [
                TextButton(
                  onPressed: () =>
                      presenter.toggleSelectAll(!presenter.isAllSelected),
                  child: Text(
                    presenter.isAllSelected ? 'B? ch?n' : 'Ch?n t?t c?',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _CartBody(presenter: presenter),
      bottomNavigationBar:
          hasItems ? _CartBottomBar(presenter: presenter) : null,
    );
  }
}

class _CartBody extends StatelessWidget {
  final CartPresenter presenter;
  const _CartBody({required this.presenter});

  @override
  Widget build(BuildContext context) {
    if (presenter.state == CartState.loading && presenter.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (presenter.state == CartState.error && presenter.entries.isEmpty) {
      return _ErrorView(message: presenter.errorMessage);
    }

    if (presenter.entries.isEmpty) {
      return const CartEmptyView();
    }

    final entries = presenter.entries;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _SelectAllBanner(presenter: presenter),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => presenter.loadCart(showLoading: false),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
              itemCount: entries.length + 1,
              itemBuilder: (context, index) {
                if (index == entries.length) {
                  return const _UpsellPlaceholder();
                }
                final entry = entries[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == entries.length - 1 ? 24 : 12,
                  ),
                  child: _CartItemTile(
                    key: ValueKey(entry.item.id),
                    entry: entry,
                    onSelect: (value) =>
                        presenter.toggleItem(entry.item.id, value),
                    onIncrease: () => presenter.increaseQuantity(entry.item),
                    onDecrease: () => presenter.decreaseQuantity(entry.item),
                    onRemove: () => presenter.removeItem(entry.item.id),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectAllBanner extends StatelessWidget {
  final CartPresenter presenter;
  const _SelectAllBanner({required this.presenter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: presenter.isAllSelected,
            onChanged: (value) => presenter.toggleSelectAll(value ?? false),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Ch?n t?t c? don v?',
              style: TextStyle(
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

class _CartItemTile extends StatelessWidget {
  final CartEntry entry;
  final ValueChanged<bool> onSelect;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartItemTile({
    super.key,
    required this.entry,
    required this.onSelect,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '?',
      decimalDigits: 0,
    );
    final tour = item.tour;
    final passengers = (item.adults + item.children) > 0
        ? (item.adults + item.children)
        : item.quantity;
    final baseTotal = item.price != 0
        ? item.price
        : (item.adultSubtotal + item.childSubtotal);
    final fallbackTotal = (tour?.priceFrom ?? 0) * passengers;
    final totalPrice = baseTotal != 0 ? baseTotal : fallbackTotal;

    String buildPaxLabel() {
      final adults = item.adults;
      final children = item.children;
      if (adults == 0 && children == 0) {
        return item.quantity > 1
            ? '${item.quantity} v�'
            : '1 v�';
      }
      final parts = <String>[];
      if (adults > 0) parts.add('$adults ngu?i l?n');
      if (children > 0) parts.add('$children tr? em');
      return parts.join(' � ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: entry.selected,
                onChanged: (value) => onSelect(value ?? false),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl.isNotEmpty
                      ? item.imageUrl
                      : 'https://via.placeholder.com/120x90?text=Tour',
                  width: 96,
                  height: 78,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: 96,
                        height: 78,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isNotEmpty
                          ? item.title
                          : (tour?.title ?? 'Tour'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tour != null && tour.destination.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          tour.destination,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    if (item.scheduleText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.scheduleText,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        buildPaxLabel(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'G�i d?ch v?:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.packageName.isNotEmpty
                            ? item.packageName
                            : item.quantityLabel,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                if (item.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      item.note,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'T?m t�nh',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.format(totalPrice),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF5B00),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _QuantityControl(
                onDecrease: onDecrease,
                onIncrease: onIncrease,
                quantity: item.quantity,
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _QuantityControl({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_circle_outline),
            splashRadius: 18,
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_circle_outline),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  final CartPresenter presenter;
  const _CartBottomBar({required this.presenter});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '?',
      decimalDigits: 0,
    );
    final totalText = currency.format(presenter.effectiveTotal);

    final selectedUnits =
        presenter.selectedQuantity == 0 && presenter.entries.isNotEmpty
            ? presenter.totalItems
            : presenter.selectedQuantity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'T?ng c?ng ($selectedUnits don v?)',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  totalText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: presenter.selectedQuantity == 0 ? null : () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5B00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            child: const Text('Thanh to�n'),
          ),
        ],
      ),
    );
  }
}

class _UpsellPlaceholder extends StatelessWidget {
  const _UpsellPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thu?ng du?c d?t v?i',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'T�nh nang g?i � dang du?c ph�t tri?n. H�y ti?p t?c kh�m ph� Tourify nh�!',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message.isNotEmpty ? message : '�� x?y ra l?i khi t?i gi? h�ng.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

