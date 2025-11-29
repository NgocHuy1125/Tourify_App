import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/features/account/presenter/account_presenter.dart';
import 'package:tourify_app/features/account/view/about_tourify_screen.dart';
import 'package:tourify_app/features/account/view/feedback_screen.dart';
import 'package:tourify_app/features/account/view/login_methods_screen.dart';
import 'package:tourify_app/features/account/view/notification_settings_screen.dart';
import 'package:tourify_app/features/account/view/security_settings_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      SettingSection(
        title: 'Cài đặt tài khoản',
        items: [
          SettingItem(
            title: 'Quản lý đăng nhập',
            subtitle: 'Liên kết email, số điện thoại, Google, Facebook',
            onTap: () => _push(context, const LoginMethodsScreen()),
          ),
          SettingItem(
            title: 'Bảo mật',
            subtitle: 'Đổi mật khẩu và bảo vệ tài khoản',
            onTap: () => _push(context, const SecuritySettingsScreen()),
          ),
          SettingItem(
            title: 'Cài đặt thông báo',
            subtitle: 'Chọn những nội dung muốn nhận',
            onTap: () => _push(context, const NotificationSettingsScreen()),
          ),
        ],
      ),
      SettingSection(
        title: 'Hỗ trợ',
        items: [
          SettingItem(
            title: 'Để lại phản hồi về VietTravel',
            subtitle: 'Chia sẻ góp ý để chúng tôi cải thiện trải nghiệm',
            onTap: () => _push(context, const FeedbackScreen()),
          ),
          SettingItem(
            title: 'Về VietTravel',
            subtitle: 'Giới thiệu và liên kết trang web',
            onTap: () => _push(context, const AboutTourifyScreen()),
          ),
        ],
      ),
      SettingSection(
        title: 'Tài khoản',
        items: [
          SettingItem(
            title: 'Đăng xuất',
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
            titleStyle: const TextStyle(color: Colors.redAccent),
            onTap: () => _handleSignOut(context),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) => sections[index],
      ),
    );
  }

  static Future<void> _handleSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text(
              'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await context.read<AccountPresenter>().signOut();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class SettingSection extends StatelessWidget {
  const SettingSection({super.key, required this.title, required this.items});

  final String title;
  final List<SettingItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.grey.shade700),
          ),
        ),
        ...items.map((item) => item.buildTile(context)),
      ],
    );
  }
}

class SettingItem {
  const SettingItem({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.leading,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback onTap;
  final TextStyle? titleStyle;

  Widget buildTile(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: leading,
      title: Text(
        title,
        style: titleStyle ?? const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              )
              : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
    );
  }
}
