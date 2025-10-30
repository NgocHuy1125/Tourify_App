import 'package:flutter/foundation.dart';
import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'package:tourify_app/features/account/model/account_repository.dart';
import 'package:tourify_app/features/account/model/user_profile.dart';
import 'package:tourify_app/features/auth/model/auth_repository.dart';

enum AccountState { initial, loading, signedOut, error }

class AccountPresenter with ChangeNotifier {
  final AuthRepository _authRepository;
  final AuthNotifier _authNotifier;
  final AccountRepository _accountRepository;

  AccountPresenter(
    this._authRepository,
    this._authNotifier,
    this._accountRepository,
  );

  AccountState _state = AccountState.initial;
  AccountState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  String get displayName => _profile?.name ?? 'Nguoi dung Tourify';

  Future<void> loadProfile() async {
    try {
      final data = await _accountRepository.getProfile();
      _profile = data;
      notifyListeners();
    } catch (_) {
      // ignore for now; keep old profile if any
    }
  }

  void resetState() {
    _state = AccountState.initial;
    _errorMessage = '';
    notifyListeners();
  }

  /// Handle sign out flow and update listeners
  Future<void> signOut() async {
    _state = AccountState.loading;
    notifyListeners();
    try {
      await _authRepository.signOut();
      _authNotifier.updateLoginState(false);
      _state = AccountState.signedOut;
    } catch (_) {
      _errorMessage = 'Không thể đăng xuất. Vui lòng thử lại.';
      _state = AccountState.error;
    } finally {
      notifyListeners();
    }
  }
}
