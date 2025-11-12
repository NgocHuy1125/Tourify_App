import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/booking/view/booking_checkout_page.dart';
import 'package:tourify_app/features/cart/model/cart_model.dart';
import 'package:tourify_app/features/cart/presenter/cart_presenter.dart';
import 'package:tourify_app/features/cart/view/widgets/cart_empty_view.dart';
import 'package:tourify_app/features/tour/model/tour_repository_impl.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions:
            hasItems
                ? [
                  TextButton(
                    onPressed:
                        () =>
                            presenter.toggleSelectAll(!presenter.isAllSelected),
                    child: Text(
                      presenter.isAllSelected ? 'Bỏ chọn' : 'Chọn tất cả',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]
                : null,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _CartBody(presenter: presenter, currency: _currency),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child:
                  hasItems
                      ? _CartSummaryBar(
                        presenter: presenter,
                        currency: _currency,
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBody extends StatelessWidget {
  final CartPresenter presenter;
  final NumberFormat currency;

  const _CartBody({required this.presenter, required this.currency});

  Future<void> _refresh() async {
    await presenter.loadCart(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (presenter.state == CartState.loading && presenter.entries.isEmpty) {
      child = const Center(child: CircularProgressIndicator());
    } else if (presenter.state == CartState.error &&
        presenter.entries.isEmpty) {
      child = _CartErrorView(
        message: presenter.errorMessage,
        onRetry: _refresh,
      );
    } else if (presenter.entries.isEmpty) {
      child = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: const [CartEmptyView()],
        ),
      );
    } else {
      child = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          itemCount: presenter.entries.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _SelectAllTile(
                isAllSelected: presenter.isAllSelected,
                selected: presenter.selectedCount,
                total: presenter.entries.length,
                onChanged: (value) => presenter.toggleSelectAll(value ?? false),
              );
            }
            final entry = presenter.entries[index - 1];
            return Padding(
              padding: EdgeInsets.only(top: index == 1 ? 18 : 22),
              child: _CartItemCard(
                entry: entry,
                currency: currency,
                onSelect:
                    (value) =>
                        presenter.toggleItem(entry.item.id, value ?? false),
                onIncrease: () => presenter.increaseQuantity(entry.item),
                onDecrease: () => presenter.decreaseQuantity(entry.item),
                onRemove: () => presenter.removeItem(entry.item.id),
              ),
            );
          },
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}

class _SelectAllTile extends StatelessWidget {
  final bool isAllSelected;
  final int selected;
  final int total;
  final ValueChanged<bool?> onChanged;

  const _SelectAllTile({
    required this.isAllSelected,
    required this.selected,
    required this.total,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: CheckboxListTile(
        value: isAllSelected,
        onChanged: onChanged,
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          'Chọn tất cả ($selected/$total)',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartEntry entry;
  final NumberFormat currency;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.entry,
    required this.currency,
    required this.onSelect,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final tour = item.tour;
    final isSelected = entry.selected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isSelected
                  ? const [Color(0xFFFFE8D6), Color(0xFFFFFFFF)]
                  : const [Color(0xFFFDFDFD), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF8A3D) : Colors.transparent,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFFF8A3D,
            ).withValues(alpha: isSelected ? 0.22 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: entry.selected,
                  onChanged: onSelect,
                  activeColor: const Color(0xFFFF5B00),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    item.imageUrl.isNotEmpty
                        ? item.imageUrl
                        : 'https://via.placeholder.com/140x120?text=Tour',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported),
                        ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                      if (tour?.destination.isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tour!.destination,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.scheduleText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 15),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.scheduleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.packageName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Gói dịch vụ: ${item.packageName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (tour != null)
                  _InfoChip(
                    icon: Icons.public,
                    label:
                        tour.type.toLowerCase() == 'international'
                            ? 'Tour quốc tế'
                            : 'Tour trong nước',
                  ),
                if (tour?.requiresPassport ?? false)
                  const _InfoChip(
                    icon: Icons.badge_outlined,
                    label: 'Cần hộ chiếu',
                  ),
                if (tour?.requiresVisa ?? false)
                  const _InfoChip(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Cần visa',
                  ),
                if (item.note.isNotEmpty)
                  _InfoChip(icon: Icons.info_outline, label: item.note),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StepperButton(icon: Icons.remove, onPressed: onDecrease),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                _StepperButton(icon: Icons.add, onPressed: onIncrease),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Tạm tính',
                      style: TextStyle(color: Colors.black54, fontSize: 12.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(_resolveSubtotal(item)),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Xóa khỏi giỏ'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _resolveSubtotal(CartItem item) {
    if (item.price != 0) return item.price;
    final subtotal = item.adultSubtotal + item.childSubtotal;
    if (subtotal != 0) return subtotal;
    final unit =
        item.tour?.priceAfterDiscount ?? item.tour?.priceFrom ?? 0;
    if (unit == 0) return 0;
    final passengers = item.adults + item.children;
    final quantity =
        passengers > 0 ? passengers : (item.quantity == 0 ? 1 : item.quantity);
    return unit * quantity;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFF5B00)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFF5B00),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StepperButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFFE0CC), Color(0xFFFFC9A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3DFF8A3D),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Colors.white),
        splashRadius: 22,
      ),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  final CartPresenter presenter;
  final NumberFormat currency;

  const _CartSummaryBar({required this.presenter, required this.currency});

  Future<void> _startCheckout(BuildContext context) async {
    final selected = presenter.selectedItems;
    if (selected.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (selected.length > 1) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn một tour để thanh toán.'),
        ),
      );
      return;
    }

    final item = selected.first;
    final tourId = item.tour?.id ?? '';
    if (tourId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin tour phù hợp.'),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    var dialogClosed = false;
    void closeDialog() {
      if (!dialogClosed) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogClosed = true;
      }
    }

    try {
      final tourRepo = TourRepositoryImpl();
      final detail = await tourRepo.getTourDetails(tourId);

      if (detail.packages.isEmpty) {
        throw Exception('Tour chưa có gói dịch vụ khả dụng.');
      }

      TourPackage package;
      try {
        package = detail.packages.firstWhere(
          (pkg) => pkg.id == item.packageId,
        );
      } catch (_) {
        package = detail.packages.first;
      }

      TourSchedule? schedule;
      if (item.scheduleId.isNotEmpty && detail.schedules.isNotEmpty) {
        try {
          schedule = detail.schedules.firstWhere(
            (s) => s.id == item.scheduleId,
          );
        } catch (_) {
          schedule = detail.schedules.first;
        }
      } else if (detail.schedules.length == 1) {
        schedule = detail.schedules.first;
      }

      final adults = item.adults > 0 ? item.adults : item.quantity;
      final children = item.children;

      closeDialog();

      await navigator.push(
        MaterialPageRoute(
          builder: (_) => BookingCheckoutPage(
            detail: detail,
            package: package,
            schedule: schedule,
            adults: adults,
            children: children,
          ),
        ),
      );

      if (!context.mounted) return;
      await presenter.loadCart(showLoading: false);
    } catch (error) {
      closeDialog();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.toString().isNotEmpty
                ? error.toString()
                : 'Không thể mở màn hình thanh toán. Vui lòng thử lại.',
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final totalText = currency.format(presenter.effectiveTotal);
    final units =
        presenter.selectedQuantity == 0 && presenter.entries.isNotEmpty
            ? presenter.totalItems
            : presenter.selectedQuantity;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFEAD9), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33FF8A3D),
            blurRadius: 22,
            offset: Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng cộng ($units đơn vị)',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    totalText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: presenter.selectedItems.isEmpty ? null : () => _startCheckout(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 16,
                ),
                backgroundColor: const Color(0xFFFF5B00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                elevation: 0,
              ),
              child: const Text('Thanh toán'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _CartErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final display =
        message.isNotEmpty ? message : 'Đã xảy ra lỗi khi tải giỏ hàng.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(display, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onRetry(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
