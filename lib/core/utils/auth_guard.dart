import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'package:tourify_app/features/auth/view/auth_screen.dart';

Future<bool> openAuthScreen(BuildContext context) async {
  final bool? result = await Navigator.of(
    context,
    rootNavigator: true,
  ).push<bool>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const AuthScreen()),
  );

  final auth = context.read<AuthNotifier>();
  return result == true || auth.isLoggedIn;
}

Future<bool> ensureLoggedIn(
  BuildContext context, {
  String? message,
  String? title,
}) async {
  final auth = context.read<AuthNotifier>();
  if (auth.isLoggedIn) return true;

  final bool? shouldLogin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title ?? 'Cần đăng nhập'),
      content: Text(
        message ?? 'Bạn cần đăng nhập để sử dụng tính năng này.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Để sau'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5B00),
            foregroundColor: Colors.white,
          ),
          child: const Text('Đăng nhập'),
        ),
      ],
    ),
  );

  if (shouldLogin == true) {
    return openAuthScreen(context);
  }
  return false;
}
