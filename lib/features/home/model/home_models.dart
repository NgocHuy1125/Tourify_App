class CategoryItem {
  final String id;
  final String name;
  final String? slug;
  final String? imageUrl;

  CategoryItem({
    required this.id,
    required this.name,
    this.slug,
    this.imageUrl,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? '',
        slug: j['slug']?.toString(),
        imageUrl: j['image']?.toString(),
      );
}

class PromotionItem {
  final String id;
  final String code;
  final String discountType; // percent | fixed
  final double value;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool isActive;

  PromotionItem({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    required this.isActive,
    this.validFrom,
    this.validTo,
  });

  factory PromotionItem.fromJson(Map<String, dynamic> j) => PromotionItem(
        id: j['id']?.toString() ?? '',
        code: j['code']?.toString() ?? '',
        discountType: j['discount_type']?.toString() ?? 'percent',
        value: j['value'] is num
            ? (j['value'] as num).toDouble()
            : (j['value'] is String
                ? (double.tryParse(j['value']) ?? 0)
                : 0),
        isActive: j['is_active'] == true || j['is_active'] == 1,
        validFrom: j['valid_from'] != null ? DateTime.tryParse(j['valid_from'].toString()) : null,
        validTo: j['valid_to'] != null ? DateTime.tryParse(j['valid_to'].toString()) : null,
      );
}

class HomePayload {
  final List<CategoryItem> categories;
  final List<PromotionItem> promotions;
  final List<dynamic> rawTrending; // keep raw to be flexible

  HomePayload({
    this.categories = const [],
    this.promotions = const [],
    this.rawTrending = const [],
  });

  factory HomePayload.fromJson(Map<String, dynamic> j) => HomePayload(
        categories: (j['categories'] as List?)
                ?.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        promotions: (j['promotions'] as List?)
                ?.map((e) => PromotionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        rawTrending: (j['trending'] as List?) ?? const [],
      );
}
