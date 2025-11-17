import 'dart:convert';

import 'package:tourify_app/core/services/secure_storage_service.dart';
import 'package:tourify_app/features/booking/model/booking_model.dart';
import 'package:tourify_app/features/booking/model/booking_repository.dart';

import 'notification_model.dart';
import 'notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required BookingRepository bookingRepository,
    SecureStorageService? storage,
  })  : _bookingRepository = bookingRepository,
        _storage = storage ?? SecureStorageService();

  final BookingRepository _bookingRepository;
  final SecureStorageService _storage;

  static const _readStateKey = 'app_notifications_read_state';
  static const _toggleKey = 'app_notifications_enabled';

  List<AppNotification>? _cached;

  @override
  Future<NotificationPage> fetchNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final snapshot = await _ensureSnapshot(refresh: page == 1);
    final offset = ((page - 1) * perPage).clamp(0, snapshot.length).toInt();
    final end = (offset + perPage).clamp(0, snapshot.length).toInt();
    final items =
        offset >= snapshot.length
            ? <AppNotification>[]
            : snapshot.sublist(offset, end);
    final hasMore = end < snapshot.length;
    return NotificationPage(
      items: items,
      page: page,
      hasMore: hasMore,
    );
  }

  @override
  Future<int> fetchUnreadCount() async {
    final snapshot = await _ensureSnapshot();
    return snapshot.where((item) => !item.isRead).length;
  }

  @override
  Future<void> markAsRead(String id) async {
    if (id.isEmpty) return;
    final readState = await _loadReadState();
    readState[id] = DateTime.now();
    await _saveReadState(readState);
    _cached = _cached
        ?.map(
          (item) => item.id == id
              ? item.copyWith(readAt: readState[id])
              : item,
        )
        .toList();
  }

  @override
  Future<void> markAllAsRead() async {
    final snapshot = await _ensureSnapshot();
    final now = DateTime.now();
    final readState = {
      for (final notification in snapshot)
        notification.id: notification.readAt ?? now,
    };
    await _saveReadState(readState);
    _cached = snapshot.map((item) => item.isRead ? item : item.copyWith(
      readAt: now,
    )).toList();
  }

  @override
  Future<bool> toggleNotifications(bool enabled) async {
    await _storage.writeValue(_toggleKey, enabled.toString());
    return enabled;
  }

  @override
  Future<bool?> fetchNotificationsEnabled() async {
    final raw = await _storage.readValue(_toggleKey);
    if (raw == null) return null;
    final normalized = raw.toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'on') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'off') {
      return false;
    }
    return null;
  }

  Future<List<AppNotification>> _ensureSnapshot({bool refresh = false}) async {
    if (_cached != null && !refresh) return _cached!;
    final bookings = await _bookingRepository.fetchBookings();
    final generated = _buildNotifications(bookings);
    final readState = await _loadReadState();
    _cached = generated
        .map(
          (notification) => readState[notification.id] != null
              ? notification.copyWith(readAt: readState[notification.id])
              : notification,
        )
        .toList();
    return _cached!;
  }

  List<AppNotification> _buildNotifications(
    List<BookingSummary> bookings,
  ) {
    final notifications = <AppNotification>[];
    for (final booking in bookings) {
      notifications.add(_buildBookingStatusNotification(booking));
      notifications.addAll(_buildVoucherNotifications(booking));
      notifications.addAll(_buildRefundNotifications(booking));
      final invoice = booking.invoice;
      if (invoice != null) {
        notifications.add(_buildInvoiceNotification(booking, invoice));
      }
    }
    notifications.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
    return notifications;
  }

  AppNotification _buildBookingStatusNotification(BookingSummary booking) {
    final status = booking.status.toLowerCase();
    final title = _bookingStatusTitle(status);
    final message = _bookingStatusMessage(booking, status);
    final createdAt = booking.createdAt ?? DateTime.now();
    return AppNotification(
      id: 'booking:${booking.id}:$status',
      type: 'booking_$status',
      title: title,
      message: message,
      data: {
        'booking_id': booking.id,
        'tour_title': booking.tour?.title,
        'status': booking.status,
      },
      createdAt: createdAt,
    );
  }

  List<AppNotification> _buildVoucherNotifications(BookingSummary booking) {
    if (!booking.status.toLowerCase().contains('cancel')) return const [];
    if (booking.promotions.isEmpty) return const [];
    final voucherCodes = booking.promotions
        .map((promo) => promo.code)
        .where((code) => code.isNotEmpty)
        .toList();
    if (voucherCodes.isEmpty) return const [];
    final createdAt = booking.createdAt ?? DateTime.now();
    return [
      AppNotification(
        id: 'voucher:${booking.id}:${voucherCodes.join(',')}',
        type: 'voucher',
        title: 'Tour đã bị hủy, voucher đã gửi qua email',
        message:
            'Đơn ${booking.reference ?? booking.id} nhận được voucher: ${voucherCodes.join(', ')}.',
        data: {
          'booking_id': booking.id,
          'voucher_codes': voucherCodes,
        },
        createdAt: createdAt.add(const Duration(minutes: 1)),
      ),
    ];
  }

  List<AppNotification> _buildRefundNotifications(BookingSummary booking) {
    if (booking.refundRequests.isEmpty) return const [];
    return booking.refundRequests.map((request) {
      final timestamp =
          request.updatedAt ?? request.createdAt ?? DateTime.now();
      final statusText = _refundStatusLabel(request.status);
      return AppNotification(
        id: 'refund:${request.id}:${request.status.toLowerCase()}',
        type: 'refund_update',
        title: 'Yêu cầu hoàn tiền đã được cập nhật',
        message:
            'Trạng thái yêu cầu hoàn tiền cho đơn ${booking.reference ?? booking.id} hiện là $statusText.',
        data: {
          'booking_id': booking.id,
          'refund_id': request.id,
          'refund_status': request.status,
        },
        createdAt: timestamp,
      );
    }).toList();
  }

  AppNotification _buildInvoiceNotification(
    BookingSummary booking,
    BookingInvoice invoice,
  ) {
    final timestamp = invoice.emailedAt ?? DateTime.now();
    final delivery =
        invoice.deliveryMethod.toLowerCase() == 'email'
            ? 'Hóa đơn sẽ được gửi qua email của bạn.'
            : 'Bạn có thể tải hóa đơn từ mục chi tiết đơn hàng.';
    return AppNotification(
      id: 'invoice:${booking.id}:${invoice.invoiceNumber}',
      type: 'invoice',
      title: 'Hóa đơn đã phát hành',
      message:
          'Đơn ${booking.reference ?? booking.id} đã phát hành hóa đơn ${invoice.invoiceNumber}. $delivery',
      data: {
        'booking_id': booking.id,
        'invoice_number': invoice.invoiceNumber,
        'delivery_method': invoice.deliveryMethod,
        'download_url': invoice.downloadUrl,
      },
      createdAt: timestamp,
    );
  }

  Future<Map<String, DateTime>> _loadReadState() async {
    final raw = await _storage.readValue(_readStateKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          DateTime.tryParse(value.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveReadState(Map<String, DateTime> state) async {
    final map = state.map(
      (key, value) => MapEntry(key, value.toIso8601String()),
    );
    await _storage.writeValue(_readStateKey, json.encode(map));
  }

  String _bookingStatusTitle(String status) {
    if (status.contains('pending')) return 'Đơn hàng chờ thanh toán';
    if (status.contains('confirm')) return 'Đơn hàng đã được xác nhận';
    if (status.contains('complete') || status.contains('finish')) {
      return 'Chuyến đi đã hoàn thành';
    }
    if (status.contains('cancel')) return 'Tour đã bị hủy';
    return 'Cập nhật đơn hàng';
  }

  String _bookingStatusMessage(BookingSummary booking, String status) {
    final tourTitle = booking.tour?.title ?? 'tour';
    final reference = booking.reference ?? booking.id;
    if (status.contains('pending')) {
      return 'Đơn $reference cho $tourTitle đang chờ thanh toán. Vui lòng hoàn tất sớm để giữ chỗ.';
    }
    if (status.contains('confirm')) {
      return 'Đơn $reference đã được xác nhận. Hãy chuẩn bị cho chuyến đi $tourTitle.';
    }
    if (status.contains('complete') || status.contains('finish')) {
      return 'Chuyến đi $tourTitle trong đơn $reference đã hoàn thành. Đừng quên để lại đánh giá nhé!';
    }
    if (status.contains('cancel')) {
      return 'Đơn $reference đã bị hủy. Nếu bạn đã thanh toán, hãy gửi yêu cầu hoàn tiền để được hỗ trợ.';
    }
    return 'Đơn $reference cho $tourTitle đang được cập nhật.';
  }

  String _refundStatusLabel(String raw) {
    final status = raw.toLowerCase();
    if (status.contains('await') || status.contains('customer')) {
      return 'Chờ bạn xác nhận';
    }
    if (status.contains('pending') || status.contains('processing')) {
      return 'Đang xử lý';
    }
    if (status.contains('complete') || status.contains('success')) {
      return 'Đã hoàn tất';
    }
    if (status.contains('reject') || status.contains('failed')) {
      return 'Đã bị từ chối';
    }
    return raw;
  }
}
