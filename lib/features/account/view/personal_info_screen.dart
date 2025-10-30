import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/account/model/user_profile.dart';
import 'package:tourify_app/features/account/presenter/account_presenter.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<AccountPresenter>();
    final profile = presenter.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(profile: profile),
            const SizedBox(height: 20),
            _InfoGroup(
              title: 'Thông tin cơ bản',
              children: [
                _InfoTile(
                  icon: Icons.person_outline,
                  label: 'Tên của bạn',
                  value: _valueOrPlaceholder(profile?.name),
                  actionLabel: 'Chỉnh sửa',
                ),
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Danh xưng',
                  value: _valueOrPlaceholder(profile?.gender),
                  actionLabel: 'Chỉnh sửa',
                ),
                _InfoTile(
                  icon: Icons.cake_outlined,
                  label: 'Ngày sinh',
                  value: _formatDate(profile?.birthday),
                  actionLabel: 'Chỉnh sửa',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoGroup(
              title: 'Liên hệ & cư trú',
              children: [
                _InfoTile(
                  icon: Icons.flag_outlined,
                  label: 'Quốc gia / Khu vực cư trú',
                  value: _valueOrPlaceholder(profile?.country ?? 'Việt Nam'),
                  actionLabel: 'Chỉnh sửa',
                ),
                _InfoTile(
                  icon: Icons.phone_android_outlined,
                  label: 'Số điện thoại',
                  value: _valueOrPlaceholder(profile?.phone),
                  helper: 'Bạn có thể đăng nhập bằng số điện thoại hoặc email',
                  actionLabel: 'Chỉnh sửa',
                ),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _valueOrPlaceholder(profile?.email),
                  actionLabel: 'Chỉnh sửa',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _valueOrPlaceholder(String? value) {
    if (value == null || value.trim().isEmpty) return 'Chưa có';
    return value;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa có';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class _HeaderCard extends StatelessWidget {
  final UserProfile? profile;
  const _HeaderCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;
    return Stack(
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF4E54C8), Color(0xFF8F94FB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned.fill(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  backgroundImage:
                      avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                  child:
                      avatarUrl == null || avatarUrl.isEmpty
                          ? const Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.white,
                          )
                          : null,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _HeaderCard._valueOrPlaceholder(profile?.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _HeaderCard._valueOrPlaceholder(profile?.email),
                      style: TextStyle(color: Colors.white.withOpacity(0.85)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4E54C8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Chỉnh ảnh đại diện'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _valueOrPlaceholder(String? value) {
    if (value == null || value.trim().isEmpty) return 'Chưa có';
    return value;
  }
}

class _InfoGroup extends StatelessWidget {
  final String title;
  final List<_InfoTile> children;
  const _InfoGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E54C8),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++)
                Column(
                  children: [
                    if (i != 0)
                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                        indent: 60,
                      ),
                    children[i],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? helper;
  final String? actionLabel;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF4E54C8).withOpacity(0.12),
        child: Icon(icon, color: const Color(0xFF4E54C8)),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                helper!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
      trailing:
          actionLabel != null
              ? TextButton(onPressed: () {}, child: Text(actionLabel!))
              : null,
    );
  }
}
