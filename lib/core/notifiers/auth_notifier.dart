// lib/core/notifiers/auth_notifier.dart

import 'package:flutter/foundation.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';

class AuthNotifier with ChangeNotifier {
  final SecureStorageService _storageService = SecureStorageService();
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  AuthNotifier();

  Future<void> init() async {
    final token = await _storageService.getToken();
    _isLoggedIn = token != null;
  }

  void updateLoginState(bool isLoggedIn) {
    print(
      "--- [AuthNotifier] updateLoginState được gọi với giá trị: $isLoggedIn",
    );
    _isLoggedIn = isLoggedIn;
    print("--- [AuthNotifier] Chuẩn bị gọi notifyListeners().");
    notifyListeners();
    print("--- [AuthNotifier] Đã gọi notifyListeners().");
  }
}
