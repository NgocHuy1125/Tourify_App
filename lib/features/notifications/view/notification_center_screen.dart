import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/features/notifications/model/notification_model.dart';
import 'package:tourify_app/features/notifications/presenter/notification_presenter.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationFormatter _formatter = const NotificationFormatter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final presenter = context.read<NotificationPresenter>();
      presenter.loadInitial();
      presenter.refreshUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          Consumer<NotificationPresenter>(
            builder: (_, presenter, __) {
              final hasUnread = presenter.unreadCount > 0;
              return TextButton(
                onPressed: hasUnread ? presenter.markAllAsRead : null,
                child: const Text('Đánh dấu đã đọc'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationPresenter>(
        builder: (_, presenter, __) {
          if (presenter.isLoading && presenter.notifications.isEmpty) {
            return const _NotificationLoadingPlaceholder();
          }

          if (presenter.errorMessage.isNotEmpty &&
              presenter.notifications.isEmpty) {
            return _NotificationError(
              message: presenter.errorMessage,
              onRetry: presenter.refresh,
            );
          }

          if (presenter.notifications.isEmpty) {
            return const _NotificationEmptyState();
          }

          return RefreshIndicator(
            onRefresh: presenter.refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 100 &&
                    !presenter.isLoadingMore) {
                  presenter.loadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: presenter.notifications.length +
                    (presenter.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= presenter.notifications.length) {
                    return const _NotificationLoadingTile();
                  }
                  final item = presenter.notifications[index];
                  return _NotificationTile(
                    notification: item,
                    formatter: _formatter,
                    onMarkRead: () => presenter.markAsRead(item),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.formatter,
    required this.onMarkRead,
  });

  final AppNotification notification;
  final NotificationFormatter formatter;
  final VoidCallback onMarkRead;

  IconData _iconForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('voucher')) return Icons.card_giftcard_outlined;
    if (normalized.contains('refund')) return Icons.monetization_on_outlined;
    if (normalized.contains('invoice')) return Icons.receipt_long_outlined;
    if (normalized.contains('booking')) return Icons.event_available_outlined;
    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        notification.isRead ? Colors.grey.shade600 : theme.primaryColor;

    return ListTile(
      onTap: onMarkRead,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              _iconForType(notification.type),
              color: color,
            ),
          ),
          if (!notification.isRead)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        notification.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.message.isNotEmpty
                ? notification.message
                : 'Bạn có cập nhật mới.',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatter.formatDate(notification.createdAt),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 36,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có thông báo',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Khi có cập nhật về đơn hàng, voucher hoặc hoàn tiền, chúng tôi sẽ thông báo cho bạn ngay.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationLoadingPlaceholder extends StatelessWidget {
  const _NotificationLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, __) => Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _NotificationLoadingTile extends StatelessWidget {
  const _NotificationLoadingTile();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
