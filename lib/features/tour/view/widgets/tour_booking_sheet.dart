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
    TourSchedule? availableSchedule;
    if (schedules.isNotEmpty) {
      try {
        availableSchedule = schedules.firstWhere((s) => s.seatsAvailable > 0);
      } catch (_) {
        availableSchedule = schedules.first;
      }
    }

    String? selectedScheduleId = availableSchedule?.id;
    int adultCount = 1;
    int childCount = 0;
    bool isLoading = false;
    bool showFullDescription = false;

    TourSchedule? currentSchedule() {
      if (selectedScheduleId == null) return null;
      if (schedules.isEmpty) return null;
      try {
        return schedules.firstWhere((s) => s.id == selectedScheduleId);
      } catch (_) {
        return schedules.first;
      }
    }

    int totalGuests() => adultCount + childCount;

    double calcTotal() {
      final childPrice = package.childPrice ?? 0;
      return adultCount * package.adultPrice + childCount * childPrice;
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
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
              final cap = schedule?.seatsAvailable ?? 0;
              final guests = totalGuests();

              if (schedule != null && cap <= 0) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Lịch này đã hết chỗ, vui lòng chọn ngày khác.',
                    ),
                  ),
                );
                return;
              }

              if (schedule != null && cap > 0 && guests > cap) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Chỉ còn $cap chỗ, vui lòng chọn ngày khác.'),
                  ),
                );
                return;
              }

              if (schedule == null && schedules.isNotEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Vui lòng chọn lịch còn chỗ.')),
                );
                return;
              }

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
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          package.description,
                                          maxLines:
                                              showFullDescription ? null : 3,
                                          overflow:
                                              showFullDescription
                                                  ? TextOverflow.visible
                                                  : TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        if (package.description.length > 120)
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 0),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            onPressed:
                                                () => setState(
                                                  () =>
                                                      showFullDescription =
                                                          !showFullDescription,
                                                ),
                                            child: Text(
                                              showFullDescription
                                                  ? 'Thu gọn'
                                                  : 'Xem thêm',
                                              style: const TextStyle(
                                                color: Color(0xFFFF5B00),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
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
                                    final cap = schedule.seatsAvailable;
                                    final isSoldOut = cap <= 0;
                                    final isSelected =
                                        schedule.id == selectedScheduleId;
                                    return ChoiceChip(
                                      label: Text(
                                        isSoldOut
                                            ? '$text (Hết chỗ)'
                                            : '$text (Còn $cap chỗ)',
                                      ),
                                      selected: isSelected,
                                      onSelected:
                                          isSoldOut
                                              ? null
                                              : (_) {
                                                if (cap > 0 &&
                                                    totalGuests() > cap) {
                                                  ScaffoldMessenger.of(
                                                    rootContext,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Chỉ còn $cap chỗ, vui lòng chọn ngày khác.',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                setState(
                                                  () =>
                                                      selectedScheduleId =
                                                          schedule.id,
                                                );
                                              },
                                      selectedColor: const Color(0xFFFFF2E8),
                                      labelStyle: TextStyle(
                                        color:
                                            isSelected
                                                ? const Color(0xFFFF5B00)
                                                : Colors.black87,
                                        fontWeight:
                                            isSoldOut ? FontWeight.w600 : null,
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
                            onChanged: (value) {
                              final newAdult = value.clamp(1, 20);
                              final cap =
                                  currentSchedule()?.seatsAvailable ?? 0;
                              if (cap > 0 && newAdult + childCount > cap) {
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Chỉ còn $cap chỗ, vui lòng chọn ngày khác.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(() => adultCount = newAdult);
                            },
                          ),
                          const SizedBox(height: 12),
                          PassengerCounter(
                            title: 'Trẻ em',
                            description: 'Dưới 12 tuổi',
                            value: childCount,
                            minValue: 0,
                            onChanged: (value) {
                              final newChild = value.clamp(0, 20);
                              final cap =
                                  currentSchedule()?.seatsAvailable ?? 0;
                              if (cap > 0 && adultCount + newChild > cap) {
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Chỉ còn $cap chỗ, vui lòng chọn ngày khác.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(() => childCount = newChild);
                            },
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
                                'Tạm tính',
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
