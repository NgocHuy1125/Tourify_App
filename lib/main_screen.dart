import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'features/account/presenter/account_presenter.dart';
import 'features/account/view/account_screen.dart';
import 'features/booking/presenter/trips_presenter.dart';
import 'features/booking/view/trips_screen.dart';
import 'features/cart/presenter/cart_presenter.dart';
import 'features/home/view/home_screen.dart';
import 'features/home/view/promotions_list_screen.dart';
import 'features/home/view/widgets/home_header_search.dart';
import 'features/notifications/presenter/notification_presenter.dart';
import 'features/wishlist/view/wishlist_screen.dart';
import 'features/wishlist/presenter/wishlist_presenter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final AuthNotifier _authNotifier;
  late final VoidCallback _authListener;

  late final List<Widget> _pages = const [
    HomeScreen(),
    WishlistScreen(),
    PromotionsListScreen(),
    TripsScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _authNotifier = context.read<AuthNotifier>();
    _authListener = () => _handleAuthChanged();
    _authNotifier.addListener(_authListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAuthChanged(initial: true);
    });
  }

  @override
  void dispose() {
    _authNotifier.removeListener(_authListener);
    super.dispose();
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _handleAuthChanged({bool initial = false}) {
    if (!mounted) return;
    final isLoggedIn = _authNotifier.isLoggedIn;
    final cartPresenter = context.read<CartPresenter>();
    final wishlistPresenter = context.read<WishlistPresenter>();
    final tripsPresenter = context.read<TripsPresenter>();
    final notificationPresenter = context.read<NotificationPresenter>();
    final accountPresenter = context.read<AccountPresenter>();

    if (isLoggedIn) {
      if (cartPresenter.state == CartState.initial || !initial) {
        cartPresenter.loadCart();
      }
      notificationPresenter.refreshUnreadCount();
    } else {
      cartPresenter.reset();
      wishlistPresenter.resetForGuest();
      tripsPresenter.resetForGuest();
      notificationPresenter.reset();
      accountPresenter.clearProfile();
    }
  }

  PreferredSizeWidget? _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return const HomeHeaderSearch();
      case 3:
        return AppBar(title: const Text('Chuyến đi của tôi'));
      case 4:
        return AppBar(title: const Text('Tài khoản'));
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const klookOrangeColor = Color(0xFFFF5B00);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'Sale',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_travel_outlined),
            activeIcon: Icon(Icons.card_travel),
            label: 'Chuyến đi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: klookOrangeColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}
