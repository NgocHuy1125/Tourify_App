import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/home/model/home_models.dart';
import 'package:tourify_app/features/home/model/recent_tour_storage.dart';
import 'package:tourify_app/features/cart/presenter/cart_presenter.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/tour/model/tour_repository.dart';
import 'package:tourify_app/features/tour/view/widgets/tour_booking_sheet.dart';
import 'package:tourify_app/features/tour/view/widgets/tour_detail_header.dart';
import 'package:tourify_app/features/tour/view/widgets/tour_detail_sections.dart';
import 'package:tourify_app/features/tour/view/widgets/tour_detail_tabs.dart';
import 'package:tourify_app/features/wishlist/presenter/wishlist_presenter.dart';
import '../../cart/view/cart_screen.dart';

class TourDetailPage extends StatefulWidget {
  final String id;
  const TourDetailPage({super.key, required this.id});

  @override
  State<TourDetailPage> createState() => _TourDetailPageState();
}

class _TourDetailPageState extends State<TourDetailPage> {
  late Future<_TourDetailBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TourDetailBundle> _load() async {
    final repo = context.read<TourRepository>();
    final detail = await repo.getTourDetails(widget.id);

    unawaited(Future(() async {
      try {
        await repo.trackTourView(widget.id);
      } catch (_) {
        // ignore tracking error
      }
    }));

    final storage = context.read<RecentTourStorage>();
    final summary = detail.toSummary();
    await storage.upsert(
      RecentTourItem.fromSummary(
        summary,
        viewedAt: DateTime.now(),
      ),
    );

    TourReviewsResponse reviews;
    try {
      reviews = await repo.fetchTourReviews(widget.id);
    } catch (_) {
      reviews = TourReviewsResponse(
        reviews: const [],
        average: detail.ratingAvg ?? 0,
        count: detail.reviewsCount,
      );
    }

    List<TourSummary> suggestions;
    try {
      suggestions = await repo.fetchSuggestedTours(
        excludeTourId: widget.id,
        limit: 6,
      );
    } catch (_) {
      suggestions = const [];
    }

    return _TourDetailBundle(
      detail: detail,
      reviews: reviews,
      suggestions: suggestions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TourDetailBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết tour')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Không thể tải thông tin tour. Vui lòng thử lại sau.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return _TourDetailView(bundle: snapshot.data!);
      },
    );
  }
}

class _TourDetailView extends StatefulWidget {
  final _TourDetailBundle bundle;
  const _TourDetailView({required this.bundle});

  @override
  State<_TourDetailView> createState() => _TourDetailViewState();
}

class _TourDetailViewState extends State<_TourDetailView> {
  final ScrollController _controller = ScrollController();
  final ValueNotifier<int> _activeSection = ValueNotifier(0);
  final ValueNotifier<bool> _showStickyTabs = ValueNotifier(false);
  final _sectionKeys = List.generate(4, (_) => GlobalKey());
  bool _wishlistBusy = false;

