import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'package:tourify_app/core/widgets/login_required_view.dart';
import 'package:tourify_app/features/booking/model/booking_model.dart';
import 'package:tourify_app/features/booking/presenter/trips_presenter.dart';
import 'package:tourify_app/features/booking/view/booking_checkout_page.dart';
import 'package:tourify_app/features/home/view/all_tours_screen.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/tour/view/tour_detail_page.dart';

enum _ReviewOutcome { created, updated, deleted }

enum _BookingStage {
  awaitingPayment,
  awaitingConfirmation,
  completed,
  cancelled,
  processing,
}

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

_BookingStage _bookingStageFor(BookingSummary booking) {
  final status = booking.status.toLowerCase();
  final payment = booking.paymentStatus?.toLowerCase() ?? '';
  final hasPaid =
      _isBookingPaid(booking) ||
      payment.contains('paid') ||
      payment.contains('success') ||
      payment.contains('refunded');

  if (status.contains('cancel')) return _BookingStage.cancelled;
  if (status.contains('complete') || status.contains('finish')) {
    return _BookingStage.completed;
  }

  if (status.contains('pending') || status.contains('await')) {
    if (hasPaid) return _BookingStage.awaitingConfirmation;
    return _BookingStage.awaitingPayment;
  }

  if (status.contains('confirm') || status.contains('process')) {
    if (hasPaid) return _BookingStage.awaitingConfirmation;
    return _BookingStage.awaitingPayment;
  }

  if (status.contains('cancell') && payment.contains('pending')) {
    return _BookingStage.awaitingPayment;
  }

  if (!hasPaid &&
      (payment.contains('pending') ||
          payment.contains('await') ||
          payment.contains('unpaid') ||
          payment.isEmpty)) {
    return _BookingStage.awaitingPayment;
  }

  if (hasPaid) return _BookingStage.awaitingConfirmation;
  return _BookingStage.processing;
}

bool _isBookingPaid(BookingSummary booking) {
  final paymentStatus = booking.paymentStatus?.toLowerCase() ?? '';
  if (paymentStatus.contains('paid') || paymentStatus.contains('success')) {
    return true;
  }
  if ((booking.amountPaid ?? 0) > 0) return true;
  return booking.payments.any((payment) {
    final status = payment.status.toLowerCase();
    return status.contains('paid') ||
        status.contains('success') ||
        status.contains('complete');
  });
}

String _bookingStageLabel(_BookingStage stage) {
  switch (stage) {
    case _BookingStage.awaitingPayment:
      return 'Chờ thanh toán';
    case _BookingStage.awaitingConfirmation:
      return 'Chờ xác nhận';
    case _BookingStage.completed:
      return 'Hoàn thành';
    case _BookingStage.cancelled:
      return 'Đã hủy';
    case _BookingStage.processing:
      return 'Đang xử lý';
  }
}

