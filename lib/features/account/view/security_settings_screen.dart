import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/features/account/presenter/account_presenter.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<AccountPresenter>();
    return Scaffold(
      appBar: AppBar(title: const Text('Bảo mật')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (presenter.isChangingPassword)
              const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đổi mật khẩu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhập mật khẩu hiện tại và thiết lập mật khẩu mới để tăng cường an toàn cho tài khoản của bạn.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      _PasswordField(
                        controller: _currentPasswordController,
                        label: 'Mật khẩu hiện tại',
                        obscureText: _obscureCurrent,
                        onToggleVisibility: () {
                          setState(() => _obscureCurrent = !_obscureCurrent);
                        },
                        validator:
                            (value) =>
                                value == null || value.length < 6
                                    ? 'Vui lòng nhập mật khẩu hiện tại hợp lệ'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        controller: _newPasswordController,
                        label: 'Mật khẩu mới',
                        obscureText: _obscureNew,
                        onToggleVisibility: () {
                          setState(() => _obscureNew = !_obscureNew);
                        },
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                          }
                          if (value == _currentPasswordController.text) {
                            return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        controller: _confirmPasswordController,
                        label: 'Xác nhận mật khẩu mới',
                        obscureText: _obscureConfirm,
                        onToggleVisibility: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return 'Xác nhận mật khẩu không khớp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              presenter.isChangingPassword
                                  ? null
                                  : () => _submit(context),
                          child: const Text('Lưu mật khẩu mới'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final presenter = context.read<AccountPresenter>();
    final success = await presenter.changePassword(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đổi mật khẩu thành công' : presenter.errorMessage,
        ),
      ),
    );
    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}
