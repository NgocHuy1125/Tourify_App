import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/features/account/presenter/account_presenter.dart';
import 'package:tourify_app/features/notifications/presenter/notification_presenter.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _options = const [
    _NotificationOption(
      keyName: 'promotions',
      title: 'Email khuyến mãi',
      description:
          'Nhận thông tin về ưu đãi độc quyền và chương trình khuyến mãi mới nhất.',
    ),
    _NotificationOption(
      keyName: 'booking_updates',
      title: 'Cập nhật đặt chỗ',
      description:
          'Thông báo về trạng thái đặt tour, xác nhận và thay đổi lịch trình.',
    ),
    _NotificationOption(
      keyName: 'travel_tips',
      title: 'Tin tức & mẹo du lịch',
      description:
          'Khám phá điểm đến mới và mẹo hữu ích để chuẩn bị cho chuyến đi.',
    ),
    _NotificationOption(
      keyName: 'upcoming_reminders',
      title: 'Nhắc nhở sắp tới',
      description:
          'Nhận nhắc nhở về hoạt động và đặt chỗ sắp diễn ra để không bỏ lỡ.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountPresenter>().loadNotificationPreferences();
      context.read<NotificationPresenter>().ensureNotificationToggleLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<AccountPresenter>();
    final prefs = presenter.notificationPreferences;
    final notificationPresenter = context.watch<NotificationPresenter>();
    final notificationsEnabled =
        notificationPresenter.notificationsEnabled ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt thông báo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              value: notificationsEnabled,
              onChanged: notificationPresenter.toggleLoading
                  ? null
                  : notificationPresenter.toggleNotifications,
              activeColor: const Color(0xFF4E54C8),
              title: const Text(
                'Nhận thông báo từ Tourify',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Tắt để không nhận bất kỳ thông báo nào về đơn hàng, voucher, hoàn tiền.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final option in _options) ...[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            option.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: (prefs[option.keyName] ?? true) &&
                          notificationsEnabled,
                      activeColor: const Color(0xFF4E54C8),
                      onChanged: (notificationsEnabled &&
                              !presenter.notificationLoading)
                          ? (value) => presenter.updateNotificationPreference(
                                option.keyName,
                                value,
                              )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _NotificationOption {
  const _NotificationOption({
    required this.keyName,
    required this.title,
    required this.description,
  });

  final String keyName;
  final String title;
  final String description;
}
