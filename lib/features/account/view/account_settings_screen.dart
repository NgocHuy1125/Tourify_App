import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/account/presenter/account_presenter.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      SettingSection(
        title: 'Cài đặt tài khoản',
        items: [
          SettingItem(title: 'Quản lý đăng nhập', onTap: () {}),
          SettingItem(title: 'Bảo mật tài khoản', onTap: () {}),
          SettingItem(
            title: 'Vân tay',
            trailing: const StatusChip(
              text: 'Chưa thiết lập',
              color: Colors.orange,
            ),
            onTap: () {},
          ),
        ],
      ),
      SettingSection(
        title: 'Thông tin chung',
        items: [
          SettingItem(
            title: 'Ngôn ngữ',
            trailing: const Text('Tiếng Việt'),
            onTap: () {},
          ),
          SettingItem(
            title: 'Tiền tệ',
            trailing: const Text('VND | đ'),
            onTap: () {},
          ),
          SettingItem(title: 'Cài đặt thông báo', onTap: () {}),
        ],
      ),
      SettingSection(
        title: 'Khác',
        items: [
          SettingItem(title: 'Để lại phản hồi', onTap: () {}),
          SettingItem(title: 'Về Tourify', onTap: () {}),
          SettingItem(
            title: 'Đăng xuất',
            trailing: const Icon(Icons.logout, size: 18, color: Colors.red),
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
            content: const Text('Bạn có chắc chắn đăng xuất khỏi tài khoản?'),
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
}

class SettingSection extends StatelessWidget {
  final String title;
  final List<SettingItem> items;
  const SettingSection({super.key, required this.title, required this.items});

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
        ...items.map((item) => item.buildTile(context)).toList(),
      ],
    );
  }
}

class SettingItem {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  const SettingItem({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  Widget buildTile(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.fiber_manual_record, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
