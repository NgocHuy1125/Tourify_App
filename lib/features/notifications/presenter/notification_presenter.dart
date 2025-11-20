import 'package:flutter/foundation.dart';

import '../model/notification_model.dart';
import '../model/notification_repository.dart';

class NotificationPresenter with ChangeNotifier {
  NotificationPresenter(this._repository);

  final NotificationRepository _repository;

  static const int _perPage = 20;

  List<AppNotification> _notifications = const [];
  List<AppNotification> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  int _currentPage = 1;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool? _notificationsEnabled;
  bool? get notificationsEnabled => _notificationsEnabled;

  bool _toggleLoading = false;
  bool get toggleLoading => _toggleLoading;

  Future<void> loadInitial({bool force = false}) async {
    if (_isLoading) return;
    if (_notifications.isNotEmpty && !force) return;
    await _fetch(page: 1, reset: true);
  }

  Future<void> refresh() => _fetch(page: 1, reset: true);

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    await _fetch(page: _currentPage + 1, reset: false);
  }

  Future<void> _fetch({required int page, required bool reset}) async {
    if (reset) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final result = await _repository.fetchNotifications(
        page: page,
        perPage: _perPage,
      );
      _currentPage = result.page;
      _hasMore = result.hasMore;
      _errorMessage = '';
      if (reset) {
        _notifications = result.items;
      } else {
        _notifications = [..._notifications, ...result.items];
      }
    } catch (error) {
      _errorMessage = error.toString();
      if (reset) {
        _notifications = const [];
        _hasMore = false;
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _repository.fetchUnreadCount();
      notifyListeners();
    } catch (_) {
      // ignore unread errors
    }
  }

  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index == -1) return;
    _notifications = [
      ..._notifications.sublist(0, index),
      notification.markAsRead(),
      ..._notifications.sublist(index + 1),
    ];
    _unreadCount = (_unreadCount - 1).clamp(0, 1 << 31);
    notifyListeners();

    try {
      await _repository.markAsRead(notification.id);
    } catch (_) {
      // swallow error, UI already updated
    }
  }

  Future<void> markAllAsRead() async {
    if (_notifications.every((n) => n.isRead)) return;
    _notifications = _notifications.map((n) => n.markAsRead()).toList();
    _unreadCount = 0;
    notifyListeners();
    try {
      await _repository.markAllAsRead();
    } catch (_) {
      // ignore errors; next refresh will sync
    }
  }

  Future<void> ensureNotificationToggleLoaded() async {
    if (_notificationsEnabled != null || _toggleLoading) return;
    _toggleLoading = true;
    notifyListeners();
    try {
      _notificationsEnabled =
          await _repository.fetchNotificationsEnabled() ?? true;
    } finally {
      _toggleLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (_toggleLoading) return;
    final previous = _notificationsEnabled ?? true;
    _notificationsEnabled = enabled;
    _toggleLoading = true;
    notifyListeners();
    try {
      _notificationsEnabled =
          await _repository.toggleNotifications(enabled);
    } catch (error) {
      _notificationsEnabled = previous;
      _errorMessage = error.toString();
    } finally {
      _toggleLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _notifications = const [];
    _unreadCount = 0;
    _errorMessage = '';
    _currentPage = 1;
    _hasMore = true;
    _notificationsEnabled = null;
    notifyListeners();
  }
}
