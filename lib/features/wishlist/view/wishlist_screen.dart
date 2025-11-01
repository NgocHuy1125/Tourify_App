import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/wishlist/model/wishlist_model.dart';
import 'package:tourify_app/features/wishlist/presenter/wishlist_presenter.dart';
import 'package:tourify_app/features/wishlist/view/wishlist_compare_screen.dart';
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
      final presenter = context.read<WishlistPresenter>();
      if (presenter.state == WishlistState.initial) {
        presenter.loadWishlist();
      }
    });
  }

  Future<void> _handleCompare(BuildContext context) async {
    final presenter = context.read<WishlistPresenter>();
    if (!presenter.canCompare) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đủ 2 tour để so sánh.')),
      );
      return;
    }
    try {
      final tours = await presenter.compareSelectedTours();
      if (!mounted) return;
      if (tours.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể so sánh tour lúc này.')),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WishlistCompareScreen(tours: tours)),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isNotEmpty ? message : 'Không thể so sánh tour lúc này.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<WishlistPresenter>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final body = _buildBody(presenter);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Yêu thích',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions:
            presenter.items.isNotEmpty &&
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
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(child: body),
            if (presenter.hasCompareSelection)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16 + bottomInset,
                child: _WishlistCompareBar(
                  selected: presenter.compareCount,
                  canCompare: presenter.canCompare,
                  onCompare: () => _handleCompare(context),
                  onClear: presenter.clearCompareSelection,
                ),
              ),
          ],
        ),
      ),
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
          child: _WishlistGridView(
            items: presenter.items,
            presenter: presenter,
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Bắt đầu khám phá và thêm vào yêu thích để dễ dàng so sánh sau này.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 170,
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
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Khám phá tour'),
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
    if (presenter.isTrendingLoading && presenter.trendingTours.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final tours = presenter.trendingTours;
    if (tours.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Không có tour nổi bật để gợi ý.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: presenter.showSavedList,
                child: const Text('Quay lại danh sách của tôi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => presenter.refreshTrendingTours(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Gợi ý dành riêng cho bạn',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: presenter.showSavedList,
                        child: const Text('Xem yêu thích'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Đây là các tour đang được yêu thích. Lưu lại nếu bạn muốn theo dõi.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
            sliver: _WishlistGrid(
              tours: tours,
              presenter: presenter,
              isOnboarding: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistGridView extends StatelessWidget {
  final List<WishlistItem> items;
  final WishlistPresenter presenter;

  const _WishlistGridView({required this.items, required this.presenter});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 160),
          sliver: _WishlistGrid(wishlistItems: items, presenter: presenter),
        ),
      ],
    );
  }
}

class _WishlistGrid extends StatelessWidget {
  final List<WishlistItem>? wishlistItems;
  final List<TourSummary>? tours;
  final WishlistPresenter presenter;
  final bool isOnboarding;

  const _WishlistGrid({
    this.wishlistItems,
    this.tours,
    required this.presenter,
    this.isOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    final list = wishlistItems ?? tours ?? const [];
    final isWide = MediaQuery.of(context).size.width > 700;
    final crossAxisCount = isWide ? 3 : 2;
    final aspectRatio = isWide ? 0.85 : 0.6;

    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        final tour =
            wishlistItems != null ? wishlistItems![index].tour : tours![index];
        final wishlistItem =
            wishlistItems != null ? wishlistItems![index] : null;

        final isLiked =
            wishlistItem != null || presenter.isTourFavourited(tour.id);

        final isSelected = presenter.isSelectedForCompare(tour.id);
        final isDisabled =
            !isSelected &&
            presenter.isCompareLimitReached &&
            presenter.compareCount >= 2;

        return WishTourGridCard(
          tour: tour,
          isLiked: isLiked,
          isSelectedForCompare: isSelected,
          isCompareDisabled: isDisabled && !isOnboarding,
          onToggleLike:
              isOnboarding
                  ? () => presenter.toggleFavouriteByTour(tour)
                  : () => presenter.removeItem(wishlistItem!.id),
          onTap: () {},
          onToggleCompare:
              isOnboarding
                  ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hãy lưu tour vào danh sách để so sánh.'),
                      ),
                    );
                  }
                  : () {
                    final success = presenter.toggleCompareSelection(tour.id);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chỉ có thể so sánh tối đa 2 tour.'),
                        ),
                      );
                    }
                  },
        );
      }, childCount: list.length),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
    );
  }
}

class _WishlistCompareBar extends StatelessWidget {
  final int selected;
  final bool canCompare;
  final VoidCallback onCompare;
  final VoidCallback onClear;

  const _WishlistCompareBar({
    required this.selected,
    required this.canCompare,
    required this.onCompare,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'So sánh tour',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đã chọn $selected/2 tour',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('Bỏ chọn')),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: canCompare ? onCompare : null,
              icon: const Icon(Icons.table_view_rounded),
              label: const Text('So sánh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
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