  static const _tabs = [
    'Các gói dịch vụ',
    'Đánh giá',
    'Về dịch vụ này',
    'Bạn có thể thích',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartPresenter = context.read<CartPresenter>();
      if (cartPresenter.state == CartState.initial) {
        cartPresenter.loadCart();
      }
      final wishlist = context.read<WishlistPresenter>();
      if (wishlist.state == WishlistState.initial) {
        wishlist.loadWishlist();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final offset = _controller.offset;
    _showStickyTabs.value = offset > 280;

    for (var i = 0; i < _sectionKeys.length; i++) {
      final keyContext = _sectionKeys[i].currentContext;
      if (keyContext == null) continue;
      final box = keyContext.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final position = box.localToGlobal(Offset.zero);
      if (position.dy <= kToolbarHeight + 80) {
        _activeSection.value = i;
      }
    }
  }

  void _scrollToSection(int index) {
    final keyContext = _sectionKeys[index].currentContext;
    if (keyContext == null) return;
    Scrollable.ensureVisible(
      keyContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.bundle.detail;
    final minPrice =
        detail.packages.isNotEmpty
            ? detail.packages.map((pkg) => pkg.adultPrice).reduce(min)
            : (detail.priceAfterDiscount ?? detail.basePrice);
    final priceText = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(minPrice);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _controller,
            slivers: [
              _buildAppBar(detail),
              SliverToBoxAdapter(
                child: TourDetailHeader(
                  detail: detail,
                  reviews: widget.bundle.reviews,
                ),
              ),
              SliverToBoxAdapter(
                child: StickyTabPlaceholder(
                  titles: _tabs,
                  activeSection: _activeSection,
                  notifier: _showStickyTabs,
                  onTap: _scrollToSection,
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  SectionAnchor(
                    key: _sectionKeys[0],
                    child: ServiceSection(detail: detail),
                  ),
                  SectionAnchor(
                    key: _sectionKeys[1],
                    child: ReviewSection(reviews: widget.bundle.reviews),
                  ),
                  SectionAnchor(
                    key: _sectionKeys[2],
                    child: AboutSection(detail: detail),
                  ),
                  SectionAnchor(
                    key: _sectionKeys[3],
                    child: SuggestionSection(
                      suggestions: widget.bundle.suggestions,
                      onTap: (tour) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TourDetailPage(id: tour.id),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 120),
                ]),
              ),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _showStickyTabs,
            builder: (_, show, __) {
              if (!show) return const SizedBox.shrink();
              return Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight - 8,
                left: 0,
                right: 0,
                child: PinnedTabs(
                  titles: _tabs,
                  activeSection: _activeSection,
                  onTap: _scrollToSection,
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomCTA(detail: detail, priceText: priceText),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(TourDetail detail) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 320,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        Consumer<WishlistPresenter>(
          builder: (_, wishlist, __) {
            final isFavourite = wishlist.isTourFavourited(detail.id);
            return IconButton(
              onPressed:
                  _wishlistBusy
                      ? null
                      : () => _toggleFavourite(detail, wishlist),
              icon:
                  _wishlistBusy
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: isFavourite ? const Color(0xFFFF5B00) : null,
                      ),
              tooltip: isFavourite ? 'Bỏ khỏi yêu thích' : 'Thêm vào yêu thích',
            );
          },
        ),
        Consumer<CartPresenter>(
          builder: (_, cart, __) {
            return _CartActionIcon(
              count: cart.totalItems,
              onPressed: () {
                if (cart.state == CartState.initial ||
                    cart.state == CartState.error) {
                  cart.loadCart();
                }
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
              },
            );
          },
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
      ],
      flexibleSpace: FlexibleSpaceBar(background: HeroCarousel(detail: detail)),
    );
  }

  Future<void> _toggleFavourite(
    TourDetail detail,
    WishlistPresenter wishlist,
  ) async {
    if (_wishlistBusy) return;
    setState(() => _wishlistBusy = true);
    try {
      await wishlist.toggleFavouriteByTour(_summaryFromDetail(detail));
    } finally {
      if (mounted) setState(() => _wishlistBusy = false);
    }
  }

  TourSummary _summaryFromDetail(TourDetail detail) {
    return TourSummary(
      id: detail.id,
      title: detail.title,
      destination: detail.destination,
      duration: detail.duration,
      priceFrom: detail.basePrice,
      ratingAvg: detail.ratingAvg,
      reviewsCount: detail.reviewsCount,
      mediaCover: detail.media.isNotEmpty ? detail.media.first : null,
      tags: detail.tags,
      bookingsCount: detail.bookingsCount,
      type: detail.type,
      childAgeLimit: detail.childAgeLimit,
      requiresPassport: detail.requiresPassport,
      requiresVisa: detail.requiresVisa,
    );
  }
}

class BottomCTA extends StatelessWidget {
  final TourDetail detail;
  final String priceText;
  const BottomCTA({super.key, required this.detail, required this.priceText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Từ', style: TextStyle(color: Colors.black54)),
                Text(
                  priceText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final packages =
                  detail.packages.where((pkg) => pkg.isActive).toList();
              if (packages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chưa có gói dịch vụ khả dụng.'),
                  ),
                );
                return;
              }
              BookingSheet.show(
                context,
                detail: detail,
                package: packages.first,
                schedules: detail.schedules,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5B00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            child: const Text('Chọn gói'),
          ),
        ],
      ),
    );
  }
}

class _CartActionIcon extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _CartActionIcon({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.shopping_cart_outlined),
          tooltip: 'Xem giỏ hàng',
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
  }
}

class _TourDetailBundle {
  final TourDetail detail;
  final TourReviewsResponse reviews;
  final List<TourSummary> suggestions;

  _TourDetailBundle({
    required this.detail,
    required this.reviews,
    required this.suggestions,
  });
}
