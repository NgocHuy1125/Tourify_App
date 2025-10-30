import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/wishlist/model/wishlist_model.dart';
import 'package:tourify_app/features/wishlist/presenter/wishlist_presenter.dart';
import 'package:tourify_app/features/wishlist/view/widgets/wish_tour_grid_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistPresenter>().loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistPresenter>(
      builder: (context, presenter, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black),
            title: const Text(
              'Yêu thích',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: false,
            actions: presenter.items.isNotEmpty &&
                    presenter.state == WishlistState.success
                ? [
                    IconButton(
                      onPressed: presenter.loadWishlist,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Làm mới',
                    ),
                  ]
                : null,
          ),
          body: _buildBody(presenter),
        );
      },
    );
  }

  Widget _buildBody(WishlistPresenter presenter) {
    switch (presenter.state) {
      case WishlistState.initial:
      case WishlistState.loading:
        return const Center(child: CircularProgressIndicator());
      case WishlistState.error:
        return _ErrorView(message: presenter.errorMessage);
      case WishlistState.empty:
        return presenter.isOnboarding
            ? _WishlistOnboardingView(presenter: presenter)
            : _WishlistEmptyStartView(presenter: presenter);
      case WishlistState.success:
        return RefreshIndicator(
          onRefresh: presenter.loadWishlist,
          child: _WishlistListView(
            items: presenter.items,
            onRemove: presenter.removeItem,
          ),
        );
    }
  }
}

class _WishlistEmptyStartView extends StatelessWidget {
  final WishlistPresenter presenter;
  const _WishlistEmptyStartView({required this.presenter});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_border,
                size: 120,
                color: Color(0xFFFF5B00),
              ),
              const SizedBox(height: 24),
              const Text(
                'Chưa có hoạt động nào ở đây',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bắt đầu khám phá và thêm vào Yêu thích.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: presenter.beginOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Bắt đầu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistOnboardingView extends StatelessWidget {
  final WishlistPresenter presenter;
  const _WishlistOnboardingView({required this.presenter});

  @override
  Widget build(BuildContext context) {
    final trending = presenter.trendingTours;
    final isLoading = presenter.isTrendingLoading;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thêm vào Yêu thích',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: presenter.showSavedList,
                      child: const Text('Bỏ qua'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chạm vào hình trái tim để thêm vào Yêu thích. Chúng tôi sẽ cập nhật cho bạn các chương trình ưu đãi.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: trending.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (context, index) {
                        final tour = trending[index];
                        final liked =
                            presenter.isTourFavourited(tour.id);
                        return WishTourGridCard(
                          tour: tour,
                          isLiked: liked,
                          onToggle: () =>
                              presenter.toggleFavouriteByTour(tour),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: ElevatedButton(
              onPressed: presenter.items.isEmpty
                  ? null
                  : presenter.showSavedList,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5B00),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              child: const Text('Xem danh sách Yêu thích'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistListView extends StatelessWidget {
  final List<WishlistItem> items;
  final ValueChanged<String> onRemove;
  const _WishlistListView({
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _WishlistListTile(
          item: item,
          onRemove: () => onRemove(item.id),
        );
      },
    );
  }
}

class _WishlistListTile extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onRemove;
  const _WishlistListTile({
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tour = item.tour;
    final currency = NumberFormat('#,##0', 'vi_VN');
    final cover =
        tour.mediaCover ?? 'https://via.placeholder.com/120x80?text=Tour';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              cover,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 96,
                height: 96,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tour.destination,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFFFB800)),
                    const SizedBox(width: 4),
                    Text(
                      tour.ratingAvg != null
                          ? tour.ratingAvg!.toStringAsFixed(1)
                          : 'Chưa có',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (tour.reviewsCount > 0)
                      Text(
                        ' (${tour.reviewsCount})',
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Từ đ ${currency.format(tour.priceFrom)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.favorite),
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message.isNotEmpty
              ? message
              : 'Đã xảy ra lỗi khi tải danh sách yêu thích.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