Color _bookingStageColor(_BookingStage stage) {
  switch (stage) {
    case _BookingStage.awaitingPayment:
      return const Color(0xFFE67E22);
    case _BookingStage.awaitingConfirmation:
      return const Color(0xFFF2994A);
    case _BookingStage.completed:
      return const Color(0xFF27AE60);
    case _BookingStage.cancelled:
      return const Color(0xFFE74C3C);
    case _BookingStage.processing:
      return const Color(0xFF2F80ED);
  }
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

String _localizedError(String raw) {
  if (raw.isEmpty) return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  var message = raw;
  const prefix = 'Exception: ';
  if (message.startsWith(prefix)) {
    message = message.substring(prefix.length);
  }
  message = message.trim();
  final lower = message.toLowerCase();
  if (lower.contains('account name must match booking contact name')) {
    return 'Tên chủ tài khoản phải trùng với tên liên hệ của đơn đặt tour.';
  }
  if (lower.contains('booking can no longer be cancelled')) {
    return 'Đơn này không thể hủy nữa. Vui lòng liên hệ hỗ trợ.';
  }
  if (message.isEmpty) return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  return message;
}

String _refundStatusLabel(String raw) {
  final status = raw.toLowerCase();
  if (status.contains('await') || status.contains('customer')) {
    return 'Chờ bạn xác nhận';
  }
  if (status.contains('pending') || status.contains('process')) {
    return 'Đang xử lý';
  }
  if (status.contains('complete') || status.contains('success')) {
    return 'Đã hoàn tất';
  }
  if (status.contains('reject') || status.contains('fail')) {
    return 'Đã bị từ chối';
  }
  return raw;
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
  late final AuthNotifier _authNotifier;
  late final VoidCallback _authListener;

  @override
  void initState() {
    super.initState();
    _authNotifier = context.read<AuthNotifier>();
    _authListener = _onAuthChanged;
    _authNotifier.addListener(_authListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onAuthChanged();
    });
  }

  @override
  void dispose() {
    _authNotifier.removeListener(_authListener);
    super.dispose();
  }

  void _onAuthChanged() {
    final presenter = context.read<TripsPresenter>();
    if (_authNotifier.isLoggedIn) {
      presenter.loadInitial();
    } else {
      presenter.resetForGuest();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthNotifier>().isLoggedIn;
    if (!isLoggedIn) {
      return const LoginRequiredView(
        title: 'Đăng nhập để xem chuyến đi',
        message:
            'Vui lòng đăng nhập để theo dõi đơn hàng và yêu cầu của bạn.',
        icon: Icons.card_travel_outlined,
      );
    }
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

    _ReviewOutcome? outcome;
    try {
      outcome = await showModalBottomSheet<_ReviewOutcome>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;
              return Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomInset + 16),
                child: SingleChildScrollView(
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
                            onPressed: submitting
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
                            onPressed: submitting
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
                          _localizedError(presenter.actionError),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (existing != null)
                            TextButton.icon(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      final confirmed =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) =>
                                            AlertDialog(
                                          title: const Text('Xóa đánh giá'),
                                          content: const Text(
                                            'Bạn có chắc chắn muốn xóa đánh giá này?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(dialogContext)
                                                      .pop(false),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(dialogContext)
                                                      .pop(true),
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
                                          Navigator.of(sheetContext)
                                              .pop(_ReviewOutcome.deleted);
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Xóa đánh giá'),
                            ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: submitting
                                ? null
                                : () async {
                                    setState(() => submitting = true);
                                    final success =
                                        await presenter.submitReview(
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
                            child: submitting
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
                ),
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }

    if (outcome != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final message = switch (outcome!) {
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
    this.expanded = false,
  });

  final BookingSummary booking;
  final TripsPresenter presenter;
  final VoidCallback onOpenReview;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tour = booking.tour;
    final tourId = tour?.id ?? '';
    final destination = tour?.destination ?? '';
    final reference = booking.reference;
    final stage = _bookingStageFor(booking);
    final statusText = _bookingStageLabel(stage);
    final statusColor = _bookingStageColor(stage);
    final review = booking.review;
    final canReview = booking.canReview || review != null;
    final hasTourId = tourId.isNotEmpty;
    final refundHistory = booking.refundRequests;
    final canRequestRefund = _canRequestRefund(booking, refundHistory);
    final invoice = booking.invoice;
    final hasInvoice = invoice != null;
    final canRequestInvoice = _canRequestInvoice(booking, hasInvoice);
    final payments = booking.payments;
    final canCancel = _canCancelBooking(booking);
    final isCancelled = booking.status.toLowerCase().contains('cancel');
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
        if (isCancelled) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Tour đã bị hủy. Voucher hoặc hoàn tiền (nếu có) đã được gửi qua email của bạn.',
              style: TextStyle(
                color: Color(0xFFBF360C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
        if (payments.isNotEmpty && expanded) ...[
            const SizedBox(height: 16),
            _PaymentBreakdown(payments: payments),
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
            if (!expanded)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openBookingDetail(context),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Chi tiết đơn hàng'),
                ),
              ),
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
            if (_canTriggerPayLater(booking))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handlePayLater(context),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Thanh toán'),
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
            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancelBooking(context),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFE53935),
                  ),
                  label: const Text('Hủy tour'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
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

  bool _canCancelBooking(BookingSummary booking) {
    final status = booking.status.toLowerCase();
    if (status.contains('cancel') || status.contains('complete')) {
      return false;
    }
    return true;
  }

  bool _canTriggerPayLater(BookingSummary booking) {
    if (booking.status.toLowerCase().contains('cancel')) return false;
    if (_isBookingPaid(booking)) return false;
    final payment = booking.paymentStatus?.toLowerCase() ?? '';
    if (payment.contains('unpaid') ||
        payment.contains('pending') ||
        payment.contains('await')) {
      return true;
    }
    if (payment.isEmpty &&
        (booking.amountPaid ?? 0) <= 0 &&
        (booking.balanceDue == null || booking.balanceDue! > 0)) {
      return true;
    }
    return false;
  }

  Future<void> _openRefundRequestSheet(BuildContext context) async {
    final data = await _showRefundFormSheet(context);
    if (data == null || !context.mounted) return;
    await _submitRefundRequest(context, data);
  }

  Future<_RefundFormData?> _showRefundFormSheet(
    BuildContext context, {
    _RefundFormData? initial,
  }) async {
    final formKey = GlobalKey<FormState>();
    final defaults = initial ??
        _RefundFormData(
          accountName: booking.contactName ?? '',
          accountNumber: '',
          bankName: '',
          bankBranch: '',
          amount: booking.totalPrice ?? booking.totalAmount ?? 0,
          currency: 'VND',
          note: '',
        );

    final accountNameCtrl = TextEditingController(text: defaults.accountName);
    final accountNumberCtrl = TextEditingController(text: defaults.accountNumber);
    final bankNameCtrl = TextEditingController(text: defaults.bankName);
    final branchCtrl = TextEditingController(text: defaults.bankBranch);
    final amountCtrl = TextEditingController(
      text: defaults.amount.toStringAsFixed(0),
    );
    final noteCtrl = TextEditingController(text: defaults.note ?? '');

    final result = await showModalBottomSheet<_RefundFormData>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Yêu cầu hoàn tiền',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    controller: accountNameCtrl,
                    label: 'Tên chủ tài khoản',
                    hint: 'Ví dụ: NGUYEN VAN A',
                    readOnly: true,
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập tên chủ tài khoản'
                            : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tên chủ tài khoản phải trùng với tên liên hệ của đơn đặt tour.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
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
                    readOnly: true,
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
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.of(sheetContext).pop(
                          _RefundFormData(
                            accountName: accountNameCtrl.text.trim(),
                            accountNumber: accountNumberCtrl.text.trim(),
                            bankName: bankNameCtrl.text.trim(),
                            bankBranch: branchCtrl.text.trim(),
                            amount: defaults.amount,
                            currency: defaults.currency,
                            note: noteCtrl.text.trim().isEmpty
                                ? null
                                : noteCtrl.text.trim(),
                          ),
                        );
                      },
                      child: const Text('Tiếp tục'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    accountNameCtrl.dispose();
    accountNumberCtrl.dispose();
    bankNameCtrl.dispose();
    branchCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();

    accountNameCtrl.dispose();
    accountNumberCtrl.dispose();
    bankNameCtrl.dispose();
    branchCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();

    return result;
  }

  Future<void> _submitRefundRequest(
    BuildContext context,
    _RefundFormData data,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final result = await presenter.submitRefundRequest(
      bookingId: booking.id,
      accountName: data.accountName,
      accountNumber: data.accountNumber,
      bankName: data.bankName,
      bankBranch: data.bankBranch,
      amount: data.amount,
      customerMessage: data.note,
    );
    if (context.mounted) {
      rootNavigator.pop();
      if (result != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Yêu cầu hoàn tiền đã gửi. Vui lòng chờ xác nhận.'),
          ),
        );
      } else if (presenter.actionError.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(_localizedError(presenter.actionError))),
        );
      }
    }
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
        SnackBar(content: Text(_localizedError(presenter.actionError))),
      );
    }
  }

  Future<void> _openInvoiceRequestSheet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: booking.contactName ?? '');
    final taxCtrl = TextEditingController();
    final addressCtrl = TextEditingController(
      text: booking.tour?.destination ?? '',
    );
    final emailCtrl = TextEditingController(text: booking.contactEmail ?? '');
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
                        hint: 'Ví dụ: Đinh Huy hoặc Công ty ABC',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập tên khách hàng'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        controller: taxCtrl,
                        label: 'Mã số thuế',
                        hint: 'Ví dụ: 0101234567',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập mã số thuế'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        controller: addressCtrl,
                        label: 'Địa chỉ xuất hóa đơn',
                        hint: 'Ví dụ: Số 1 Tràng Tiền, Hoàn Kiếm, Hà Nội',
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
                            label: const Text('Tải về trong ứng dụng'),
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
                                        content: Text(
                                          _localizedError(presenter.actionError),
                                        ),
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
    nameCtrl.dispose();
    taxCtrl.dispose();
    addressCtrl.dispose();
    emailCtrl.dispose();
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

  bool _requiresRefundBeforeCancel(BookingSummary booking) {
    final status = booking.status.toLowerCase();
    return _isBookingPaid(booking) &&
        (status.contains('confirm') || status.contains('processing') || status.contains('await'));
  }

  Future<void> _confirmCancelBooking(BuildContext context) async {
    _RefundFormData? pendingRefund;
    if (_requiresRefundBeforeCancel(booking)) {
      pendingRefund = await _showRefundFormSheet(context);
      if (pendingRefund == null) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy tour'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy tour này? Chính sách hoàn tiền sẽ áp dụng theo quy định của đối tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Giữ tour'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hủy tour'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    BookingCancellationResult? result;
    try {
      result = await presenter.cancelBooking(booking.id);
    } catch (_) {
      // presenter will expose actionError; handle below
    } finally {
      if (rootNavigator.mounted) {
        rootNavigator.pop();
      }
    }

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (result == null) {
      final errorMessage = presenter.actionError.isNotEmpty
          ? _localizedError(presenter.actionError)
          : 'Không thể hủy tour ngay lúc này. Vui lòng thử lại sau.';
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    final BookingCancellationResult successResult = result;
    final refund = successResult.refund;
    String? refundRateText;
    if (refund != null && refund.rate != null) {
      final rate = refund.rate!;
      final normalized = rate > 1 ? rate : rate * 100;
      refundRateText = 'Tỷ lệ hoàn: ${normalized.toStringAsFixed(0)}%';
    }
    final refundPolicyText = refund != null && refund.policyDaysBefore != null
        ? 'Chính sách: trước ${refund.policyDaysBefore} ngày khởi hành'
        : null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đã hủy tour'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(successResult.message),
            if (refund != null) ...[
              const SizedBox(height: 12),
              if (refund.amount != null) ...[
                const Text(
                  'Số tiền dự kiến hoàn:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(_formatCurrency(refund.amount)),
              ],
              if (refundRateText != null) ...[
                const SizedBox(height: 6),
                Text(refundRateText),
              ],
              if (refundPolicyText != null) ...[
                const SizedBox(height: 6),
                Text(refundPolicyText),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (pendingRefund != null) {
      await _submitRefundRequest(context, pendingRefund);
      return;
    }

    if (_isBookingPaid(booking)) {
      await _openRefundRequestSheet(context);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(successResult.message)));
    }
  }



  Future<void> _openBookingDetail(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => BookingDetailPage(
              booking: booking,
              presenter: presenter,
              onOpenReview: onOpenReview,
            ),
      ),
    );
  }

  Future<void> _handlePayLater(BuildContext context) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    BookingPaymentIntent? intent;
    try {
      intent = await presenter.payLater(booking.id);
    } finally {
      if (rootNavigator.mounted) {
        rootNavigator.pop();
      }
    }

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (intent == null) {
      final errorMessage =
          presenter.actionError.isNotEmpty
              ? _localizedError(presenter.actionError)
              : 'Khong the tao lien ket thanh toan. Vui long thu lai.';
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    final BookingPaymentIntent confirmedIntent = intent;
    final paymentUrl = confirmedIntent.paymentUrl?.trim() ?? '';
    final paymentQr = confirmedIntent.paymentQrUrl?.trim() ?? '';

    if (paymentUrl.isEmpty && paymentQr.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            confirmedIntent.status.isNotEmpty
                ? confirmedIntent.status
                : 'Da tao yeu cau thanh toan. Vui long kiem tra email.',
          ),
        ),
      );
      return;
    }

    final subtotal =
        booking.totalAmount ?? booking.totalPrice ?? confirmedIntent.amount;

    final bool? acknowledged = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => PaymentQRCodeSheet(
                amount: confirmedIntent.amount,
                subtotal: subtotal,
                discountTotal: booking.discountTotal,
                promotions: booking.promotions,
                bookingId: booking.id,
                qrImageUrl: paymentQr.isNotEmpty ? paymentQr : null,
                paymentUrl: paymentUrl.isNotEmpty ? paymentUrl : null,
              ),
    );

    if (acknowledged == true) {
      final status = await presenter.refreshPaymentStatus(booking.id);
      if (!context.mounted) return;
      if (status != null) {
        final normalized = status.status.toLowerCase();
        if (normalized.contains('paid') || normalized.contains('success')) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Thanh toan da duoc ghi nhan. Vui long cho xac nhan.',
              ),
            ),
          );
        } else if (normalized.contains('pending')) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Thanh toan dang duoc xu ly. Vui long cho them it phut.',
              ),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text('Trang thai thanh toan: ${status.status}')),
          );
        }
      } else {
        final fallback =
            presenter.actionError.isNotEmpty
                ? _localizedError(presenter.actionError)
                : 'Khong kiem tra duoc trang thai thanh toan. Vui long thu lai.';
        messenger.showSnackBar(SnackBar(content: Text(fallback)));
      }
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

