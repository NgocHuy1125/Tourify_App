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
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: Column(
        children: [
          if (presenter.isSaving) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: presenter.loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(profile: profile),
                    const SizedBox(height: 24),
                    _InfoGroup(
                      title: 'Thông tin cơ bản',
                      children: [
                        _InfoTile(
                          icon: Icons.person_outline,
                          label: 'Tên của bạn',
                          value: _valueOrPlaceholder(profile?.name),
                          actionLabel: 'Chỉnh sửa',
                          onTap: () => _editName(context, presenter, profile),
                        ),
                        _InfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Giới tính',
                          value: _valueOrPlaceholder(
                            _genderLabel(profile?.gender),
                          ),
                          actionLabel: 'Chỉnh sửa',
                          onTap: () => _editGender(context, presenter, profile),
                        ),
                        _InfoTile(
                          icon: Icons.cake_outlined,
                          label: 'Ngày sinh',
                          value: _formatDate(profile?.birthday),
                          actionLabel: 'Chỉnh sửa',
                          onTap:
                              () => _editBirthday(context, presenter, profile),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _InfoGroup(
                      title: 'Liên hệ & cư trú',
                      children: [
                        _InfoTile(
                          icon: Icons.home_outlined,
                          label: 'Địa chỉ',
                          value: _valueOrPlaceholder(profile?.address),
                          actionLabel: 'Chỉnh sửa',
                          onTap:
                              () => _editAddress(context, presenter, profile),
                        ),
                        _InfoTile(
                          icon: Icons.phone_android_outlined,
                          label: 'Số điện thoại',
                          value: _valueOrPlaceholder(profile?.phone),
                          helper:
                              'Bạn có thể đăng nhập bằng số điện thoại hoặc email.',
                          actionLabel: 'Chỉnh sửa',
                          onTap: () => _editPhone(context, presenter, profile),
                        ),
                        _InfoTile(
                          icon: Icons.email_outlined,
                          label: 'Email / tài khoản',
                          value: _primaryLoginDisplay(profile),
                          actionLabel: 'Chỉnh sửa',
                          onTap: () => _editEmail(context, presenter, profile),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF4E54C8), Color(0xFF8F94FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              backgroundImage:
                  avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
              child:
                  (avatarUrl == null || avatarUrl.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _valueOrPlaceholder(profile?.name) == 'Chưa có'
                        ? 'Khách Tourify'
                        : _valueOrPlaceholder(profile?.name),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _primaryLoginDisplay(profile),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    style: TextButton.styleFrom(
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tính năng cập nhật ảnh đại diện sẽ sớm ra mắt.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Chỉnh ảnh đại diện'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.title, required this.children});

  final String title;
  final List<_InfoTile> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
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
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
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
                        thickness: 1,
                        color: Colors.grey.shade200,
                        indent: 72,
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
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? helper;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF4E54C8).withValues(alpha: 0.12),
        child: Icon(icon, color: const Color(0xFF4E54C8)),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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
              ? TextButton(onPressed: onTap, child: Text(actionLabel!))
              : null,
    );
  }
}

String _valueOrPlaceholder(String? value) {
  if (value == null || value.trim().isEmpty) return 'Chưa có';
  return value.trim();
}

String _genderLabel(String? value) {
  if (value == null) return '';
  switch (value.toLowerCase()) {
    case 'male':
    case 'nam':
      return 'Nam';
    case 'female':
    case 'nu':
    case 'nữ':
      return 'Nữ';
    case 'other':
    case 'khac':
    case 'khác':
      return 'Khác';
    default:
      return value;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Chưa có';
  return DateFormat('dd/MM/yyyy').format(date);
}

String _primaryLoginDisplay(UserProfile? profile) {
  if (profile == null) return 'Chưa có';

  String? valueFromMethods() {
    if (profile.loginMethods.isEmpty) return null;

    final preferredKey =
        profile.extraLoginMethods['primary'] ??
        profile.extraLoginMethods['current'] ??
        profile.extraLoginMethods['default'];

    if (preferredKey != null) {
      for (final method in profile.loginMethods) {
        if (method.provider.toLowerCase() == preferredKey.toLowerCase()) {
          final trimmed = method.value.trim();
          if (trimmed.isNotEmpty) return trimmed;
        }
      }
    }

    for (final method in profile.loginMethods) {
      if (method.provider.toLowerCase() == 'email') {
        final trimmed = method.value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }

    for (final method in profile.loginMethods) {
      if (method.provider.toLowerCase() == 'phone') {
        final trimmed = method.value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }

    final fallback = profile.loginMethods.first.value.trim();
    return fallback.isNotEmpty ? fallback : null;
  }

  final fromMethods = valueFromMethods();
  if (fromMethods != null) return fromMethods;

  if (profile.email.trim().isNotEmpty) return profile.email.trim();
  final phone = profile.phone?.trim();
  if (phone != null && phone.isNotEmpty) return phone;
  return 'Chưa có';
}

Future<void> _editName(
  BuildContext context,
  AccountPresenter presenter,
  UserProfile? profile,
) async {
  final result = await _showTextFieldSheet(
    context,
    title: 'Chỉnh sửa tên',
    initialValue: profile?.name ?? '',
    hintText: 'Nhập tên của bạn',
    validator:
        (value) =>
            value == null || value.trim().isEmpty ? 'Vui lòng nhập tên' : null,
  );
  if (result == null) return;
  await _submitUpdate(context, presenter, {'name': result});
}

Future<void> _editGender(
  BuildContext context,
  AccountPresenter presenter,
  UserProfile? profile,
) async {
  final selected = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final options = [
        {'label': 'Nam', 'value': 'male'},
        {'label': 'Nữ', 'value': 'female'},
        {'label': 'Khác', 'value': 'other'},
      ];
      final current = profile?.gender?.toLowerCase();
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Chọn giới tính',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            for (final option in options)
              RadioListTile<String>(
                value: option['value']!,
                groupValue: current,
                title: Text(option['label']!),
                onChanged: (value) => Navigator.of(context).pop(value),
              ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
  if (selected == null) return;
  await _submitUpdate(context, presenter, {'gender': selected});
}

Future<void> _editBirthday(
  BuildContext context,
  AccountPresenter presenter,
  UserProfile? profile,
) async {
  final now = DateTime.now();
  final initialDate = profile?.birthday ?? DateTime(now.year - 18, 1, 1);
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1900, 1, 1),
    lastDate: DateTime(now.year - 10, now.month, now.day),
  );
  if (picked == null) return;
  await _submitUpdate(context, presenter, {
    'birthday': picked.toIso8601String(),
  });
}

Future<void> _editPhone(
  BuildContext context,
  AccountPresenter presenter,
  UserProfile? profile,
) async {
  final result = await _showTextFieldSheet(
    context,
    title: 'Chỉnh sửa số điện thoại',
    initialValue: profile?.phone ?? '',
    hintText: 'Nhập số điện thoại',
    keyboardType: TextInputType.phone,
  );
  if (result == null) return;
  await _submitUpdate(context, presenter, {'phone': result});
}

Future<void> _editEmail(
  BuildContext context,
  AccountPresenter presenter,
  UserProfile? profile,
) async {
  final result = await _showTextFieldSheet(
    context,
    title: 'Chỉnh sửa email',
    initialValue: profile?.email ?? '',
    hintText: 'Nhập email',
    keyboardType: TextInputType.emailAddress,
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Vui lòng nhập email';
      }
      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!regex.hasMatch(value.trim())) {
        return 'Email không hợp lệ';
      }
      return null;
    },
  );
  if (result == null) return;
  await _submitUpdate(context, presenter, {'email': result});
}

Future<void> _editAddress(
  BuildContext context,
  AccountPresenter presenter,
  UserProfile? profile,
) async {
  final result = await _showTextFieldSheet(
    context,
    title: 'Chỉnh sửa địa chỉ',
    initialValue: profile?.address ?? '',
    hintText: 'Nhập địa chỉ cư trú',
    maxLines: 2,
  );
  if (result == null) return;
  await _submitUpdate(context, presenter, {'address': result});
}

Future<String?> _showTextFieldSheet(
  BuildContext context, {
  required String title,
  required String initialValue,
  String? hintText,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  int maxLines = 1,
}) {
  final controller = TextEditingController(text: initialValue);
  final formKey = GlobalKey<FormState>();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  validator: validator,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Huỷ'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final isValid = formKey.currentState?.validate() ?? true;
                      if (isValid) {
                        Navigator.of(context).pop(controller.text.trim());
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
}

Future<void> _submitUpdate(
  BuildContext context,
  AccountPresenter presenter,
  Map<String, dynamic> payload,
) async {
  final success = await presenter.updateProfile(payload);
  if (!context.mounted) return;
  final message =
      success
          ? 'Cập nhật thành công'
          : presenter.errorMessage.isNotEmpty
          ? presenter.errorMessage
          : 'Không thể cập nhật thông tin. Vui lòng thử lại.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
