import 'notification_model.dart';

abstract class NotificationRepository {
  Future<NotificationPage> fetchNotifications({
    int page = 1,
    int perPage = 20,
  });

  Future<int> fetchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<bool> toggleNotifications(bool enabled);
  Future<bool?> fetchNotificationsEnabled();
}
