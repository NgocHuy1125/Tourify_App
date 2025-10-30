import 'package:flutter/foundation.dart';

/// Core data objects that mirror the Cassandra tables used by the promo_shop keyspace.
/// These models are intentionally light-weight so the UI can be driven without a backend.

@immutable
class PromoCategory {
  final String id;
  final String name;
  final String icon;

  const PromoCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

@immutable
class PromotionSummary {
  final String promoId;
  final String title;
  final DateTime? endDate;

  const PromotionSummary({
    required this.promoId,
    required this.title,
    this.endDate,
  });
}

@immutable
class PromoProduct {
  final String productId;
  final String categoryId;
  final String name;
  final double price;
  final int stock;
  final String imageUrl;
  final String status;
  final DateTime? updatedAt;
  final List<PromotionSummary> promotions;

  const PromoProduct({
    required this.productId,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.status,
    this.updatedAt,
    this.promotions = const [],
  });
}

@immutable
class Promotion {
  final String promoId;
  final String title;
  final String type;
  final double? minOrder;
  final int? discountPercent;
  final String rewardType;
  final double? maxDiscountAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool autoApply;
  final bool stackable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? badge;
  final List<PromotionTier> tiers;

  const Promotion({
    required this.promoId,
    required this.title,
    required this.type,
    this.minOrder,
    this.discountPercent,
    required this.rewardType,
    this.maxDiscountAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.autoApply,
    required this.stackable,
    required this.createdAt,
    required this.updatedAt,
    this.badge,
    this.tiers = const [],
  });
}

@immutable
class PromotionTier {
  final String promoId;
  final int tierLevel;
  final String label;
  final double minValue;
  final int? discountPercent;
  final double? discountAmount;
  final bool freeship;
  final String? giftProductId;
  final int? giftQuantity;
  final String? comboDescription;
  final Map<String, dynamic>? metadata;

  const PromotionTier({
    required this.promoId,
    required this.tierLevel,
    required this.label,
    required this.minValue,
    this.discountPercent,
    this.discountAmount,
    this.freeship = false,
    this.giftProductId,
    this.giftQuantity,
    this.comboDescription,
    this.metadata,
  });
}

@immutable
class PromoCartItem {
  final PromoProduct product;
  final int quantity;
  final double price;
  final PromotionSummary? appliedPromotion;

  const PromoCartItem({
    required this.product,
    required this.quantity,
    required this.price,
    this.appliedPromotion,
  });

  double get lineSubtotal => price * quantity;
}

@immutable
class PromoCartTotals {
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double finalAmount;
  final PromotionSummary? bestPromotion;

  const PromoCartTotals({
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
    required this.finalAmount,
    this.bestPromotion,
  });
}

@immutable
class PromoCart {
  final List<PromoCartItem> items;
  final PromoCartTotals totals;

  const PromoCart({required this.items, required this.totals});
}

@immutable
class PromoHomeData {
  final List<Promotion> spotlightPromotions;
  final List<PromoProduct> featuredProducts;
  final List<PromoProduct> trendingCombos;
  final List<PromoCategory> categories;

  const PromoHomeData({
    this.spotlightPromotions = const [],
    this.featuredProducts = const [],
    this.trendingCombos = const [],
    this.categories = const [],
  });
}
