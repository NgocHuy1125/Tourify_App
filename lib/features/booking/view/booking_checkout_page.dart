import 'package:flutter/material.dart';
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

  late final List<_PassengerFormData> _passengers;

  bool _isSubmitting = false;
  String _selectedMethod = _PaymentMethod.sepay.id;

  bool get _requiresDocument =>
      widget.detail.requiresPassport || widget.detail.requiresVisa;
  int? get _childAgeLimit => widget.detail.childAgeLimit;

  double get _adultPrice => widget.package.adultPrice;
  double get _childPrice =>
      widget.package.childPrice ?? widget.package.adultPrice;
  double get _totalAmount =>
      (widget.adults * _adultPrice) + (widget.children * _childPrice);

  @override
  void initState() {
    super.initState();
    _passengers = [
      for (var index = 0; index < widget.adults; index++)
        _PassengerFormData(type: 'adult', requiresDocument: _requiresDocument),
      for (var index = 0; index < widget.children; index++)
        _PassengerFormData(
          type: 'child',
          requiresDocument: _requiresDocument,
          childAgeLimit: _childAgeLimit,
        ),
    ];
  }

  @override
  void dispose() {
    _contactName.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    _notes.dispose();
    for (final passenger in _passengers) {
      passenger.dispose();
    }
    super.dispose();
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

    final today = DateTime.now();
    for (var index = 0; index < _passengers.length; index++) {
      final message = _passengers[index].validate(today);
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hành khách số ${index + 1}: $message')),
        );
        return;
      }
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
    );

    try {
      final repo = context.read<BookingRepository>();
      final response = await repo.createBooking(request);

      if (!mounted) return;

      if (_selectedMethod == _PaymentMethod.sepay.id &&
          (response.paymentUrl ?? '').isNotEmpty) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder:
              (_) => PaymentQRCodeSheet(
                paymentUrl: response.paymentUrl!,
                amount: _totalAmount,
                bookingId: response.id,
              ),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Đặt tour thành công'),
                content: Text(
                  response.message.isNotEmpty
                      ? response.message
                      : 'Chúng tôi sẽ liên hệ để xác nhận trong thời gian sớm nhất.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
        );
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
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Thông tin liên hệ'),
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
            const _SectionTitle(title: 'Danh sách hành khách'),
            const SizedBox(height: 12),
            ..._buildPassengerCards(),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Ghi chú cho nhà tổ chức'),
            const SizedBox(height: 12),
            _ContactField(
              controller: _notes,
              label: 'Nội dung',
              hint: 'Ví dụ: yêu cầu hóa đơn, dị ứng thực phẩm...',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Phương thức thanh toán'),
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
            color: Colors.black.withOpacity(0.08),
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

  const _BookingSummaryCard({
    required this.detail,
    required this.package,
    required this.schedule,
    required this.adults,
    required this.children,
    required this.totalFormatted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    String scheduleText() {
      if (schedule == null) return 'Chưa chọn lịch cố định';
      final start = dateFormat.format(schedule!.startDate);
      final end = dateFormat.format(schedule!.endDate);
      return '$start - $end';
    }

    final typeLabel =
        detail.type == 'international' ? 'Tour quốc tế' : 'Tour nội địa';
    final docLabel =
        detail.requiresPassport || detail.requiresVisa
            ? [
              if (detail.requiresPassport) 'Cần hộ chiếu',
              if (detail.requiresVisa) 'Cần visa',
            ].join(' · ')
            : 'Không yêu cầu giấy tờ đặc biệt';
    final childLabel =
        detail.childAgeLimit != null
            ? 'Trẻ em ≤ ${detail.childAgeLimit} tuổi'
            : 'Không giới hạn độ tuổi trẻ em';

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
            value: '$adults người lớn & $children trẻ em',
            valueColor: Colors.white70,
          ),
          _SummaryRow(
            label: 'Loại tour',
            value: typeLabel,
            valueColor: Colors.white70,
          ),
          _SummaryRow(
            label: 'Quy định giấy tờ',
            value: docLabel,
            valueColor: Colors.white70,
          ),
          _SummaryRow(
            label: 'Độ tuổi trẻ em',
            value: childLabel,
            valueColor: Colors.white70,
          ),
          const Divider(color: Colors.white24, height: 24),
          Text(
            'Tổng cộng $totalFormatted',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
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
            width: 120,
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
    final requiresDocument = widget.data.requiresDocument;
    final childLimit = widget.data.childAgeLimit;

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
              onTap: widget.data.type == 'child' ? _pickDob : _pickDob,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText:
                      widget.data.type == 'child' ? 'Ngày sinh *' : 'Ngày sinh',
                  border: const OutlineInputBorder(),
                ),
                child: Text(
                  widget.data.dateOfBirth != null
                      ? _dateFormat.format(widget.data.dateOfBirth!)
                      : widget.data.type == 'child'
                      ? 'Chưa chọn'
                      : 'Không bắt buộc',
                  style: TextStyle(
                    color:
                        widget.data.dateOfBirth != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            if (widget.data.type == 'child' && childLimit != null) ...[
              const SizedBox(height: 6),
              Text(
                'Yêu cầu: trẻ em không vượt quá $childLimit tuổi.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.data.documentController,
              decoration: InputDecoration(
                labelText:
                    requiresDocument
                        ? 'Số giấy tờ (CMND/CCCD/Hộ chiếu) *'
                        : 'Số giấy tờ (CMND/CCCD/Hộ chiếu)',
                helperText:
                    requiresDocument
                        ? 'Bắt buộc vì tour yêu cầu hộ chiếu hoặc visa.'
                        : 'Có thể bỏ trống nếu không cần cung cấp.',
                border: const OutlineInputBorder(),
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
  final bool requiresDocument;
  final int? childAgeLimit;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController documentController = TextEditingController();
  String? gender;
  DateTime? dateOfBirth;

  _PassengerFormData({
    required this.type,
    required this.requiresDocument,
    this.childAgeLimit,
  });

  String? validate(DateTime today) {
    if (nameController.text.trim().isEmpty) {
      return 'Vui lòng nhập họ tên.';
    }

    if (type == 'child') {
      if (dateOfBirth == null) {
        return 'Cần chọn ngày sinh cho trẻ em.';
      }
      if (childAgeLimit != null) {
        final age = _calculateAge(dateOfBirth!, today);
        if (age > childAgeLimit!) {
          return 'Tuổi vượt quá giới hạn ${childAgeLimit!} tuổi.';
        }
      }
    }

    if (requiresDocument && documentController.text.trim().isEmpty) {
      return 'Cần nhập số giấy tờ cho tour này.';
    }

    return null;
  }

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

  int _calculateAge(DateTime birthDate, DateTime today) {
    var age = today.year - birthDate.year;
    final hasHadBirthday =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hasHadBirthday) age--;
    return age;
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
  final String paymentUrl;
  final double amount;
  final String bookingId;

  const PaymentQRCodeSheet({
    super.key,
    required this.paymentUrl,
    required this.amount,
    required this.bookingId,
  });

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
            child: QrImageView(
              data: paymentUrl,
              version: QrVersions.auto,
              size: 220,
            ),
          ),
          const SizedBox(height: 16),
          Text('Mã đơn: $bookingId'),
          const SizedBox(height: 6),
          Text(
            'Số tiền: ${currency.format(amount)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B2C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: const Text('Tôi đã thanh toán'),
          ),
        ],
      ),
    );
  }
}
