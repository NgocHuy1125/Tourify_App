import 'package:flutter/material.dart';

import 'package:tourify_app/features/booking/model/booking_model.dart';
import 'package:tourify_app/features/booking/model/booking_repository.dart';

enum TripsState { initial, loading, success, error }

class TripsFilter {
  const TripsFilter({required this.key, required this.label});

  final String key;
  final String label;
}

class TripsPresenter with ChangeNotifier {
  TripsPresenter(this._repository);

  static const List<TripsFilter> filters = [
    // Đã sửa lỗi Tiếng Việt
    TripsFilter(key: 'all', label: 'Tất cả'),
    TripsFilter(key: 'pending_payment', label: 'Chờ thanh toán'),
    TripsFilter(key: 'confirmed', label: 'Xác nhận'),
    TripsFilter(key: 'completed', label: 'Hoàn thành'),
    TripsFilter(key: 'cancelled', label: 'Đã hủy'),
  ];

  final BookingRepository _repository;

  TripsState _state = TripsState.initial;
  TripsState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _actionError = '';
  String get actionError => _actionError;

  String _selectedFilter = filters.first.key;
  String get selectedFilter => _selectedFilter;

  final Map<String, List<BookingSummary>> _cache = {};
  bool _isFetching = false;

  List<BookingSummary> get bookings {
    final cached = _cache[_selectedFilter];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final all = _cache['all'];
    if (all == null) {
      return cached ?? const [];
    }

    if (_selectedFilter == 'all') {
      return cached ?? all;
    }

    return all
        .where((booking) => _matchesFilter(booking, _selectedFilter))
        .toList();
  }

  bool get isLoading => _state == TripsState.loading;
  bool get isFetching => _isFetching;

  Future<void> loadInitial() async {
    if (_state == TripsState.initial) {
      await _fetchCurrent(force: true);
    } else if (!_cache.containsKey(_selectedFilter)) {
      await _fetchCurrent(force: true);
    }
  }

  void clearActionError() {
    if (_actionError.isNotEmpty) {
      _actionError = '';
      notifyListeners();
    }
  }

  Future<void> selectFilter(String key) async {
    if (_selectedFilter == key) return;
    if (!filters.any((filter) => filter.key == key)) return;
    _selectedFilter = key;
    notifyListeners();
    await _fetchCurrent(force: !_cache.containsKey(key));
  }

  Future<void> refresh() async {
    _cache.remove(_selectedFilter);
    await _fetchCurrent(force: true);
  }

  String statusLabel(String status) {
    final normalized = status.toLowerCase();
    // Đã sửa lỗi Tiếng Việt
    if (normalized.contains('pending') || normalized.contains('await')) {
      return 'Chờ thanh toán';
    }
    if (normalized.contains('confirm')) {
      return 'Xác nhận';
    }
    if (normalized.contains('complete') || normalized.contains('finish')) {
      return 'Hoàn thành';
    }
    if (normalized.contains('cancel')) {
      return 'Đã hủy';
    }
    if (normalized.contains('processing') || normalized.contains('review')) {
      return 'Đang xử lý';
    }
    return status;
  }