class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown({required this.payments});

  final List<BookingPayment> payments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thanh toán',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...payments.map((payment) {
          final refund = payment.refundAmount ?? 0;
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      payment.method,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatCurrency(payment.amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  payment.status,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (refund > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Đã hoàn: ${_formatCurrency(refund)}',
                    style: const TextStyle(
                      color: Color(0xFF27AE60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}


class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({
    super.key,
    required this.booking,
    required this.presenter,
    required this.onOpenReview,
  });

  final BookingSummary booking;
  final TripsPresenter presenter;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          booking.reference != null
              ? 'Đơn ${booking.reference}'
              : 'Đơn ${booking.id}',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookingCard(
              booking: booking,
              presenter: presenter,
              onOpenReview: onOpenReview,
              expanded: true,
            ),
            const SizedBox(height: 20),
            _buildJourneyOverview(context),
            const SizedBox(height: 16),
            _ResponsiveDetailRow(
              children: [
                _buildRefundSummary(context),
                _buildContactInfo(context),
              ],
            ),
            const SizedBox(height: 16),
            _buildPassengerSection(context),
            const SizedBox(height: 16),
            _buildPaymentHistory(context),
            const SizedBox(height: 16),
            _buildInvoiceSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyOverview(BuildContext context) {
    final tour = booking.tour;
    final totalDisplay = booking.totalPrice ?? booking.totalAmount;
    final discountAmount = booking.discountTotal ?? 0;
    final notes = booking.notes?.trim();

    return _DetailSectionCard(
      title: booking.reference != null
          ? 'Booking #${booking.reference}'
          : 'Booking ${booking.id}',
      subtitle: tour?.title ?? 'Tour của bạn',
      icon: Icons.assignment_outlined,
      trailing: _DetailStatusChip(
        label: _bookingStageLabel(_bookingStageFor(booking)),
        color: _bookingStageColor(_bookingStageFor(booking)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 16,
            children: [
              _DetailKeyValue(
                label: 'Điểm đến',
                value: tour?.destination ?? 'Đang cập nhật',
                icon: Icons.location_on_outlined,
              ),
              _DetailKeyValue(
                label: 'Lịch trình',
                value: _formatDateRange(booking.startDate, booking.endDate),
                icon: Icons.event_available_outlined,
              ),
              _DetailKeyValue(
                label: 'Số khách',
                value: _formatGuests(booking.adults, booking.children),
                icon: Icons.groups_outlined,
              ),
              if (booking.packageName != null && booking.packageName!.isNotEmpty)
                _DetailKeyValue(
                  label: 'Gói đã chọn',
                  value: booking.packageName!,
                  icon: Icons.card_travel_outlined,
                ),
              _DetailKeyValue(
                label: 'Loại tour',
                value: _tourTypeLabel(tour?.type),
                icon: Icons.category_outlined,
              ),
              _DetailKeyValue(
                label: 'Tổng chi phí',
                value: totalDisplay != null
                    ? _formatCurrency(totalDisplay)
                    : 'Đang cập nhật',
                icon: Icons.payments_outlined,
              ),
              if (discountAmount > 0)
                _DetailKeyValue(
                  label: 'Khuyến mãi',
                  value: '-${_formatCurrency(discountAmount)}',
                  icon: Icons.local_offer_outlined,
                  valueColor: const Color(0xFF2E7D32),
                ),
              if (booking.balanceDue != null && booking.balanceDue! > 0)
                _DetailKeyValue(
                  label: 'Còn phải thanh toán',
                  value: _formatCurrency(booking.balanceDue),
                  icon: Icons.warning_amber_rounded,
                  valueColor: const Color(0xFFE53935),
                )
              else if (booking.amountPaid != null && booking.amountPaid! > 0)
                _DetailKeyValue(
                  label: 'Đã thanh toán',
                  value: _formatCurrency(booking.amountPaid),
                  icon: Icons.verified_outlined,
                ),
              _DetailKeyValue(
                label: 'Yêu cầu hộ chiếu/visa',
                value: _passportRequirementLabel(tour),
                icon: Icons.policy_outlined,
              ),
            ],
          ),
          if (booking.promotions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Khuyến mãi áp dụng',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: booking.promotions.map((promo) {
                return Chip(
                  label: Text('${promo.code} - ${_formatCurrency(promo.discountAmount)}'),
                  backgroundColor: const Color(0xFFFFF1E0),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          if ((notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Ghi chú của bạn',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            _DetailCalloutBox(text: notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildRefundSummary(BuildContext context) {
    if (booking.refundRequests.isEmpty) {
      return const _DetailSectionCard(
        title: 'Hoàn tiền',
        icon: Icons.cached_outlined,
        child: Text(
          'Chưa có yêu cầu hoàn tiền. Nếu đơn đã thanh toán và bị hủy, hãy sử dụng nút "Yêu cầu hoàn tiền" phía trên.',
        ),
      );
    }

    final latest = booking.refundRequests.first;
    return _DetailSectionCard(
      title: 'Hoàn tiền',
      icon: Icons.cached_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailStatusChip(
            label: _refundStatusLabel(latest.status),
            color: const Color(0xFF2F80ED),
          ),
          const SizedBox(height: 8),
          Text(
            'Số tiền: ${_formatCurrency(latest.amount)} (${latest.currency})',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (latest.updatedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Cập nhật gần nhất: ${_dateFormatter.format(latest.updatedAt!)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ],
          if ((latest.partnerMessage ?? latest.customerMessage) != null) ...[
            const SizedBox(height: 12),
            _DetailCalloutBox(
              text: latest.partnerMessage ?? latest.customerMessage ?? '',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return _DetailSectionCard(
      title: 'Thông tin liên hệ',
      icon: Icons.contact_phone_outlined,
      child: Wrap(
        spacing: 18,
        runSpacing: 16,
        children: [
          _DetailKeyValue(
            label: 'Người liên hệ',
            value: booking.contactName ?? 'Chưa cập nhật',
            icon: Icons.person_outline,
          ),
          _DetailKeyValue(
            label: 'Số điện thoại',
            value: booking.contactPhone ?? 'Chưa cập nhật',
            icon: Icons.phone_outlined,
          ),
          _DetailKeyValue(
            label: 'Email',
            value: booking.contactEmail ?? 'Chưa cập nhật',
            icon: Icons.alternate_email,
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerSection(BuildContext context) {
    if (booking.passengers.isEmpty) {
      return const _DetailSectionCard(
        title: 'Hành khách',
        icon: Icons.groups_outlined,
        child: Text(
          'Chưa có thông tin hành khách. Vui lòng liên hệ hỗ trợ nếu cần cập nhật.',
        ),
      );
    }

    return _DetailSectionCard(
      title: 'Hành khách',
      icon: Icons.groups_outlined,
      child: Column(
        children: [
          for (var i = 0; i < booking.passengers.length; i++) ...[
            _PassengerTile(passenger: booking.passengers[i]),
            if (i != booking.passengers.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(BuildContext context) {
    if (booking.payments.isEmpty) {
      return const _DetailSectionCard(
        title: 'Lịch sử thanh toán',
        icon: Icons.receipt_long_outlined,
        child: Text(
          'Chưa có giao dịch nào được ghi nhận. Khi bạn thanh toán hoặc được hoàn lại, thông tin sẽ hiển thị ở đây.',
        ),
      );
    }

    return _DetailSectionCard(
      title: 'Lịch sử thanh toán',
      icon: Icons.receipt_long_outlined,
      child: _PaymentBreakdown(payments: booking.payments),
    );
  }

  Widget _buildInvoiceSection(BuildContext context) {
    final invoice = booking.invoice;
    final status = booking.status.toLowerCase();
    final payment = booking.paymentStatus?.toLowerCase() ?? '';
    final canRequestInvoice =
        status.contains('complete') && payment.contains('paid');

    if (invoice == null) {
      if (!canRequestInvoice) {
        return const _DetailSectionCard(
          title: 'Hóa đơn điện tử',
          icon: Icons.file_present_outlined,
          child: Text(
            'Chưa có hóa đơn được phát hành. Bạn có thể sử dụng nút "Xuất hóa đơn" phía trên khi đơn đã hoàn tất và thanh toán thành công.',
          ),
        );
      }
      return _InvoiceRequestCard(
        booking: booking,
        presenter: presenter,
      );
    }

    return _DetailSectionCard(
      title: 'Hóa đơn điện tử',
      icon: Icons.file_present_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailKeyValue(
            label: 'Mã hóa đơn',
            value: invoice.invoiceNumber,
            icon: Icons.confirmation_number_outlined,
          ),
          const SizedBox(height: 12),
          _DetailKeyValue(
            label: 'Giá trị',
            value: _formatCurrency(invoice.amount),
            icon: Icons.price_check_outlined,
          ),
          const SizedBox(height: 12),
          _DetailKeyValue(
            label: 'Hình thức giao',
            value: invoice.deliveryMethod == 'email' ? 'Gửi email' : 'Tải xuống',
            icon: Icons.send_outlined,
          ),
          if (invoice.emailedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Đã gửi lúc: ${_dateFormatter.format(invoice.emailedAt!)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  String _tourTypeLabel(String? raw) {
    if (raw == null) return 'Đang cập nhật';
    return raw.toLowerCase().contains('international')
        ? 'Tour quốc tế'
        : 'Tour nội địa';
  }

  String _passportRequirementLabel(TourSummary? tour) {
    if (tour == null) return 'Theo quy định đối tác';
    if (tour.requiresPassport || tour.requiresVisa) {
      return 'Cần hộ chiếu/visa';
    }
    return 'Không yêu cầu';
  }
}


class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFFFF7A18)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InvoiceRequestCard extends StatefulWidget {
  const _InvoiceRequestCard({
    required this.booking,
    required this.presenter,
  });

  final BookingSummary booking;
  final TripsPresenter presenter;

  @override
  State<_InvoiceRequestCard> createState() => _InvoiceRequestCardState();
}

class _InvoiceRequestCardState extends State<_InvoiceRequestCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _emailCtrl;
  String _deliveryMethod = 'download';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    _nameCtrl = TextEditingController(text: booking.contactName ?? '');
    _taxCtrl = TextEditingController();
    _addressCtrl = TextEditingController(text: booking.tour?.destination ?? '');
    _emailCtrl = TextEditingController(text: booking.contactEmail ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taxCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DetailSectionCard(
      title: 'Hóa đơn điện tử',
      subtitle: 'Điền thông tin để yêu cầu Tourify phát hành hóa đơn',
      icon: Icons.file_present_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên đơn vị/Khách hàng',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên khách hàng';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taxCtrl,
              decoration: const InputDecoration(
                labelText: 'Mã số thuế',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa chỉ';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _deliveryMethod,
              decoration: const InputDecoration(
                labelText: 'Phương thức nhận hóa đơn',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'download',
                  child: Text('Tải về trong ứng dụng'),
                ),
                DropdownMenuItem(
                  value: 'email',
                  child: Text('Gửi qua email'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _deliveryMethod = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              enabled: _deliveryMethod == 'email',
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email nhận hóa đơn',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_deliveryMethod != 'email') return null;
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Vui lòng nhập email nhận hóa đơn';
                }
                final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!regex.hasMatch(trimmed)) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.receipt_long_outlined),
                label: Text(
                  _submitting ? 'Đang gửi yêu cầu...' : 'Yêu cầu xuất hóa đơn',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A3D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);

    final result = await widget.presenter.requestInvoice(
      bookingId: widget.booking.id,
      customerName: _nameCtrl.text.trim(),
      taxCode: _taxCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      deliveryMethod: _deliveryMethod,
    );
    setState(() => _submitting = false);

    if (result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _deliveryMethod == 'email'
                ? 'Hóa đơn sẽ được gửi qua email sau khi xử lý.'
                : 'Đã gửi yêu cầu xuất hóa đơn.',
          ),
        ),
      );
    } else if (widget.presenter.actionError.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_localizedError(widget.presenter.actionError)),
        ),
      );
    }
  }
}

class _DetailStatusChip extends StatelessWidget {
  const _DetailStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailKeyValue extends StatelessWidget {
  const _DetailKeyValue({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey.shade500),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCalloutBox extends StatelessWidget {
  const _DetailCalloutBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD9B5)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _ResponsiveDetailRow extends StatelessWidget {
  const _ResponsiveDetailRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600 && children.length > 1) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == children.length - 1 ? 0 : 16),
                    child: children[i],
                  ),
                ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == children.length - 1 ? 0 : 16),
                child: children[i],
              ),
          ],
        );
      },
    );
  }
}

class _PassengerTile extends StatelessWidget {
  const _PassengerTile({required this.passenger});

  final BookingPassenger passenger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            passenger.fullName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _DetailMiniValue(
                label: 'Loại khách',
                value: passenger.type.toLowerCase().contains('child')
                    ? 'Trẻ em'
                    : 'Người lớn',
              ),
              if (passenger.gender != null && passenger.gender!.isNotEmpty)
                _DetailMiniValue(
                  label: 'Giới tính',
                  value: passenger.gender!,
                ),
              if (passenger.dateOfBirth != null)
                _DetailMiniValue(
                  label: 'Ngày sinh',
                  value: _dateFormatter.format(passenger.dateOfBirth!),
                ),
              if (passenger.documentNumber != null &&
                  passenger.documentNumber!.isNotEmpty)
                _DetailMiniValue(
                  label: 'Giấy tờ',
                  value: passenger.documentNumber!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailMiniValue extends StatelessWidget {
  const _DetailMiniValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
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
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool readOnly;

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
          readOnly: readOnly,
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

class _RefundFormData {
  const _RefundFormData({
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.bankBranch,
    required this.amount,
    this.currency = 'VND',
    this.note,
  });

  final String accountName;
  final String accountNumber;
  final String bankName;
  final String bankBranch;
  final double amount;
  final String currency;
  final String? note;
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







