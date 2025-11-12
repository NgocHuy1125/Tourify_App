import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:tourify_app/features/booking/model/booking_model.dart';
import 'package:tourify_app/features/booking/presenter/trips_presenter.dart';
import 'package:tourify_app/features/home/view/all_tours_screen.dart';
import 'package:tourify_app/features/tour/view/tour_detail_page.dart';

enum _ReviewOutcome { created, updated, deleted }

final NumberFormat _vndFormatter = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);
final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

String _filterLabel(String key) {
  switch (key) {
    case 'all':
      return 'Tất cả';
    case 'pending_payment':
      return 'Chờ thanh toán';
    case 'confirmed':
      return 'Đã xác nhận';
    case 'completed':
      return 'Hoàn thành';
    case 'cancelled':
      return 'Đã hủy';
    default:
      return key;
  }
}

String _statusLabel(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('pending') || normalized.contains('await')) {
    return 'Chờ thanh toán';
  }
  if (normalized.contains('confirm')) {
    return 'Đã xác nhận';
  }
  if (normalized.contains('complete') || normalized.contains('finish')) {
    return 'Hoàn thành';
  }
  if (normalized.contains('cancel')) {
    return 'Đã hủy';
  }
  if (normalized.contains('process') || normalized.contains('review')) {
    return 'Đang xử lý';
  }
  return status;
}

String _formatCurrency(double? amount) {
  if (amount == null) return 'Đang cập nhật';
  return _vndFormatter.format(amount);
}

String _formatDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Chưa có lịch khởi hành';
  if (start != null && end != null) {
    final startText = _dateFormatter.format(start);
    final endText = _dateFormatter.format(end);
    if (startText == endText) return startText;
    return '$startText - $endText';
  }
  final single = start ?? end;
  return _dateFormatter.format(single!);
}

String _formatGuests(int adults, int children) {
  final parts = <String>[];
  if (adults > 0) parts.add('$adults người lớn');
  if (children > 0) parts.add('$children trẻ em');
  return parts.isEmpty ? 'Chưa có' : parts.join(' · ');
}

String? _reviewTimestamp(DateTime? date) {
  if (date == null) return null;
  return 'Gửi ngày ${_dateFormatter.format(date)}';
}