  Color statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('pending') || normalized.contains('await')) {
      return const Color(0xFFF2994A);
    }
    if (normalized.contains('confirm')) {
      return const Color(0xFF2F80ED);
    }
    if (normalized.contains('complete') || normalized.contains('finish')) {
      return const Color(0xFF27AE60);
    }
    if (normalized.contains('cancel')) {
      return const Color(0xFFE74C3C);
    }
    return const Color(0xFF4E54C8);
  }

  Future<void> _fetchCurrent({bool force = false}) async {
    if (_isFetching) return;
    final hasCached = _cache.containsKey(_selectedFilter);
    if (!force && hasCached) {
      _state = TripsState.success;
      notifyListeners();
      return;
    }

    _isFetching = true;
    if (!hasCached) {
      _state = TripsState.loading;
    }
    notifyListeners();

    try {
      final filterKey = _selectedFilter;
      final statusParam = _statusParamFor(filterKey);
      final result = await _repository.fetchBookings(status: statusParam);

      List<BookingSummary> effective = result;
      if (effective.isEmpty && filterKey != 'all') {
        final all = _cache['all'];
        if (all != null && all.isNotEmpty) {
          effective =
              all
                  .where((booking) => _matchesFilter(booking, filterKey))
                  .toList();
        }
      }

      _cache[filterKey] = effective;
      if (filterKey == 'all') {
        _cache['all'] = effective;
      }
      _errorMessage = '';
      _actionError = '';
      _state = TripsState.success;
    } catch (e) {
      final message = e.toString();
      _errorMessage =
          message.startsWith('Exception: ')
              ? message.substring('Exception: '.length)
              : message;
      _state = TripsState.error;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
    String? reviewId,
  }) async {
    try {
      if (reviewId == null) {
        await _repository.createReview(
          bookingId: bookingId,
          rating: rating,
          comment: comment,
        );
      } else {
        await _repository.updateReview(
          reviewId,
          rating: rating,
          comment: comment,
        );
      }
      _actionError = '';
      await _fetchCurrent(force: true);
      return true;
    } catch (e) {
      final message = e.toString();
      _actionError =
          message.startsWith('Exception: ')
              ? message.substring('Exception: '.length)
              : message;
      notifyListeners();
      return false;
    }
  }

  Future<BookingPaymentIntent?> payLater(String bookingId) async {
    try {
      final intent = await _repository.createPayLater(bookingId);
      await refresh();
      _actionError = '';
      notifyListeners();
      return intent;
    } catch (error) {
      _actionError = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<BookingPaymentIntent?> refreshPaymentStatus(String bookingId) async {
    try {
      final status = await _repository.fetchPaymentStatus(bookingId);
      await refresh();
      return status;
    } catch (error) {
      _actionError = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteReview(String reviewId) async {
    try {
      await _repository.deleteReview(reviewId);
      _actionError = '';
      await _fetchCurrent(force: true);
      return true;
    } catch (e) {
      final message = e.toString();
      _actionError =
          message.startsWith('Exception: ')
              ? message.substring('Exception: '.length)
              : message;
      notifyListeners();
      return false;
    }
  }

  String? _statusParamFor(String filterKey) {
    switch (filterKey) {
      case 'pending_payment':
        return 'pending_payment';
      case 'confirmed':
        return 'confirmed';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return null;
    }
  }

  bool _matchesFilter(BookingSummary booking, String filter) {
    final stage = _stageKeyFor(booking);
    switch (filter) {
      case 'pending_payment':
        return stage == 'awaiting_payment';
      case 'confirmed':
        return stage == 'awaiting_confirmation';
      case 'completed':
        return stage == 'completed';
      case 'cancelled':
        return stage == 'cancelled';
      default:
        return true;
    }
  }

  String _stageKeyFor(BookingSummary booking) {
    final status = booking.status.toLowerCase();
    final payment = booking.paymentStatus?.toLowerCase() ?? '';
    final hasPaid =
        (booking.amountPaid ?? 0) > 0 ||
        payment.contains('paid') ||
        payment.contains('success') ||
        payment.contains('refunded');

    if (status.contains('cancel')) return 'cancelled';
    if (status.contains('complete') || status.contains('finish')) {
      return 'completed';
    }

    if (status.contains('pending') || status.contains('await')) {
      return hasPaid ? 'awaiting_confirmation' : 'awaiting_payment';
    }

    if (status.contains('confirm') || status.contains('process')) {
      return hasPaid ? 'awaiting_confirmation' : 'awaiting_payment';
    }

    if (status.contains('cancell') && payment.contains('pending')) {
      return 'awaiting_payment';
    }

    if (!hasPaid &&
        (payment.contains('pending') ||
            payment.contains('await') ||
            payment.contains('unpaid') ||
            payment.isEmpty)) {
      return 'awaiting_payment';
    }

    if (hasPaid) return 'awaiting_confirmation';
    return 'processing';
  }

  Future<RefundRequest?> submitRefundRequest({
    required String bookingId,
    required String accountName,
    required String accountNumber,
    required String bankName,
    required String bankBranch,
    double? amount,
    String currency = 'VND',
    String? customerMessage,
  }) async {
    try {
      final refund = await _repository.submitRefundRequest(
        bookingId,
        bankAccountName: accountName,
        bankAccountNumber: accountNumber,
        bankName: bankName,
        bankBranch: bankBranch,
        amount: amount,
        currency: currency,
        customerMessage: customerMessage,
      );
      await refresh();
      _actionError = '';
      notifyListeners();
      return refund;
    } catch (error) {
      _actionError = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmRefundRequest(String requestId) async {
    try {
      await _repository.confirmRefundRequest(requestId);
      await refresh();
      _actionError = '';
      notifyListeners();
      return true;
    } catch (error) {
      _actionError = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<BookingInvoice?> fetchInvoice(String bookingId) async {
    try {
      return await _repository.fetchInvoice(bookingId);
    } catch (error) {
      _actionError = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<BookingInvoice?> requestInvoice({
    required String bookingId,
    required String customerName,
    required String taxCode,
    required String address,
    required String email,
    required String deliveryMethod,
  }) async {
    try {
      final invoice = await _repository.requestInvoice(
        bookingId,
        customerName: customerName,
        taxCode: taxCode,
        address: address,
        email: email,
        deliveryMethod: deliveryMethod,
      );
      await refresh();
      _actionError = '';
      notifyListeners();
      return invoice;
    } catch (error) {
      _actionError = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<BookingCancellationResult?> cancelBooking(String bookingId) async {
    try {
      final result = await _repository.cancelBooking(bookingId);
      await refresh();
      _actionError = '';
      notifyListeners();
      return result;
    } catch (error) {
      _actionError = error.toString();
      notifyListeners();
      return null;
    }
  }

  void resetForGuest() {
    _state = TripsState.initial;
    _errorMessage = '';
    _actionError = '';
    _cache.clear();
    _selectedFilter = filters.first.key;
    notifyListeners();
  }
}
