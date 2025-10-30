import 'promo_models.dart';

abstract class PromoRepository {
  Future<PromoHomeData> fetchHome();
  Future<PromoCart> fetchCart();
}

/// Mock data source so the client interface can be demonstrated without a
/// running Cassandra backend. Each sample mirrors the columns in the provided
/// tables (products, promotions, promotion_tiers, user_carts).
class MockPromoRepository implements PromoRepository {
  MockPromoRepository({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;

  @override
  Future<PromoHomeData> fetchHome() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final spotlight = _promotions.take(3).toList();
    final featured =
        _products.where((p) => p.categoryId == 'electronics').toList();
    final combos = _products.where((p) => p.categoryId == 'bundles').toList();

    return PromoHomeData(
      spotlightPromotions: spotlight,
      featuredProducts: featured,
      trendingCombos: combos,
      categories: _categories,
    );
  }

  @override
  Future<PromoCart> fetchCart() async {
    await Future.delayed(const Duration(milliseconds: 240));

    final cartItems = <PromoCartItem>[
      PromoCartItem(
        product: _products.firstWhere((p) => p.productId == 'P1001'),
        quantity: 1,
        price: 1890000.0,
        appliedPromotion: const PromotionSummary(
          promoId: 'PRM_FLASH10',
          title: 'Flash Sale 10%',
        ),
      ),
      PromoCartItem(
        product: _products.firstWhere((p) => p.productId == 'P3001'),
        quantity: 3,
        price: 98000.0,
        appliedPromotion: const PromotionSummary(
          promoId: 'PRM_MEMBER',
          title: 'Tang qua tung bac',
        ),
      ),
      PromoCartItem(
        product: _products.firstWhere((p) => p.productId == 'P4002'),
        quantity: 1,
        price: 759000.0,
        appliedPromotion: const PromotionSummary(
          promoId: 'PRM_MEMBER',
          title: 'Qua tang Platinum',
        ),
      ),
    ];

    final subtotal =
        cartItems.fold<double>(0, (sum, item) => sum + item.lineSubtotal);
    final discount = subtotal * 0.12;
    final shippingFee = subtotal >= 500000 ? 0.0 : 25000.0;
    final total = subtotal - discount + shippingFee;

    return PromoCart(
      items: cartItems,
      totals: PromoCartTotals(
        subtotal: subtotal,
        discount: discount,
        shippingFee: shippingFee,
        finalAmount: total,
        bestPromotion: const PromotionSummary(
          promoId: 'PRM_MEMBER',
          title: 'Uu dai thanh vien bac Vang',
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Mock seeds

  late final List<Promotion> _promotions = [
    Promotion(
      promoId: 'PRM_FLASH10',
      title: 'Flash Sale 10%',
      type: 'flash_sale',
      minOrder: 200000.0,
      discountPercent: 10,
      rewardType: 'discount_percent',
      maxDiscountAmount: 150000.0,
      startDate: _now.subtract(const Duration(days: 2)),
      endDate: _now.add(const Duration(days: 3)),
      status: 'ACTIVE',
      autoApply: false,
      stackable: false,
      createdAt: _now.subtract(const Duration(days: 7)),
      updatedAt: _now.subtract(const Duration(days: 1)),
      badge: 'Hot',
      tiers: [
        PromotionTier(
          promoId: 'PRM_FLASH10',
          tierLevel: 1,
          label: 'Don tu 200K',
          minValue: 200000.0,
          discountPercent: 10,
          metadata: const {'color': '#FF5B00'},
        ),
      ],
    ),
    Promotion(
      promoId: 'PRM_MEMBER',
      title: 'Uu dai thanh vien',
      type: 'membership',
      minOrder: 0.0,
      discountPercent: null,
      rewardType: 'tiered',
      maxDiscountAmount: null,
      startDate: _now.subtract(const Duration(days: 30)),
      endDate: _now.add(const Duration(days: 180)),
      status: 'ACTIVE',
      autoApply: true,
      stackable: true,
      createdAt: _now.subtract(const Duration(days: 45)),
      updatedAt: _now.subtract(const Duration(days: 5)),
      tiers: [
        PromotionTier(
          promoId: 'PRM_MEMBER',
          tierLevel: 1,
          label: 'Silver',
          minValue: 0.0,
          discountPercent: 5,
          metadata: const {'badge': 'Silver'},
        ),
        PromotionTier(
          promoId: 'PRM_MEMBER',
          tierLevel: 2,
          label: 'Gold',
          minValue: 1000000.0,
          discountPercent: 10,
          freeship: true,
          metadata: const {'badge': 'Gold'},
        ),
        PromotionTier(
          promoId: 'PRM_MEMBER',
          tierLevel: 3,
          label: 'Platinum',
          minValue: 2000000.0,
          discountPercent: 15,
          freeship: true,
          giftProductId: 'P4002',
          giftQuantity: 1,
          metadata: const {'badge': 'Platinum'},
        ),
      ],
    ),
    Promotion(
      promoId: 'PRM_BUNDLE',
      title: 'Combo gia dinh',
      type: 'bundle',
      minOrder: 0.0,
      discountPercent: null,
      rewardType: 'combo',
      maxDiscountAmount: null,
      startDate: _now.subtract(const Duration(days: 10)),
      endDate: _now.add(const Duration(days: 20)),
      status: 'ACTIVE',
      autoApply: true,
      stackable: false,
      createdAt: _now.subtract(const Duration(days: 12)),
      updatedAt: _now.subtract(const Duration(days: 3)),
      tiers: [
        PromotionTier(
          promoId: 'PRM_BUNDLE',
          tierLevel: 1,
          label: 'Combo 3 mon',
          minValue: 0,
          discountAmount: 120000.0,
          comboDescription: 'Chon 3 san pham gia dung bat ky',
        ),
        PromotionTier(
          promoId: 'PRM_BUNDLE',
          tierLevel: 2,
          label: 'Combo 5 mon',
          minValue: 0,
          discountAmount: 220000.0,
          comboDescription: 'Chon 5 san pham gia dung bat ky',
        ),
      ],
    ),
    Promotion(
      promoId: 'PRM_FREESHIP',
      title: 'Freeship moi don tu 500K',
      type: 'shipping',
      minOrder: 500000.0,
      discountPercent: null,
      rewardType: 'freeship',
      maxDiscountAmount: 50000.0,
      startDate: _now.subtract(const Duration(days: 15)),
      endDate: _now.add(const Duration(days: 45)),
      status: 'ACTIVE',
      autoApply: false,
      stackable: true,
      createdAt: _now.subtract(const Duration(days: 20)),
      updatedAt: _now.subtract(const Duration(days: 2)),
      tiers: [
        PromotionTier(
          promoId: 'PRM_FREESHIP',
          tierLevel: 1,
          label: 'Don tu 500K',
          minValue: 500000.0,
          freeship: true,
          metadata: const {'icon': 'local_shipping'},
        ),
      ],
    ),
  ];

  late final List<PromoProduct> _products = [
    PromoProduct(
      productId: 'P1001',
      categoryId: 'electronics',
      name: 'Tai nghe Bluetooth A12',
      price: 1890000,
      stock: 24,
      imageUrl:
          'https://images.unsplash.com/photo-1519677100203-a0e668c92439?auto=format&fit=crop&w=800&q=80',
      status: 'AVAILABLE',
      updatedAt: _now.subtract(const Duration(days: 1)),
      promotions: const [
        PromotionSummary(promoId: 'PRM_FLASH10', title: 'Flash Sale 10%'),
        PromotionSummary(promoId: 'PRM_FREESHIP', title: 'Freeship 0d'),
      ],
    ),
    PromoProduct(
      productId: 'P1002',
      categoryId: 'electronics',
      name: 'Loa thong minh Echo Mini',
      price: 1290000,
      stock: 12,
      imageUrl:
          'https://images.unsplash.com/photo-1518105779142-d975f22f1b0e?auto=format&fit=crop&w=800&q=80',
      status: 'AVAILABLE',
      updatedAt: _now.subtract(const Duration(days: 2)),
      promotions: const [
        PromotionSummary(
          promoId: 'PRM_MEMBER',
          title: 'Thanh vien giam den 15%',
        ),
      ],
    ),
    PromoProduct(
      productId: 'P2001',
      categoryId: 'beauty',
      name: 'Serum duong da Vitamin C',
      price: 325000,
      stock: 56,
      imageUrl:
          'https://images.unsplash.com/photo-1522336572468-97b06e8ef143?auto=format&fit=crop&w=800&q=80',
      status: 'AVAILABLE',
      updatedAt: _now.subtract(const Duration(hours: 12)),
      promotions: const [
        PromotionSummary(promoId: 'PRM_FLASH10', title: 'Flash Sale 10%'),
      ],
    ),
    PromoProduct(
      productId: 'P3001',
      categoryId: 'grocery',
      name: 'Ca phe hat rang moc 250g',
      price: 98000,
      stock: 120,
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80',
      status: 'AVAILABLE',
      updatedAt: _now.subtract(const Duration(days: 4)),
      promotions: const [
        PromotionSummary(promoId: 'PRM_MEMBER', title: 'Tang qua tung bac'),
      ],
    ),
    PromoProduct(
      productId: 'P3002',
      categoryId: 'grocery',
      name: 'Ngu coc granola mix 500g',
      price: 179000,
      stock: 80,
      imageUrl:
          'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?auto=format&fit=crop&w=800&q=80',
      status: 'AVAILABLE',
      updatedAt: _now.subtract(const Duration(days: 5)),
      promotions: const [
        PromotionSummary(promoId: 'PRM_BUNDLE', title: 'Combo gia dinh'),
        PromotionSummary(promoId: 'PRM_FREESHIP', title: 'Freeship 0d'),
      ],
    ),
    PromoProduct(
      productId: 'P4001',
      categoryId: 'bundles',
      name: 'Combo ve sinh nha cua 3 mon',
      price: 259000,
      stock: 45,
      imageUrl:
          'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800&q=80',
      status: 'AVAILABLE',
      promotions: const [
        PromotionSummary(promoId: 'PRM_BUNDLE', title: 'Combo gia dinh'),
      ],
    ),
    PromoProduct(
      productId: 'P4002',
      categoryId: 'bundles',
      name: 'Combo cham soc da 5 buoc',
      price: 759000,
      stock: 30,
      imageUrl:
          'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=800&q=80',
      status: 'AVAILABLE',
      promotions: const [
        PromotionSummary(promoId: 'PRM_MEMBER', title: 'Qua tang Platinum'),
      ],
    ),
  ];

  List<PromoCategory> get _categories => const [
        PromoCategory(id: 'electronics', name: 'Thiet bi so', icon: 'devices'),
        PromoCategory(id: 'beauty', name: 'Lam dep', icon: 'spa'),
        PromoCategory(id: 'grocery', name: 'Thuc pham', icon: 'local_grocery_store'),
        PromoCategory(id: 'bundles', name: 'Combo tiet kiem', icon: 'redeem'),
        PromoCategory(id: 'lifestyle', name: 'Doi song', icon: 'self_improvement'),
      ];
}
