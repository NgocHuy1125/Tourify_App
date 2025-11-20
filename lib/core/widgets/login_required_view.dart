import 'package:flutter/material.dart';

import 'package:tourify_app/core/utils/auth_guard.dart';

class LoginRequiredView extends StatelessWidget {
  const LoginRequiredView({
    super.key,
    this.title = 'Đăng nhập để tiếp tục',
    this.message =
        'Vui lòng đăng nhập hoặc tạo tài khoản để sử dụng tính năng này.',
    this.buttonLabel = 'Đăng nhập ngay',
    this.icon = Icons.lock_outline,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: const Color(0xFFFF5B00)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => openAuthScreen(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5B00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
