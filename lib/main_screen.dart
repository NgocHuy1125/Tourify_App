// lib/main_screen.dart

import 'package:flutter/material.dart';
import 'features/account/view/account_screen.dart';
import 'features/promo_shop/view/promo_cart_screen.dart';
import 'features/promo_shop/view/promo_home_screen.dart';
import 'features/wishlist/view/wishlist_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const PromoHomeScreen(),
    const WishlistScreen(),
    const PromoCartScreen(),
    const Center(child: Text('Trang chuyen di (dang phat trien)')),
    const AccountScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  PreferredSizeWidget? _buildAppBar() {
    if (_selectedIndex == 0 || _selectedIndex == 2) {
      return null;
    }
    if (_selectedIndex == 4) return null;
    return AppBar(title: Text(_getAppBarTitle(_selectedIndex)));
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 1:
        return 'Yeu thich';
      case 3:
        return 'Chuyen di cua toi';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFFF5B00);

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
            label: 'Trang chu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Yeu thich',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Gio hang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_travel_outlined),
            activeIcon: Icon(Icons.card_travel),
            label: 'Chuyen di',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tai khoan',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: brandColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}
