import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/cart/presenter/cart_presenter.dart';
import 'package:tourify_app/features/cart/view/cart_screen.dart';
import 'package:tourify_app/features/search/view/search_screen.dart';

class HomeHeaderSearch extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeaderSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          readOnly: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
          decoration: const InputDecoration(
            hintText: 'Tìm điểm đến, tour...',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 10),
          ),
        ),
      ),
      actions: [
        Consumer<CartPresenter>(
          builder: (_, presenter, __) {
            final count = presenter.totalItems;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black54,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5B00),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
