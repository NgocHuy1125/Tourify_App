import 'package:flutter/foundation.dart';

import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'package:tourify_app/features/account/model/account_repository.dart';
import 'package:tourify_app/features/account/model/user_profile.dart';
import 'package:tourify_app/features/auth/model/auth_repository.dart';

enum AccountState { initial, loading, signedOut, error }

class AccountPresenter with ChangeNotifier {
  AccountPresenter(
    this._authRepository,
    this._authNotifier,
    this._accountRepository,
  );

  final AuthRepository _authRepository;
  final AuthNotifier _authNotifier;
  final AccountRepository _accountRepository;

  AccountState _state = AccountState.initial;
  AccountState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  String get displayName => _profile?.name ?? 'Người dùng Tourify';

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  bool _notificationLoading = false;
  bool get notificationLoading => _notificationLoading;

  Map<String, bool> _notificationPreferences = const {};
  Map<String, bool> get notificationPreferences => _notificationPreferences;

  Future<void> loadProfile() async {
    try {
      final data = await _accountRepository.getProfile();
      _profile = data;
      _errorMessage = '';
      if (data != null) {
        _notificationPreferences = Map<String, bool>.from(
          data.notificationPreferences,
        );
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
    }
  }

  Future<void> loadNotificationPreferences() async {
    _notificationLoading = true;
    notifyListeners();
    try {
      final prefs = await _accountRepository.getNotificationPreferences();
      if (prefs.isNotEmpty) {
        _notificationPreferences = prefs;
      }
    } catch (e) {
      _errorMessage = _formatError(e);
    } finally {
      _notificationLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNotificationPreference(String key, bool value) async {
    final previous = Map<String, bool>.from(_notificationPreferences);
    _notificationPreferences[key] = value;
    notifyListeners();

    try {
      final updated = await _accountRepository.updateNotificationPreferences(
        _notificationPreferences,
      );
      if (updated.isNotEmpty) {
        _notificationPreferences = updated;
      }
      _errorMessage = '';
    } catch (e) {
      _notificationPreferences = previous;
      _errorMessage = _formatError(e);
      notifyListeners();
    }
  }

  void resetState() {
    _state = AccountState.initial;
    _errorMessage = '';
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    _isSaving = true;
    notifyListeners();
    try {
      final updated = await _accountRepository.updateProfile(payload);
      if (updated != null) {
        _profile = updated;
      } else if (_profile != null) {
        _profile = _profile!.copyWith(
          name: payload['name'] as String?,
          email: payload['email'] as String?,
          phone: payload['phone'] as String?,
          gender: payload['gender'] as String?,
          birthday:
              payload['birthday'] is String
                  ? DateTime.tryParse(payload['birthday'] as String)
                  : payload['birthday'] as DateTime?,
          country: payload['country'] as String?,
          addressLine1: payload['address_line1'] as String?,
          addressLine2: payload['address_line2'] as String?,
          city: payload['city'] as String?,
          state: payload['state'] as String?,
          postalCode: payload['postal_code'] as String?,
          address: payload['address'] as String?,
          googleAccount: payload['google_account'] as String?,
          facebookAccount: payload['facebook_account'] as String?,
        );
      }
      _errorMessage = '';
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isChangingPassword = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _accountRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  Future<bool> submitFeedback(String message) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _accountRepository.submitFeedback(message);
      _errorMessage = '';
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _state = AccountState.loading;
    notifyListeners();
    try {
      await _authRepository.signOut();
      _authNotifier.updateLoginState(false);
      _state = AccountState.signedOut;
      _errorMessage = '';
    } catch (_) {
      _errorMessage = 'Không thể đăng xuất. Vui lòng thử lại.';
      _state = AccountState.error;
    } finally {
      notifyListeners();
    }
  }

  String _formatError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }
}