List<Widget> _buildRatingStars(int rating) {
  final normalized = rating.clamp(0, 5);
  return List.generate(
    5,
    (index) => Icon(
      index < normalized ? Icons.star : Icons.star_border,
      size: 18,
      color: const Color(0xFFFFB400),
    ),
  );
}

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripsPresenter>().loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<TripsPresenter>();
    final bookings = presenter.bookings;
    final isLoading = presenter.isLoading && bookings.isEmpty;
    final hasError = presenter.errorMessage.isNotEmpty && bookings.isEmpty;

    return RefreshIndicator(
      onRefresh: presenter.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _FilterBar(presenter: presenter),
          const SizedBox(height: 16),
          if (isLoading)
            const _LoadingPlaceholder()
          else if (hasError)
            _ErrorNotice(message: presenter.errorMessage, presenter: presenter)
          else if (bookings.isEmpty)
            const _EmptyState()
          else
            ...List.generate(bookings.length, (index) {
              final booking = bookings[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == bookings.length - 1 ? 0 : 16,
                ),
                child: _BookingCard(
                  booking: booking,
                  presenter: presenter,
                  onOpenReview:
                      () => _openReviewSheet(context, presenter, booking),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _openReviewSheet(
    BuildContext context,
    TripsPresenter presenter,
    BookingSummary booking,
  ) async {
    presenter.clearActionError();
    final existing = booking.review;
    final controller = TextEditingController(text: existing?.comment ?? '');
    int rating = existing?.rating ?? 5;
    bool submitting = false;

    final outcome = await showModalBottomSheet<_ReviewOutcome>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottomInset + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        existing == null
                            ? 'Đánh giá tour'
                            : 'Cập nhật đánh giá',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed:
                            submitting
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    booking.tour?.title ?? 'Tour của bạn',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      final filled = value <= rating;
                      return IconButton(
                        onPressed:
                            submitting
                                ? null
                                : () => setState(() => rating = value),
                        icon: Icon(
                          filled ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFB400),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    enabled: !submitting,
                    maxLines: 5,
                    minLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Cảm nhận của bạn',
                      hintText: 'Chia sẻ trải nghiệm sau chuyến đi...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (presenter.actionError.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      presenter.actionError,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (existing != null)
                        TextButton.icon(
                          onPressed:
                              submitting
                                  ? null
                                  : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (dialogContext) => AlertDialog(
                                            title: const Text('Xóa đánh giá'),
                                            content: const Text(
                                              'Bạn có chắc chắn muốn xóa đánh giá này?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      dialogContext,
                                                    ).pop(false),
                                                child: const Text('Hủy'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      dialogContext,
                                                    ).pop(true),
                                                child: const Text('Xóa'),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirmed == true) {
                                      setState(() => submitting = true);
                                      final success = await presenter
                                          .deleteReview(existing.id);
                                      setState(() => submitting = false);
                                      if (success && context.mounted) {
                                        Navigator.of(
                                          sheetContext,
                                        ).pop(_ReviewOutcome.deleted);
                                      }
                                    }
                                  },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Xóa đánh giá'),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed:
                            submitting
                                ? null
                                : () async {
                                  setState(() => submitting = true);
                                  final success = await presenter.submitReview(
                                    bookingId: booking.id,
                                    rating: rating,
                                    comment: controller.text.trim(),
                                    reviewId: existing?.id,
                                  );
                                  setState(() => submitting = false);
                                  if (success && context.mounted) {
                                    Navigator.of(sheetContext).pop(
                                      existing == null
                                          ? _ReviewOutcome.created
                                          : _ReviewOutcome.updated,
                                    );
                                  }
                                },
                        child:
                            submitting
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Lưu đánh giá'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    controller.dispose();

    if (outcome != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final message = switch (outcome) {
          _ReviewOutcome.created => 'Đã gửi đánh giá thành công.',
          _ReviewOutcome.updated => 'Đã cập nhật đánh giá thành công.',
          _ReviewOutcome.deleted => 'Đã xóa đánh giá.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.presenter});

  final TripsPresenter presenter;

  @override
  Widget build(BuildContext context) {
    final filters = TripsPresenter.filters;
    final selected = presenter.selectedFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (final filter in filters) ...[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(_filterLabel(filter.key)),
                selected: selected == filter.key,
                onSelected: (_) => presenter.selectFilter(filter.key),
                selectedColor: const Color(0xFFFF5B00),
                labelStyle: TextStyle(
                  color: selected == filter.key ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          OutlinedButton.icon(
            onPressed: presenter.isFetching ? null : presenter.refresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Làm mới'),
          ),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          height: 140,
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, required this.presenter});

  final String message;
  final TripsPresenter presenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Không thể tải chuyến đi',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: presenter.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.airplane_ticket_outlined,
            size: 48,
            color: Color(0xFFFF5B00),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa có chuyến đi nào',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy khám phá các hoạt động thú vị và đặt ngay để lưu giữ khoảnh khắc.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AllToursScreen()),
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5B00),
            ),
            child: const Text('Khám phá tour'),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.presenter,
    required this.onOpenReview,
  });

  final BookingSummary booking;
  final TripsPresenter presenter;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tour = booking.tour;
    final tourId = tour?.id ?? '';
    final destination = tour?.destination ?? '';
    final reference = booking.reference;
    final statusText = _statusLabel(booking.status);
    final statusColor = presenter.statusColor(booking.status);
    final review = booking.review;
    final canReview = booking.canReview || review != null;
    final hasTourId = tourId.isNotEmpty;
    final refundHistory = booking.refundRequests;
    final canRequestRefund = _canRequestRefund(booking, refundHistory);
    final invoice = booking.invoice;
    final hasInvoice = invoice != null;
    final canRequestInvoice = _canRequestInvoice(booking, hasInvoice);
    final totalDisplay = booking.totalPrice ?? booking.totalAmount;
    final discountAmount = booking.discountTotal ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverImage(imageUrl: tour?.mediaCover),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            tour?.title ?? 'Tour của bạn',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(label: statusText, color: statusColor),
                      ],
                    ),
                    if (destination.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        destination,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (reference != null && reference.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Mã đặt chỗ: $reference',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.date_range_outlined,
            label: 'Lịch trình',
            value: _formatDateRange(booking.startDate, booking.endDate),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.group_outlined,
            label: 'Số khách',
            value: _formatGuests(booking.adults, booking.children),
          ),
          if (totalDisplay != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Tổng chi phí',
              value: _formatCurrency(totalDisplay),
            ),
          ],
          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.local_offer_outlined,
              label: 'Khuyến mãi',
              value: '-${_formatCurrency(discountAmount)}',
              valueStyle: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF27AE60),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (booking.balanceDue != null && (booking.balanceDue ?? 0) > 0) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.warning_amber_rounded,
              label: 'Còn phải thanh toán',
              value: _formatCurrency(booking.balanceDue),
              valueStyle: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFE74C3C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (booking.amountPaid != null &&
              (booking.amountPaid ?? 0) > 0) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.verified_outlined,
              label: 'Đã thanh toán',
              value: _formatCurrency(booking.amountPaid),
            ),
          ],
          if (refundHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            _RefundHistoryList(
              requests: refundHistory,
              onConfirm: (request) => _confirmRefund(context, request),
            ),
          ],
          const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: hasTourId
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TourDetailPage(id: tourId),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Xem tour'),
              ),
            ),
            if (canReview)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onOpenReview,
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: Text(
                    review == null
                        ? 'Đánh giá tour'
                        : 'Chỉnh sửa đánh giá',
                  ),
                ),
              ),
            if (canRequestRefund)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openRefundRequestSheet(context),
                  icon: const Icon(Icons.account_balance_outlined),
                  label: const Text('Yêu cầu hoàn tiền'),
                ),
              ),
            if (hasInvoice)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showInvoiceDetails(context),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Xem hóa đơn'),
                ),
              )
            else if (canRequestInvoice)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openInvoiceRequestSheet(context),
                  icon: const Icon(Icons.receipt_outlined),
                  label: const Text('Xuất hóa đơn'),
                ),
              ),
          ],
        ),
          if (review != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              'Đánh giá của bạn',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ..._buildRatingStars(review.rating),
                const SizedBox(width: 8),
                Text(
                  '${review.rating}/5',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (review.comment.isNotEmpty)
              Text(review.comment, style: theme.textTheme.bodyMedium)
            else
              Text(
                'Bạn chưa để lại nhận xét.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            if (_reviewTimestamp(review.createdAt) != null) ...[
              const SizedBox(height: 6),
              Text(
                _reviewTimestamp(review.createdAt)!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  bool _canRequestRefund(BookingSummary booking, List<RefundRequest> history) {
    final status = booking.status.toLowerCase();
    final payment = booking.paymentStatus?.toLowerCase() ?? '';
    if (!(status.contains('cancel') && payment.contains('paid'))) {
      return false;
    }
    final hasActive = history.any((request) {
      final state = request.status.toLowerCase();
      return !(state.contains('reject') || state.contains('complete'));
    });
    return !hasActive;
  }

  bool _canRequestInvoice(BookingSummary booking, bool hasInvoice) {
    if (hasInvoice) return false;
    final status = booking.status.toLowerCase();
    final payment = booking.paymentStatus?.toLowerCase() ?? '';
    return status.contains('complete') && payment.contains('paid');
  }

  Future<void> _openRefundRequestSheet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final formKey = GlobalKey<FormState>();
    final accountNameCtrl = TextEditingController();
    final accountNumberCtrl = TextEditingController();
    final bankNameCtrl = TextEditingController();
    final branchCtrl = TextEditingController();
    final amountCtrl = TextEditingController(
      text: (booking.totalPrice ?? booking.totalAmount ?? 0).toStringAsFixed(0),
    );
    final noteCtrl = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final inset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, inset + 20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
        Row(
          children: [
            const Text(
              'Yêu cầu hoàn tiền',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
                        const Spacer(),
                        IconButton(
                          onPressed: submitting
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
        _LabeledField(
          controller: accountNameCtrl,
          label: 'Tên chủ tài khoản',
          hint: 'Ví dụ: NGUYEN VAN A',
          validator: (value) =>
              value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập tên chủ tài khoản'
                  : null,
        ),
                    const SizedBox(height: 12),
        _LabeledField(
          controller: accountNumberCtrl,
          label: 'Số tài khoản',
          hint: 'Nhập số tài khoản ngân hàng',
          keyboardType: TextInputType.number,
          validator: (value) =>
              value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập số tài khoản'
                  : null,
        ),
                    const SizedBox(height: 12),
        _LabeledField(
          controller: bankNameCtrl,
          label: 'Ngân hàng',
          hint: 'Ví dụ: Vietcombank',
          validator: (value) =>
              value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập tên ngân hàng'
                  : null,
        ),
                    const SizedBox(height: 12),
        _LabeledField(
          controller: branchCtrl,
          label: 'Chi nhánh',
          hint: 'Ví dụ: Chi nhánh Thủ Đức',
          validator: (value) =>
              value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập chi nhánh'
                  : null,
        ),
                    const SizedBox(height: 12),
        _LabeledField(
          controller: amountCtrl,
          label: 'Số tiền (VND)',
          hint: 'Để trống để hoàn toàn bộ số tiền',
          keyboardType: TextInputType.number,
        ),
                    const SizedBox(height: 12),
        _LabeledField(
          controller: noteCtrl,
          label: 'Ghi chú',
          hint: 'Thông tin bổ sung cho đối tác',
          maxLines: 3,
        ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                final parsedAmount = double.tryParse(
                                      amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
                                    ) ??
                                    (booking.totalPrice ?? booking.totalAmount ?? 0);
                                setState(() => submitting = true);
                                final result = await presenter.submitRefundRequest(
                                  bookingId: booking.id,
                                  accountName: accountNameCtrl.text.trim(),
                                  accountNumber: accountNumberCtrl.text.trim(),
                                  bankName: bankNameCtrl.text.trim(),
                                  bankBranch: branchCtrl.text.trim(),
                                  amount: parsedAmount,
                                  customerMessage: noteCtrl.text.trim().isEmpty
                                      ? null
                                      : noteCtrl.text.trim(),
                                );
                                setState(() => submitting = false);
                                if (result != null && context.mounted) {
                                  Navigator.of(sheetContext).pop();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã gửi yêu cầu hoàn tiền. Vui lòng chờ xử lý.'),
                                    ),
                                  );
                                } else if (presenter.actionError.isNotEmpty) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(presenter.actionError)),
                                  );
                                }
                              },
                        child: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Gửi yêu cầu'),
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

  Future<void> _confirmRefund(
    BuildContext context,
    RefundRequest request,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await presenter.confirmRefundRequest(request.id);
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xác nhận hoàn tiền.')),
      );
    } else if (presenter.actionError.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(presenter.actionError)),
      );
    }
  }

  Future<void> _openInvoiceRequestSheet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final taxCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String deliveryMethod = 'download';
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final inset = MediaQuery.of(context).viewInsets.bottom;
            final requireEmail = deliveryMethod == 'email';
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, inset + 20),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Xuất hóa đơn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed:
                                submitting
                                    ? null
                                    : () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        controller: nameCtrl,
                        label: 'Tên khách hàng / Doanh nghiệp',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập tên khách hàng'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        controller: taxCtrl,
                        label: 'Mã số thuế',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập mã số thuế'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        controller: addressCtrl,
                        label: 'Địa chỉ xuất hóa đơn',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập địa chỉ'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        controller: emailCtrl,
                        label: 'Email nhận hóa đơn',
                        hint: 'Bắt buộc nếu chọn gửi email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (!requireEmail) return null;
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Vui lòng nhập email';
                          final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!regex.hasMatch(text)) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Hình thức nhận',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: [
                          ChoiceChip(
                            label: const Text('Tải xuống trực tiếp'),
                            selected: deliveryMethod == 'download',
                            onSelected:
                                submitting
                                    ? null
                                    : (_) =>
                                        setState(() => deliveryMethod = 'download'),
                          ),
                          ChoiceChip(
                            label: const Text('Gửi qua email'),
                            selected: deliveryMethod == 'email',
                            onSelected:
                                submitting
                                    ? null
                                    : (_) =>
                                        setState(() => deliveryMethod = 'email'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setState(() => submitting = true);
                                  final result = await presenter.requestInvoice(
                                    bookingId: booking.id,
                                    customerName: nameCtrl.text.trim(),
                                    taxCode: taxCtrl.text.trim(),
                                    address: addressCtrl.text.trim(),
                                    email: emailCtrl.text.trim(),
                                    deliveryMethod: deliveryMethod,
                                  );
                                  setState(() => submitting = false);
                                  if (result != null) {
                                    if (context.mounted) {
                                      Navigator.of(sheetContext).pop();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            deliveryMethod == 'email'
                                                ? 'Hóa đơn sẽ được gửi qua email.'
                                                : 'Đã tạo hóa đơn thành công.',
                                          ),
                                        ),
                                      );
                                    }
                                  } else if (presenter.actionError.isNotEmpty) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(presenter.actionError),
                                      ),
                                    );
                                  }
                                },
                          child: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Gửi yêu cầu'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showInvoiceDetails(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    BookingInvoice? invoice = booking.invoice;

    if (invoice == null) {
      invoice = await presenter.fetchInvoice(booking.id);
      if (invoice == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Chưa có thông tin hóa đơn.')),
        );
        return;
      }
    }

    final info = invoice;

    await showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Hóa đơn điện tử',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Số hóa đơn',
                value: info.invoiceNumber.isNotEmpty
                    ? info.invoiceNumber
                    : 'Đang cập nhật',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.payments_outlined,
                label: 'Giá trị',
                value: _formatCurrency(info.amount),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.delivery_dining_outlined,
                label: 'Hình thức',
                value: info.deliveryMethod == 'email'
                    ? 'Gửi qua email'
                    : 'Tải về trực tiếp',
              ),
              const SizedBox(height: 16),
              if (info.downloadUrl != null && info.downloadUrl!.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openInvoiceDownload(context, info.downloadUrl!),
                    icon: const Icon(Icons.download),
                    label: const Text('Tải hóa đơn PDF'),
                  ),
                )
              else
                const Text(
                  'Hóa đơn sẽ được gửi qua email của bạn.',
                  style: TextStyle(color: Colors.black54),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openInvoiceDownload(
    BuildContext context,
    String url,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liên kết tải xuống không hợp lệ.')),
      );
      return;
    }
    final success = await launchUrlString(
      uri.toString(),
      mode: LaunchMode.externalApplication,
    );
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết tải hóa đơn.')),
      );
    }
  }
}
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                    valueStyle ??
                    theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RefundHistoryList extends StatelessWidget {
  const _RefundHistoryList({
    required this.requests,
    required this.onConfirm,
  });

  final List<RefundRequest> requests;
  final ValueChanged<RefundRequest> onConfirm;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch sử hoàn tiền',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...requests.map((request) {
          final status = request.status;
          final needsConfirm =
              status.toLowerCase().contains('await') ||
              status.toLowerCase().contains('customer');
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatCurrency(request.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RefundStatusChip(status: status),
                    const Spacer(),
                    Text(
                      request.currency,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                if (request.customerMessage?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    request.customerMessage!,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
                if (needsConfirm)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => onConfirm(request),
                      child: const Text('Xác nhận đã nhận tiền'),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _RefundStatusChip extends StatelessWidget {
  const _RefundStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor() {
    final normalized = status.toLowerCase();
    if (normalized.contains('pending') || normalized.contains('await')) {
      return const Color(0xFFF2994A);
    }
    if (normalized.contains('approve') || normalized.contains('process')) {
      return const Color(0xFF2F80ED);
    }
    if (normalized.contains('complete')) {
      return const Color(0xFF27AE60);
    }
    if (normalized.contains('reject')) {
      return const Color(0xFFE74C3C);
    }
    return const Color(0xFF4E54C8);
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: 96,
        width: 112,
        child:
            imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade500,
                        ),
                      ),
                )
                : Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.grey.shade500,
                  ),
                ),
      ),
    );
  }
}


