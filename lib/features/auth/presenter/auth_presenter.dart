// lib/features/auth/presenter/auth_presenter.dart

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'package:tourify_app/features/auth/model/auth_repository.dart';

enum AuthStep {
  selectMethod,
  enterIdentifier,
  verifyOtp,
  setPassword,
  passwordLogin,
  forgotPassword_EnterIdentifier,
  forgotPassword_VerifyOtp,
  forgotPassword_SetNewPassword,
}

enum ActionState { initial, loading, success, error }

class AuthPresenter with ChangeNotifier {
  final AuthRepository _repository;
  final AuthNotifier _authNotifier;

  AuthPresenter(this._repository, this._authNotifier);

  AuthStep _currentStep = AuthStep.selectMethod;
  ActionState _actionState = ActionState.initial;
  String _errorMessage = '';
  String _identifier = '';

  String _otpId = '';
  String _verifiedOtp = '';

  AuthStep get currentStep => _currentStep;
  ActionState get actionState => _actionState;
  String get errorMessage => _errorMessage;
  String get identifier => _identifier;

  void goToStep(AuthStep step) {
    _currentStep = step;
    _errorMessage = '';
    _actionState = ActionState.initial;
    notifyListeners();
  }

  void resetActionState() {
    _actionState = ActionState.initial;
  }

  Future<void> sendLoginOrRegisterOtp(String identifier) async {
    _identifier = identifier;
    _actionState = ActionState.loading;
    notifyListeners();
    try {
      await _repository.sendLoginOrRegisterOtp(identifier: identifier);
      _actionState = ActionState.success;
      goToStep(AuthStep.verifyOtp);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _actionState = ActionState.error;
      notifyListeners();
    }
  }

  Future<void> verifyLoginOrRegisterOtp(String otp) async {
    _actionState = ActionState.loading;
    notifyListeners();
    try {
      final result = await _repository.verifyLoginOrRegisterOtp(
        identifier: _identifier,
        otp: otp,
      );
      _verifiedOtp = otp;

      final token =
          (result['access_token'] ?? result['token'] ?? '').toString().trim();
      final mode = (result['mode'] ?? result['flow'] ?? '').toString();
      final requiresPassword =
          result['requires_password'] == true ||
          result['need_password'] == true ||
          result['needs_password'] == true ||
          result['is_new_user'] == true ||
          result['user_exists'] == false ||
          mode.toLowerCase() == 'register' ||
          token.isEmpty;

      if (!requiresPassword && token.isNotEmpty) {
        _authNotifier.updateLoginState(true);
        _actionState = ActionState.success;
        notifyListeners();
        return;
      }

      _actionState = ActionState.success;
      notifyListeners();
      goToStep(AuthStep.setPassword);
      return;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _actionState = ActionState.error;
      notifyListeners();
    }
  }

  Future<void> setPasswordAndRegister(
    String password,
    String confirmPassword,
  ) async {
    if (password != confirmPassword) {
      _errorMessage = 'Mat khau khong khop.';
      _actionState = ActionState.error;
      notifyListeners();
      return;
    }

    _actionState = ActionState.loading;
    notifyListeners();
    try {
      final isEmail = _identifier.contains('@');
      await _repository.signUp(
        name: 'New User',
        email: isEmail ? _identifier : '',
        phone: isEmail ? '' : _identifier,
        password: password,
      );
      _authNotifier.updateLoginState(true);
      _actionState = ActionState.success;
    } catch (e) {
      final rawMessage = e.toString().replaceFirst('Exception: ', '');
      if (rawMessage.contains('duplicate') ||
          rawMessage.contains('already exists') ||
          rawMessage.contains('users_email_key') ||
          rawMessage.contains('users_phone_key')) {
        _errorMessage =
            'Tài khoản đã tồn tại. Vui lòng đăng nhập hoặc dùng chức năng Quên mật khẩu.';
      } else {
        _errorMessage = rawMessage;
      }
      _actionState = ActionState.error;
    }
    notifyListeners();
  }

  Future<void> loginWithPassword(String identifier, String password) async {
    _identifier = identifier;
    _actionState = ActionState.loading;
    notifyListeners();
    try {
      await _repository.signIn(identifier: identifier, password: password);
      _authNotifier.updateLoginState(true);
      _actionState = ActionState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _actionState = ActionState.error;
    }
    notifyListeners();
  }

  Future<void> handleGoogleLogin() async {
    _actionState = ActionState.loading;
    notifyListeners();
    try {
      final webClientId =
          dotenv.env['GOOGLE_CLIENT_ID_WEB'] ??
          dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
          dotenv.env['GOOGLE_CLIENT_ID'] ??
          '';
      final androidClientId = dotenv.env['GOOGLE_CLIENT_ID_ANDROID'] ?? '';
      if (webClientId.isEmpty && androidClientId.isEmpty) {
        throw Exception(
          'Thiếu GOOGLE_CLIENT_ID_WEB/GOOGLE_CLIENT_ID_ANDROID trong .env',
        );
      }

      // Dùng web client ID làm serverClientId để nhận idToken; nếu thiếu thì chỉ dùng Android ID.
      final googleSignIn = GoogleSignIn(
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
        clientId: androidClientId.isNotEmpty ? androidClientId : null,
        scopes: const ['email', 'profile'],
      );

      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Đăng nhập Google đã bị hủy.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Không lấy được idToken từ Google (kiểm tra serverClientId).',
        );
      }

      await _repository.handleGoogleMobile(idToken: idToken);
      _authNotifier.updateLoginState(true);
      _actionState = ActionState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _actionState = ActionState.error;
    }
    notifyListeners();
  }

  Future<void> handleFacebookLogin() async {
    _actionState = ActionState.loading;
    notifyListeners();
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        await _repository.handleSocialLoginCallback(
          provider: 'facebook',
          code: accessToken.tokenString,
        );
        _authNotifier.updateLoginState(true);
        _actionState = ActionState.success;
      } else {
        throw Exception('Dang nhap Facebook that bai.');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _actionState = ActionState.error;
    }
    notifyListeners();
  }

  Future<void> sendForgotPasswordOtp(String identifier) async {
    _identifier = identifier;
    _actionState = ActionState.loading;
    notifyListeners();
    try {
      await _repository.sendForgotPasswordOtp(identifier: identifier);
      _actionState = ActionState.success;
      goToStep(AuthStep.forgotPassword_VerifyOtp);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _actionState = ActionState.error;
      notifyListeners();
    }
  }

  Future<void> verifyForgotPasswordOtp(String otp) async {
    _actionState = ActionState.loading;
    notifyListeners();
    try {
      final response = await _repository.verifyForgotPasswordOtp(
        identifier: _identifier,
        otp: otp,
      );
      _otpId = response['otp_id'].toString();
      _verifiedOtp = otp;
      _actionState = ActionState.success;
      goToStep(AuthStep.forgotPassword_SetNewPassword);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _actionState = ActionState.error;
      notifyListeners();
    }
  }

  Future<void> setNewPassword(
    String newPassword,
    String confirmPassword,
  ) async {
    _actionState = ActionState.loading;
    notifyListeners();
    try {
      await _repository.setNewPassword(
        otpId: _otpId,
        identifier: _identifier,
        channel: _identifier.contains('@') ? 'email' : 'phone',
        otp: _verifiedOtp,
        newPassword: newPassword,
        passwordConfirmation: confirmPassword,
      );
      _actionState = ActionState.success;
      goToStep(AuthStep.passwordLogin);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _actionState = ActionState.error;
      notifyListeners();
    }
  }
}
