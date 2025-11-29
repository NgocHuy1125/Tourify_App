// lib/features/account/view/account_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'package:tourify_app/core/utils/auth_guard.dart';
import 'package:tourify_app/features/account/presenter/account_presenter.dart';
import 'package:tourify_app/features/account/view/account_settings_screen.dart';
import 'package:tourify_app/features/account/view/feedback_screen.dart';
import 'package:tourify_app/features/account/view/personal_info_screen.dart';
import 'package:tourify_app/features/booking/presenter/trips_presenter.dart';
import 'package:tourify_app/features/booking/view/trips_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _userName = 'Người dùng VietTravel';
  final String _avatarUrl = '';
  final String _level = 'KH';
  final int _levelNumber = 1;
  final String _rewardsInfo = '4 Quyền lợi | Nhiều ưu đãi';
  late final AuthNotifier _authNotifier;
  late final VoidCallback _authListener;

  @override
  void initState() {
    super.initState();
    _authNotifier = context.read<AuthNotifier>();
    _authListener = _handleAuthChanged;
    _authNotifier.addListener(_authListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAuthChanged();
    });
  }

  @override
  void dispose() {
    _authNotifier.removeListener(_authListener);
    super.dispose();
  }

  void _handleAuthChanged() {
    final presenter = context.read<AccountPresenter>();
    if (_authNotifier.isLoggedIn) {
      presenter.loadProfile();
    } else {
      presenter.clearProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<AccountPresenter>();
    final state = presenter.state;
    final isLoggedIn = context.watch<AuthNotifier>().isLoggedIn;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state == AccountState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(presenter.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        presenter.resetState();
      }
    });

    final bool isLoading = state == AccountState.loading;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(isLoggedIn),
                const SizedBox(height: 110),
                _buildMainActionGroup(),
                const SizedBox(height: 16),
                _buildSecondaryActionGroup(),
                const SizedBox(height: 24),
                if (isLoggedIn) _buildLogoutButton() else _buildLoginButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.1),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(bool isLoggedIn) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _buildHeaderBackground(),
        Positioned(
          top: 45,
          left: 16,
          right: 16,
          child: Column(
            children: [
              _buildUserProfileHeader(isLoggedIn),
              const SizedBox(height: 16),
              if (isLoggedIn) _buildUserRewardsCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: OutlinedButton(
        onPressed: () async {
          final bool? didConfirm = await showDialog<bool>(
            context: context,
            builder:
                (dialogContext) => AlertDialog(
                  title: const Text('Xác nhận đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
          );

          if (didConfirm == true && mounted) {
            context.read<AccountPresenter>().signOut();
          }
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Đăng xuất',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: () => openAuthScreen(context),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Đăng nhập hoặc Đăng ký',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00B6D8), Color(0xFF007E9B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
    );
  }

  Widget _buildUserProfileHeader(bool isLoggedIn) {
    final presenter = context.watch<AccountPresenter>();
    final profile = presenter.profile;
    final name =
        profile != null && profile.name.trim().isNotEmpty
            ? profile.name
            : _userName;
    final avatarUrl = profile?.avatarUrl ?? _avatarUrl;

    void openPersonalInfo() {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PersonalInfoScreen()));
    }

    if (!isLoggedIn) {
      return GestureDetector(
        onTap: () => openAuthScreen(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Đăng nhập hoặc Đăng ký',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chạm để đăng nhập và đồng bộ thông tin tài khoản.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: openPersonalInfo,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade300,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child:
                avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 30, color: Colors.white)
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cập nhật thông tin cá nhân',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRewardsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.compass_calibration_outlined,
            color: Color(0xFF007E9B),
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.$_levelNumber $_level',
                    style: const TextStyle(
                      color: Color(0xFF007E9B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _rewardsInfo,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nhận phần thưởng',
                  style: TextStyle(
                    color: Color(0xFFFF5B00),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.chevron_right, color: Color(0xFFFF5B00), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTrips({required bool completedOnly}) async {
    if (!await _ensureLoggedIn()) return;
    final tripsPresenter = context.read<TripsPresenter>();
    await tripsPresenter.selectFilter(completedOnly ? 'completed' : 'all');
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider<TripsPresenter>.value(
              value: tripsPresenter,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(completedOnly ? 'Đánh giá' : 'Đơn hàng'),
                ),
                body: const TripsScreen(),
              ),
            ),
      ),
    );
  }

  void _openFeedback() {
    _ensureLoggedIn().then((allowed) {
      if (!allowed || !mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FeedbackScreen()));
    });
  }

  Future<bool> _ensureLoggedIn() {
    return ensureLoggedIn(
      context,
      message: 'Vui lòng đăng nhập để sử dụng tính năng này.',
    );
  }

  Widget _buildMainActionGroup() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _ActionListTile(
            icon: Icons.receipt_long_outlined,

            title: 'Đơn hàng',
            onTap: () => _openTrips(completedOnly: false),
          ),
          const Divider(height: 1, indent: 56),
          _ActionListTile(
            icon: Icons.rate_review_outlined,

            title: 'Đánh giá',

            subtitle: 'Xem và cập nhật tour đã hoàn thành',
            onTap: () => _openTrips(completedOnly: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionGroup() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _ActionListTile(
            icon: Icons.help_outline,

            title: 'Trợ giúp',
            onTap: _openFeedback,
          ),
          const Divider(height: 1, indent: 56),
          _ActionListTile(
            icon: Icons.settings_outlined,

            title: 'Cài đặt',
            onTap: () {
              _ensureLoggedIn().then((allowed) {
                if (!allowed || !mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsScreen(),
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}

class _ActionListTile extends StatelessWidget {
  const _ActionListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle:
          subtitle != null
              ? Text(
                subtitle!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              )
              : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
