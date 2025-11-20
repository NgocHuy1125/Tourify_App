// lib/features/auth/view/auth_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'package:tourify_app/features/auth/presenter/auth_presenter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Controllers cho các bước
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _didCompleteLogin = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFFF5B00);
    final isLoggedIn = context.watch<AuthNotifier>().isLoggedIn;
    if (isLoggedIn && !_didCompleteLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didCompleteLogin) return;
        _didCompleteLogin = true;
        Navigator.of(context).pop(true);
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Consumer<AuthPresenter>(
          builder: (context, presenter, _) {
            if (presenter.currentStep != AuthStep.selectMethod) {
              return IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black54),
                onPressed: () {
                  if (presenter.currentStep == AuthStep.enterIdentifier) {
                    presenter.goToStep(AuthStep.selectMethod);
                  } else if (presenter.currentStep == AuthStep.passwordLogin) {
                    presenter.goToStep(AuthStep.selectMethod);
                  } else {
                    presenter.goToStep(AuthStep.selectMethod);
                  }
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Consumer<AuthPresenter>(
        builder: (context, presenter, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (presenter.actionState == ActionState.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(presenter.errorMessage),
                  backgroundColor: Colors.redAccent,
                ),
              );
              presenter.resetActionState();
            }
          });

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder:
                (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: _buildCurrentStep(presenter, brandColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep(AuthPresenter presenter, Color brandColor) {
    switch (presenter.currentStep) {
      case AuthStep.selectMethod:
        return _buildSelectMethodStep(presenter);
      case AuthStep.enterIdentifier:
        return _buildEnterIdentifierStep(presenter, brandColor);
      case AuthStep.verifyOtp:
        return _buildVerifyOtpStep(presenter, brandColor);
      case AuthStep.passwordLogin:
        return _buildPasswordLoginStep(presenter, brandColor);
      case AuthStep.setPassword:
        return _buildSetPasswordStep(presenter, brandColor);
      case AuthStep.forgotPassword_EnterIdentifier:
        return _buildForgotPassword_EnterIdentifierStep(presenter, brandColor);
      case AuthStep.forgotPassword_VerifyOtp:
        return _buildForgotPassword_VerifyOtpStep(presenter, brandColor);
      case AuthStep.forgotPassword_SetNewPassword:
        return _buildForgotPassword_SetNewPasswordStep(presenter, brandColor);
    }
  }

  // --- WIDGETS CHO TỪNG BƯỚC (PHONG CÁCH KLOOK) ---

  Widget _buildSelectMethodStep(AuthPresenter presenter) {
    return Column(
      key: const ValueKey('SelectMethod'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'Đăng nhập hoặc Đăng ký',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 48),
        _AuthMethodButton(
          icon: FontAwesomeIcons.google,
          text: 'Google',
          onTap: () => presenter.handleGoogleLogin(),
          iconColor: Colors.redAccent,
        ),
        const SizedBox(height: 16),
        _AuthMethodButton(
          icon: Icons.phone_outlined,
          text: 'Số điện thoại',
          onTap: () => presenter.goToStep(AuthStep.enterIdentifier),
        ),
        const SizedBox(height: 16),
        _AuthMethodButton(
          icon: Icons.email_outlined,
          text: 'Email',
          onTap: () => presenter.goToStep(AuthStep.enterIdentifier),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => presenter.handleFacebookLogin(),
          icon: const FaIcon(
            FontAwesomeIcons.facebook,
            color: Colors.white,
            size: 20,
          ),
          label: const Text(
            'Facebook',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1877F2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const Spacer(),
        _buildTermsText(context),
      ],
    );
  }

  Widget _buildEnterIdentifierStep(AuthPresenter presenter, Color brandColor) {
    return Column(
      key: const ValueKey('EnterIdentifier'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Log in or sign up',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _identifierController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed:
              presenter.actionState == ActionState.loading
                  ? null
                  : () => presenter.sendLoginOrRegisterOtp(
                    _identifierController.text.trim(),
                  ),
          child: _buildLoadingIndicator(presenter, 'Gửi mã xác minh'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => presenter.goToStep(AuthStep.passwordLogin),
              child: const Text(
                'Đăng nhập bằng mật khẩu',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildTermsText(context),
      ],
    );
  }

  Widget _buildVerifyOtpStep(AuthPresenter presenter, Color brandColor) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Column(
      key: const ValueKey('VerifyOtp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xác thực OTP',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            children: [
              const TextSpan(text: 'Enter the verification code sent to\n'),
              TextSpan(
                text: presenter.identifier,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' Change',
                style: TextStyle(
                  color: brandColor,
                  decoration: TextDecoration.underline,
                ),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap =
                          () => presenter.goToStep(AuthStep.enterIdentifier),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Pinput(
            controller: _otpController,
            length: 6,
            autofocus: true,
            onCompleted: (pin) => presenter.verifyLoginOrRegisterOtp(pin),
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: brandColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(onPressed: () {}, child: Text('Resend in 55s')),
        ),
      ],
    );
  }

  Widget _buildPasswordLoginStep(AuthPresenter presenter, Color brandColor) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('PasswordLogin'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chào mừng trở lại.',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          if (presenter.identifier.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: brandColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      presenter.identifier,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => presenter.goToStep(AuthStep.enterIdentifier),
                    child: Text('Change', style: TextStyle(color: brandColor)),
                  ),
                ],
              ),
            ),
          if (presenter.identifier.isEmpty)
            TextFormField(
              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'Email hoặc Số điện thoại',
                border: OutlineInputBorder(),
              ),
              validator:
                  (v) =>
                      (v == null || v.isEmpty)
                          ? 'Vui lòng nhập thông tin'
                          : null,
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
            validator:
                (v) =>
                    (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed:
                presenter.actionState == ActionState.loading
                    ? null
                    : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        presenter.loginWithPassword(
                          presenter.identifier.isNotEmpty
                              ? presenter.identifier
                              : _identifierController.text,
                          _passwordController.text,
                        );
                      }
                    },
            child: _buildLoadingIndicator(presenter, 'Đăng nhập'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => presenter.goToStep(AuthStep.enterIdentifier),
                child: const Text(
                  'Sử dụng mã xác nhận',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              TextButton(
                onPressed:
                    () => presenter.goToStep(
                      AuthStep.forgotPassword_EnterIdentifier,
                    ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetPasswordStep(AuthPresenter presenter, Color brandColor) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('SetPassword'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tạo mật khẩu',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Tạo mật khẩu cho tài khoản mới của bạn: ${presenter.identifier}',
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu',
              border: OutlineInputBorder(),
            ),
            validator:
                (v) =>
                    (v == null || v.length < 6)
                        ? 'Mật khẩu phải có ít nhất 6 ký tự'
                        : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Xác nhận mật khẩu',
              border: OutlineInputBorder(),
            ),
            validator:
                (v) =>
                    (v != _newPasswordController.text)
                        ? 'Mật khẩu không khớp'
                        : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed:
                presenter.actionState == ActionState.loading
                    ? null
                    : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        presenter.setPasswordAndRegister(
                          _newPasswordController.text,
                          _confirmPasswordController.text,
                        );
                      }
                    },
            child: _buildLoadingIndicator(presenter, 'Hoàn tất'),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword_EnterIdentifierStep(
    AuthPresenter presenter,
    Color brandColor,
  ) {
    return Column(
      key: const ValueKey('ForgotIdentifier'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quên mật khẩu',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Nhập email hoặc số điện thoại của bạn để nhận mã xác thực đặt lại mật khẩu.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _identifierController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email hoặc Số điện thoại',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed:
              presenter.actionState == ActionState.loading
                  ? null
                  : () => presenter.sendForgotPasswordOtp(
                    _identifierController.text.trim(),
                  ),
          child: _buildLoadingIndicator(presenter, 'Gửi mã'),
        ),
      ],
    );
  }

  Widget _buildForgotPassword_VerifyOtpStep(
    AuthPresenter presenter,
    Color brandColor,
  ) {
    return _buildVerifyOtpStep(presenter, brandColor); // Giao diện giống hệt
  }

  Widget _buildForgotPassword_SetNewPasswordStep(
    AuthPresenter presenter,
    Color brandColor,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('ForgotSetNew'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Đặt lại mật khẩu',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu mới',
              border: OutlineInputBorder(),
            ),
            validator:
                (v) =>
                    (v == null || v.length < 6)
                        ? 'Mật khẩu phải có ít nhất 6 ký tự'
                        : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Xác nhận mật khẩu mới',
              border: OutlineInputBorder(),
            ),
            validator:
                (v) =>
                    (v != _newPasswordController.text)
                        ? 'Mật khẩu không khớp'
                        : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed:
                presenter.actionState == ActionState.loading
                    ? null
                    : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        presenter.setNewPassword(
                          _newPasswordController.text,
                          _confirmPasswordController.text,
                        );
                      }
                    },
            child: _buildLoadingIndicator(presenter, 'Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS TÁI SỬ DỤNG ---

  Widget _buildTermsText(BuildContext context) {
    return Text(
      'Bằng cách đăng ký, bạn đồng ý với Điều khoản Dịch vụ và Chính sách Bảo mật.',
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
    );
  }

  Widget _buildLoadingIndicator(AuthPresenter presenter, String text) {
    if (presenter.actionState == ActionState.loading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
      );
    }
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }
}

// Widget cho các nút chọn phương thức
class _AuthMethodButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color? iconColor;

  const _AuthMethodButton({
    required this.icon,
    required this.text,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            FaIcon(icon, color: iconColor ?? Colors.black54, size: 20),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
