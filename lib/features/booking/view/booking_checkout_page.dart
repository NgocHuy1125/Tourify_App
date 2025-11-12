import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tourify_app/features/booking/model/booking_model.dart';
import 'package:tourify_app/features/booking/model/booking_repository.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class BookingCheckoutPage extends StatefulWidget {
  final TourDetail detail;
  final TourPackage package;
  final TourSchedule? schedule;
  final int adults;
  final int children;

  const BookingCheckoutPage({
    super.key,
    required this.detail,
    required this.package,
    this.schedule,
    this.adults = 1,
    this.children = 0,
  });

  @override
  State<BookingCheckoutPage> createState() => _BookingCheckoutPageState();
}

class _BookingCheckoutPageState extends State<BookingCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _contactName = TextEditingController();
  final _contactEmail = TextEditingController();
  final _contactPhone = TextEditingController();
  final _notes = TextEditingController();
  final _promotionCode = TextEditingController();

  late final List<_PassengerFormData> _passengers;

  bool _isSubmitting = false;
  String _selectedMethod = _PaymentMethod.sepay.id;

  double get _adultPrice => widget.package.adultPrice;
  double get _childPrice =>
      widget.package.childPrice ?? widget.package.adultPrice;

  double get _discountFactor => widget.detail.autoPromotionFactor;
  double get _discountedAdultPrice =>
      (_adultPrice * _discountFactor).clamp(0, _adultPrice);
  double get _discountedChildPrice =>
      (_childPrice * _discountFactor).clamp(0, _childPrice);

  double get _baseSubtotal =>
      (widget.adults * _adultPrice) + (widget.children * _childPrice);

  double get _totalAmount =>
      (widget.adults * _discountedAdultPrice) +
      (widget.children * _discountedChildPrice);

  @override
  void initState() {
    super.initState();
    _passengers = [
      for (var index = 0; index < widget.adults; index++)
        _PassengerFormData(type: 'adult'),
      for (var index = 0; index < widget.children; index++)
        _PassengerFormData(type: 'child'),
    ];
  }

  @override
  void dispose() {
    _contactName.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    _notes.dispose();
    _promotionCode.dispose();
    for (final passenger in _passengers) {
      passenger.dispose();
    }
    super.dispose();
  }

  Future<void> _showAwaitingConfirmationDialog(String message) async {
    if (!mounted) return;
    final trimmed = message.trim();
    final displayMessage =
        trimmed.isNotEmpty
            ? trimmed
            : 'Thanh toán đã được ghi nhận. Vui lòng chờ Tourify xác nhận.';

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Đang chờ xác nhận'),
            content: Text(displayMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin bắt buộc.'),
        ),
      );
      return;
    }

    final incompletePassenger = _passengers.indexWhere(
      (passenger) => !passenger.isValid,
    );
    if (incompletePassenger != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hành khách số ${incompletePassenger + 1} chưa điền đầy đủ thông tin.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final request = BookingRequest(
      tourId: widget.detail.id,
      scheduleId: widget.schedule?.id,
      packageId: widget.package.id,
      adults: widget.adults,
      children: widget.children,
      contactName: _contactName.text.trim(),
      contactEmail: _contactEmail.text.trim(),
      contactPhone: _contactPhone.text.trim(),
      paymentMethod: _selectedMethod,
      notes: _notes.text.trim(),
      passengers: _passengers.map((e) => e.toPassenger()).toList(),
      promotionCode: _promotionCode.text.trim(),
    );

    try {
      final repo = context.read<BookingRepository>();
      final response = await repo.createBooking(request);

      if (!mounted) return;

      final qrUrl = response.paymentQrUrl ?? '';
      final redirectUrl = response.paymentUrl ?? '';
      final fallbackMessage =
          response.message.isNotEmpty
              ? response.message
              : 'Thanh toán đã được ghi nhận. Vui lòng chờ Tourify xác nhận.';

      if (_selectedMethod == _PaymentMethod.sepay.id &&
          (qrUrl.isNotEmpty || redirectUrl.isNotEmpty)) {
        final acknowledged = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder:
              (_) => PaymentQRCodeSheet(
                amount: response.totalPrice ?? _totalAmount,
                subtotal: _totalAmount,
                discountTotal: response.discountTotal,
                promotions: response.promotions,
                bookingId: response.id,
                qrImageUrl: qrUrl,
                paymentUrl: redirectUrl,
              ),
        );

        if (acknowledged == true) {
          await _showAwaitingConfirmationDialog(fallbackMessage);
        }
      } else {
        await _showAwaitingConfirmationDialog(fallbackMessage);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().isNotEmpty
                ? error.toString()
                : 'Không thể tạo đơn đặt tour. Vui lòng thử lại.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán tour')),
      backgroundColor: const Color(0xFFF6F6F6),
      bottomNavigationBar: _CheckoutBottomBar(
        total: currency.format(_totalAmount),
        isBusy: _isSubmitting,
        onPay: _handleSubmit,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _BookingSummaryCard(
              detail: widget.detail,
              package: widget.package,
              schedule: widget.schedule,
              adults: widget.adults,
              children: widget.children,
              totalFormatted: currency.format(_totalAmount),
              subtotalFormatted:
                  _discountFactor < 1 ? currency.format(_baseSubtotal) : null,
              discountFormatted:
                  _discountFactor < 1
                      ? currency.format((_baseSubtotal - _totalAmount).clamp(0, double.infinity))
                      : null,
              autoPromotion: widget.detail.autoPromotion,
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Thông tin liên hệ'),
            const SizedBox(height: 12),
            _ContactField(
              controller: _contactName,
              label: 'Họ và tên',
              hint: 'Nguyễn Văn A',
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _ContactField(
              controller: _contactEmail,
              label: 'Email',
              hint: 'email@domain.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _ContactField(
              controller: _contactPhone,
              label: 'Số điện thoại',
              hint: '09xx xxx xxx',
              keyboardType: TextInputType.phone,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Danh sách hành khách'),
            const SizedBox(height: 12),
            ..._buildPassengerCards(),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Ghi chú cho nhà tổ chức'),
            const SizedBox(height: 12),
            _ContactField(
              controller: _notes,
              label: 'Nội dung',
              hint: 'Ví dụ: yêu cầu hóa đơn, dị ứng thực phẩm...',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Khuyến mãi'),
            const SizedBox(height: 12),
            _ContactField(
              controller: _promotionCode,
              label: 'Mã khuyến mãi (nếu có)',
              hint: 'SALE10',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 4),
            const Text(
              'Hệ thống sẽ tự động áp dụng thêm khuyến mãi phù hợp của tour.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Phương thức thanh toán'),
            const SizedBox(height: 12),
            ..._PaymentMethod.values.map(
              (method) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RadioListTile<String>(
                  value: method.id,
                  groupValue: _selectedMethod,
                  onChanged:
                      (value) => setState(
                        () => _selectedMethod = value ?? _selectedMethod,
                      ),
                  title: Text(method.title),
                  subtitle: Text(method.description),
                  secondary: Icon(method.icon, color: const Color(0xFFFF6B2C)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập thông tin.';
    }
    return null;
  }

  List<Widget> _buildPassengerCards() {
    final widgets = <Widget>[];
    var adultOrdinal = 0;
    var childOrdinal = 0;

    for (var index = 0; index < _passengers.length; index++) {
      final passenger = _passengers[index];
      final title =
          passenger.type == 'adult'
              ? 'Người lớn #${++adultOrdinal}'
              : 'Trẻ em #${++childOrdinal}';

      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: index == _passengers.length - 1 ? 0 : 12,
          ),
          child: _PassengerFormCard(title: title, data: passenger),
        ),
      );
    }

    return widgets;
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  final String total;
  final bool isBusy;
  final VoidCallback onPay;

  const _CheckoutBottomBar({
    required this.total,
    required this.isBusy,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isBusy ? null : onPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B2C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child:
                isBusy
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text(
                      'Thanh toán ngay',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
          ),
        ],
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  final TourDetail detail;
  final TourPackage package;
  final TourSchedule? schedule;
  final int adults;
  final int children;
  final String totalFormatted;
  final String? subtotalFormatted;
  final String? discountFormatted;
  final AutoPromotion? autoPromotion;

  const _BookingSummaryCard({
    required this.detail,
    required this.package,
    required this.schedule,
    required this.adults,
    required this.children,
    required this.totalFormatted,
    this.subtotalFormatted,
    this.discountFormatted,
    this.autoPromotion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    String scheduleText() {
      if (schedule == null) return 'Chưa chọn lịch cố định';
      final start = dateFormat.format(schedule!.startDate);
      final end = dateFormat.format(schedule!.endDate);
      return '$start – $end';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A3C), Color(0xFFFF6B2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Gói dịch vụ',
            value: package.name,
            valueColor: Colors.white,
          ),
          _SummaryRow(
            label: 'Lịch khởi hành',
            value: scheduleText(),
            valueColor: Colors.white70,
          ),
          _SummaryRow(
            label: 'Số khách',
            value: '$adults người lớn · $children trẻ em',
            valueColor: Colors.white70,
          ),
          const Divider(color: Colors.white24, height: 24),
          if (subtotalFormatted != null)
            _SummaryRow(
              label: 'Tạm tính',
              value: subtotalFormatted!,
              valueColor: Colors.white70,
            ),
          if (discountFormatted != null)
            _SummaryRow(
              label: 'Ưu đãi ước tính',
              value: '-$discountFormatted',
              valueColor: Colors.white70,
            ),
          Text(
            'Tổng cộng $totalFormatted',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (autoPromotion != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                autoPromotion?.description ??
                    'Đã áp dụng khuyến mãi ${autoPromotion?.code}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w600,
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

class _ContactField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const _ContactField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _PassengerFormCard extends StatefulWidget {
  final String title;
  final _PassengerFormData data;

  const _PassengerFormCard({required this.title, required this.data});

  @override
  State<_PassengerFormCard> createState() => _PassengerFormCardState();
}

class _PassengerFormCardState extends State<_PassengerFormCard> {
  final _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initialDate =
        widget.data.dateOfBirth ?? now.subtract(const Duration(days: 365 * 18));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Xong',
    );
    if (picked != null) {
      setState(() => widget.data.dateOfBirth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.data.type == 'adult'
                      ? Icons.person_pin_circle_outlined
                      : Icons.child_care_outlined,
                  color: const Color(0xFFFF6B2C),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.data.nameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên hành khách',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập họ tên.'
                          : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: widget.data.gender,
              decoration: const InputDecoration(
                labelText: 'Giới tính',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Nam')),
                DropdownMenuItem(value: 'female', child: Text('Nữ')),
                DropdownMenuItem(value: 'other', child: Text('Khác')),
              ],
              onChanged: (value) => setState(() => widget.data.gender = value),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDob,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  widget.data.dateOfBirth != null
                      ? _dateFormat.format(widget.data.dateOfBirth!)
                      : 'Chưa chọn',
                  style: TextStyle(
                    color:
                        widget.data.dateOfBirth != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.data.documentController,
              decoration: const InputDecoration(
                labelText: 'Số giấy tờ (CMND/CCCD/Hộ chiếu)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerFormData {
  final String type;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController documentController = TextEditingController();
  String? gender;
  DateTime? dateOfBirth;

  _PassengerFormData({required this.type});

  bool get isValid => nameController.text.trim().isNotEmpty;

  BookingPassenger toPassenger() {
    return BookingPassenger(
      type: type,
      fullName: nameController.text.trim(),
      gender: gender,
      dateOfBirth: dateOfBirth,
      documentNumber:
          documentController.text.trim().isEmpty
              ? null
              : documentController.text.trim(),
    );
  }

  void dispose() {
    nameController.dispose();
    documentController.dispose();
  }
}

class _PaymentMethod {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _PaymentMethod({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  static const sepay = _PaymentMethod(
    id: 'sepay',
    title: 'Thanh toán QR Sepay',
    description: 'Quét mã QR và hoàn tất trong vòng 15 phút.',
    icon: Icons.qr_code_2_rounded,
  );

  static const offline = _PaymentMethod(
    id: 'offline',
    title: 'Thanh toán tại quầy',
    description: 'Giữ chỗ 24 giờ và thanh toán trực tiếp tại văn phòng.',
    icon: Icons.storefront_outlined,
  );

  static const values = [sepay, offline];
}

class PaymentQRCodeSheet extends StatelessWidget {
  const PaymentQRCodeSheet({
    super.key,
    required this.amount,
    required this.bookingId,
    this.qrImageUrl,
    this.paymentUrl,
    this.promotions = const [],
    this.discountTotal,
    this.subtotal,
  });

  final double amount;
  final String bookingId;
  final String? qrImageUrl;
  final String? paymentUrl;
  final List<AppliedPromotion> promotions;
  final double? discountTotal;
  final double? subtotal;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quét QR để thanh toán',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFFFF5ED),
            ),
            child: _buildQrWidget(),
          ),
          const SizedBox(height: 16),
          Text('Mã đơn: $bookingId'),
          const SizedBox(height: 6),
          Text(
            'Số tiền: ${currency.format(amount)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildBreakdown(currency),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B2C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 42,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text('Tôi đã thanh toán'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrWidget() {
    final directSource = qrImageUrl?.trim();
    if (directSource != null && directSource.isNotEmpty) {
      return _buildQrFromSource(directSource);
    }

    final fallback = paymentUrl?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return _buildGeneratedQr(fallback);
    }

    return _buildPlaceholderQr();
  }

  Widget _buildBreakdown(NumberFormat currency) {
    final discount = discountTotal ?? 0;
    if ((promotions.isEmpty) && (discount <= 0) && (subtotal == null)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtotal != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tạm tính', style: TextStyle(color: Colors.black54)),
              Text(currency.format(subtotal)),
            ],
          ),
        if (promotions.isNotEmpty || discount > 0) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Khuyến mãi', style: TextStyle(color: Colors.black54)),
              Text(
                '-${currency.format(discount > 0 ? discount : promotions.fold<double>(0, (sum, promo) => sum + promo.discountAmount))}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
          if (promotions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: promotions.map((promo) {
                  final amount = currency.format(promo.discountAmount);
                  return Text(
                    '${promo.code}: -$amount',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildQrFromSource(String source) {
    if (source.startsWith('data:image')) {
      final commaIndex = source.indexOf(',');
      final data =
          commaIndex != -1 ? source.substring(commaIndex + 1) : source;
      final widget = _buildBase64QrImage(data);
      if (widget != null) return widget;
    } else if (_looksLikeBase64(source)) {
      final widget = _buildBase64QrImage(source);
      if (widget != null) return widget;
    }

    return _buildNetworkQrImage(source, fallbackData: source);
  }

  Widget? _buildBase64QrImage(String data) {
    try {
      final normalized = data.replaceAll(RegExp(r'\s'), '');
      final bytes = base64Decode(normalized);
      return _buildImageFromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  Widget _buildNetworkQrImage(String url, {String? fallbackData}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        height: 220,
        width: 220,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox(
            height: 220,
            width: 220,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (_, __, ___) {
          if (fallbackData != null && fallbackData.isNotEmpty) {
            return _buildGeneratedQr(fallbackData);
          }
          return _buildPlaceholderIcon();
        },
      ),
    );
  }

  Widget _buildImageFromBytes(List<int> bytes) {
    final buffer = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(
        buffer,
        height: 220,
        width: 220,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildGeneratedQr(String data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: 220,
      ),
    );
  }

  Widget _buildPlaceholderQr() {
    return const SizedBox(
      height: 220,
      width: 220,
      child: Center(child: _PaymentQrPlaceholderIcon()),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const _PaymentQrPlaceholderIcon();
  }

  bool _looksLikeBase64(String source) {
    if (source.length < 60) return false;
    final normalized = source.replaceAll(RegExp(r'\s'), '');
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    return base64Pattern.hasMatch(normalized);
  }
}

class _PaymentQrPlaceholderIcon extends StatelessWidget {
  const _PaymentQrPlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.primary;
    return Icon(
      Icons.qr_code_2_rounded,
      size: 200,
      color: baseColor.withAlpha(153),
    );
  }
}
