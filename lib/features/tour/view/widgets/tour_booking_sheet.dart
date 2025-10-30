import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourify_app/features/booking/view/booking_checkout_page.dart';
import 'package:tourify_app/features/cart/model/cart_repository_impl.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class BookingSheet {
  static Future<void> show(
    BuildContext context, {
    required TourDetail detail,
    required TourPackage package,
    required List<TourSchedule> schedules,
  }) {
    final rootContext = context;
    String? selectedScheduleId =
        schedules.isNotEmpty ? schedules.first.id : null;
    int adultCount = 1;
    int childCount = 0;
    bool isLoading = false;

    TourSchedule? currentSchedule() {
      if (selectedScheduleId == null) return null;
      try {
        return schedules.firstWhere(
          (schedule) => schedule.id == selectedScheduleId,
        );
      } catch (_) {
        return schedules.isNotEmpty ? schedules.first : null;
      }
    }

    double calcTotal() {
      final childPrice = package.childPrice ?? 0;
      return adultCount * package.adultPrice + childCount * childPrice;
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> handleAction(bool checkout) async {
              final messenger = ScaffoldMessenger.of(rootContext);
              final navigator = Navigator.of(rootContext);
              final sheetNavigator = Navigator.of(sheetContext);

              if (adultCount <= 0 && childCount <= 0) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng chọn ít nhất 1 hành khách.'),
                  ),
                );
                return;
              }

              final schedule = currentSchedule();

              if (checkout) {
                sheetNavigator.pop();
                await navigator.push(
                  MaterialPageRoute(
                    builder:
                        (_) => BookingCheckoutPage(
                          detail: detail,
                          package: package,
                          schedule: schedule,
                          adults: adultCount,
                          children: childCount,
                        ),
                  ),
                );
                return;
              }

              setState(() => isLoading = true);
              try {
                final repo = CartRepositoryImpl();
                await repo.addItem(
                  tourId: detail.id,
                  scheduleId: selectedScheduleId,
                  packageId: package.id,
                  adults: adultCount,
                  children: childCount,
                );
                setState(() => isLoading = false);
                sheetNavigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Đã thêm vào giỏ hàng.')),
                );
              } catch (error) {
                setState(() => isLoading = false);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      error.toString().isNotEmpty
                          ? error.toString()
                          : 'Không thể thêm vào giỏ hàng. Vui lòng thử lại.',
                    ),
                  ),
                );
              }
            }

            String formatSchedule(TourSchedule schedule) {
              final startText = dateFormat.format(schedule.startDate);
              final endText = dateFormat.format(schedule.endDate);
              return '$startText - $endText';
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  package.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                if (package.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      package.description,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vui lòng chọn ngày tham quan',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          if (schedules.isEmpty)
                            const Text('Chưa có lịch trình khả dụng.')
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  schedules.map((schedule) {
                                    final text = formatSchedule(schedule);
                                    final isSelected =
                                        schedule.id == selectedScheduleId;
                                    return ChoiceChip(
                                      label: Text(text),
                                      selected: isSelected,
                                      onSelected: (_) {
                                        setState(
                                          () =>
                                              selectedScheduleId = schedule.id,
                                        );
                                      },
                                      selectedColor: const Color(0xFFFFF2E8),
                                      labelStyle: TextStyle(
                                        color:
                                            isSelected
                                                ? const Color(0xFFFF5B00)
                                                : Colors.black87,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          const SizedBox(height: 24),
                          const Text(
                            'Số hành khách',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          PassengerCounter(
                            title: 'Người lớn',
                            description: 'Từ 12 tuổi',
                            value: adultCount,
                            minValue: 1,
                            onChanged:
                                (value) => setState(
                                  () => adultCount = value.clamp(1, 20),
                                ),
                          ),
                          const SizedBox(height: 12),
                          PassengerCounter(
                            title: 'Trẻ em',
                            description: 'Dưới 12 tuổi',
                            value: childCount,
                            minValue: 0,
                            onChanged:
                                (value) => setState(
                                  () => childCount = value.clamp(0, 20),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Tổng tạm tính',
                                style: TextStyle(color: Colors.black54),
                              ),
                              const Spacer(),
                              Text(
                                currency.format(calcTotal()),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      isLoading
                                          ? null
                                          : () => handleAction(false),
                                  child: const Text('Thêm vào giỏ hàng'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      isLoading
                                          ? null
                                          : () => handleAction(true),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    backgroundColor: const Color(0xFFFF5B00),
                                  ),
                                  child:
                                      isLoading
                                          ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text('Đặt ngay'),
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
          },
        );
      },
    );
  }
}

class PassengerCounter extends StatelessWidget {
  final String title;
  final String description;
  final int value;
  final int minValue;
  final ValueChanged<int> onChanged;

  const PassengerCounter({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          _RoundIconButton(
            icon: Icons.remove_circle_outline,
            onPressed: value > minValue ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          _RoundIconButton(
            icon: Icons.add_circle_outline,
            onPressed: value < 20 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _RoundIconButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              onPressed == null ? Colors.grey.shade200 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.grey : const Color(0xFFFF5B00),
        ),
      ),
    );
  }
}
