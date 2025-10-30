// lib/features/account/view/account_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/account/presenter/account_presenter.dart';
import 'package:tourify_app/features/account/view/account_settings_screen.dart';
import 'package:tourify_app/features/account/view/personal_info_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Dữ liệu mẫu - Sau này bạn sẽ lấy từ thông tin user thật
  String _userName = 'Người dùng Tourify';
  final String _avatarUrl = '';
  final String _level = 'Bạc';
  final int _levelNumber = 1;
  final String _rewardsInfo = '4 Quyền lợi | X1 Tourify Xu';
  final int _vouchers = 0;
  final int _points = 0;
  final int _giftCards = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountPresenter>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dùng watch để lắng nghe presenter và rebuild UI khi có thay đổi (ví dụ: loading)
    final presenter = context.watch<AccountPresenter>();
    final state = presenter.state;

    // Xử lý các hành động một lần (side-effects) như hiển thị SnackBar lỗi
    // Logic điều hướng khi đăng xuất thành công đã được GoRouter xử lý tự động
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state == AccountState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(presenter.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        // Quan trọng: Reset lại trạng thái để SnackBar không hiện lại
        presenter.resetState();
      }
    });

    final bool isLoading = state == AccountState.loading;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          // Không cần AppBar vì chúng ta tự vẽ header
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(
                  height: 110,
                ), // Khoảng trống để các card không bị header che
                _buildUserStatsCard(),
                const SizedBox(height: 16),
                _buildMainActionGroup(),
                const SizedBox(height: 16),
                _buildSecondaryActionGroup(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        // Hiển thị lớp loading overlay khi đang xử lý đăng xuất
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  // --- WIDGETS ---

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _buildHeaderBackground(),
        Positioned(
          top: 45, // Căn chỉnh vị trí từ trên xuống
          left: 16,
          right: 16,
          child: Column(
            children: [
              _buildUserProfileHeader(),
              const SizedBox(height: 16),
              _buildUserRewardsCard(),
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
          // Hiển thị dialog xác nhận trước khi đăng xuất
          final bool? didRequestSignOut = await showDialog<bool>(
            context: context,
            builder:
                (BuildContext dialogContext) => AlertDialog(
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

          // Chỉ gọi signOut nếu người dùng đã xác nhận
          if (didRequestSignOut == true) {
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

  Widget _buildUserProfileHeader() {
    final presenter = context.watch<AccountPresenter>();
    final profile = presenter.profile;
    final name =
        (profile?.name?.trim().isNotEmpty ?? false) ? profile!.name : _userName;
    final avatarUrl = profile?.avatarUrl ?? _avatarUrl;

    void openPersonalInfo() {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PersonalInfoScreen()));
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
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.8),
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
            color: Colors.black.withOpacity(0.1),
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

  Widget _buildUserStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.add,
            label: 'Mã ưu đãi',
            value: _vouchers.toString(),
          ),
          _buildStatItem(label: 'Tourify Xu', value: _points.toString()),
          _buildStatItem(
            label: 'Tourify Gift Card',
            value: _giftCards.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    IconData? icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        if (icon != null)
          Icon(icon, color: Colors.grey.shade600)
        else
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
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
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _ActionListTile(
            icon: Icons.person_outline,
            title: 'Thông tin thường dùng',
            subtitle: 'Quản lý thông tin khách trên đơn hàng...',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _ActionListTile(
            icon: Icons.chat_bubble_outline,
            title: 'Đánh giá',
            onTap: () {},
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
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _ActionListTile(
            icon: Icons.star_outline,
            title: 'Đánh giá ứng dụng',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _ActionListTile(
            icon: Icons.settings_outlined,
            title: 'Cài đặt',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccountSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

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
