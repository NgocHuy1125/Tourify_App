// lib/features/account/view/account_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  // Sample data - replace with real user data when API is integrated
  String _userName = 'Ng\u01b0\u1eddi d\u00f9ng Tourify';
  final String _avatarUrl = '';
  final String _level = 'B\u1ea1c';
  final int _levelNumber = 1;
  final String _rewardsInfo = '4 Quy\u1ec1n l\u1ee3i | X1 Tourify Xu';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountPresenter>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<AccountPresenter>();
    final state = presenter.state;

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
                _buildHeader(),
                const SizedBox(height: 110),
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
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
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
          final bool? didConfirm = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('X\u00e1c nh\u1eadn \u0111\u0103ng xu\u1ea5t'),
              content: const Text('B\u1ea1n c\u00f3 ch\u1eafc ch\u1eafn mu\u1ed1n \u0111\u0103ng xu\u1ea5t?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('H\u1ee7y'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(
                    '\u0110\u0103ng xu\u1ea5t',
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          '\u0110\u0103ng xu\u1ea5t',
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
        profile != null && profile.name.trim().isNotEmpty
            ? profile.name
            : _userName;
    final avatarUrl = profile?.avatarUrl ?? _avatarUrl;

    void openPersonalInfo() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
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
            child: avatarUrl.isEmpty
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
                      'C\u1eadp nh\u1eadt th\u00f4ng tin c\u00e1 nh\u00e2n',
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
                  'Nh\u1eadn ph\u1ea7n th\u01b0\u1edfng',
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
    final tripsPresenter = context.read<TripsPresenter>();
    await tripsPresenter.selectFilter(completedOnly ? 'completed' : 'all');
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TripsPresenter>.value(
          value: tripsPresenter,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                completedOnly ? '\u0110\u00e1nh gi\u00e1' : '\u0110\u01a1n h\u00e0ng',
              ),
            ),
            body: const TripsScreen(),
          ),
        ),
      ),
    );
  }

  void _openFeedback() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
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
            title: '\u0110\u01a1n h\u00e0ng',
            onTap: () => _openTrips(completedOnly: false),
          ),
          const Divider(height: 1, indent: 56),
          _ActionListTile(
            icon: Icons.rate_review_outlined,
            title: '\u0110\u00e1nh gi\u00e1',
            subtitle: 'Xem v\u00e0 c\u1eadp nh\u1eadt tour \u0111\u00e3 ho\u00e0n th\u00e0nh',
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
            title: 'Tr\u1ee3 gi\u00fap',
            onTap: _openFeedback,
          ),
          const Divider(height: 1, indent: 56),
          _ActionListTile(
            icon: Icons.settings_outlined,
            title: 'C\u00e0i \u0111\u1eb7t',
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
