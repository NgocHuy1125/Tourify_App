import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/features/account/presenter/account_presenter.dart';

class LoginMethodsScreen extends StatelessWidget {
  const LoginMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<AccountPresenter>();
    final profile = presenter.profile;

    final channels = [
      _LoginChannelConfig(
        provider: 'email',
        title: 'Email',
        description: 'Dùng để đăng nhập và nhận thông báo đặt chỗ.',
        icon: Icons.mail_outline,
        value: profile?.email,
        keyboardType: TextInputType.emailAddress,
        hint: 'Nhập địa chỉ email của bạn',
      ),
      _LoginChannelConfig(
        provider: 'phone',
        title: 'Số điện thoại',
        description: 'Nhận mã OTP và hỗ trợ xác thực nhanh.',
        icon: Icons.phone_android_outlined,
        value: profile?.phone,
        keyboardType: TextInputType.phone,
        hint: 'Nhập số điện thoại',
      ),
      _LoginChannelConfig(
        provider: 'google',
        title: 'Google',
        description: 'Liên kết để đăng nhập bằng Google.',
        icon: Icons.g_mobiledata_rounded,
        value: profile?.googleAccount,
        hint: 'Nhập email Google của bạn',
      ),
      _LoginChannelConfig(
        provider: 'facebook',
        title: 'Facebook',
        description: 'Liên kết để đăng nhập bằng Facebook.',
        icon: Icons.facebook_outlined,
        value: profile?.facebookAccount,
        hint: 'Nhập tài khoản Facebook',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý đăng nhập')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: channels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final channel = channels[index];
          final hasValue =
              channel.value != null && channel.value!.trim().isNotEmpty;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(
                          0xFF4E54C8,
                        ).withValues(alpha: 0.12),
                        child: Icon(
                          channel.icon,
                          color: const Color(0xFF4E54C8),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              channel.description,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(connected: hasValue),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (hasValue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4E54C8),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              channel.value!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                () => _showConnectSheet(
                                  context,
                                  presenter,
                                  channel,
                                  currentValue: channel.value,
                                ),
                            child: const Text('Thay đổi'),
                          ),
                        ],
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed:
                          () => _showConnectSheet(context, presenter, channel),
                      icon: const Icon(Icons.add_link),
                      label: const Text('Liên kết ngay'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showConnectSheet(
    BuildContext context,
    AccountPresenter presenter,
    _LoginChannelConfig channel, {
    String? currentValue,
  }) async {
    final controller = TextEditingController(text: currentValue ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Form(
                  key: formKey,
                  child: TextFormField(
                    controller: controller,
                    keyboardType: channel.keyboardType,
                    decoration: InputDecoration(
                      hintText: channel.hint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập ${channel.title.toLowerCase()}';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Huỷ'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          Navigator.of(ctx).pop(controller.text.trim());
                        }
                      },
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    final payloadKey = switch (channel.provider) {
      'email' => 'email',
      'phone' => 'phone',
      'google' => 'google_account',
      'facebook' => 'facebook_account',
      _ => channel.provider,
    };

    final success = await presenter.updateProfile({payloadKey: result});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Cập nhật thành công' : presenter.errorMessage),
      ),
    );
  }
}

class _LoginChannelConfig {
  const _LoginChannelConfig({
    required this.provider,
    required this.title,
    required this.description,
    required this.icon,
    this.value,
    this.keyboardType = TextInputType.text,
    this.hint,
  });

  final String provider;
  final String title;
  final String description;
  final IconData icon;
  final String? value;
  final TextInputType keyboardType;
  final String? hint;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? Colors.green : Colors.orange;
    final text = connected ? 'Đã liên kết' : 'Chưa liên kết';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
