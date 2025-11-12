import 'package:tourify_app/features/tour/model/tour_model.dart';

class CategoryItem {
  final String id;
  final String name;
  final String? slug;
  final String? imageUrl;
  final String? coverImage;

  const CategoryItem({
    required this.id,
    required this.name,
    this.slug,
    this.imageUrl,
    this.coverImage,
  });

  CategoryItem copyWith({String? imageUrl, String? coverImage}) {
    return CategoryItem(
      id: id,
      name: name,
      slug: slug,
      imageUrl: imageUrl ?? this.imageUrl,
      coverImage: coverImage ?? this.coverImage,
    );
  }

  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
    id: j['id']?.toString() ?? '',
    name: j['name'] ?? '',
    slug: j['slug']?.toString(),
    imageUrl: j['image']?.toString(),
    coverImage: j['cover_image']?.toString() ?? j['coverImage']?.toString(),
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
    value:
        j['value'] is num
            ? (j['value'] as num).toDouble()
            : (j['value'] is String ? (double.tryParse(j['value']) ?? 0) : 0),
    isActive: j['is_active'] == true || j['is_active'] == 1,
    validFrom:
        j['valid_from'] != null
            ? DateTime.tryParse(j['valid_from'].toString())
            : null,
    validTo:
        j['valid_to'] != null
            ? DateTime.tryParse(j['valid_to'].toString())
            : null,
  );
}

class RecentTourItem {
  final TourSummary tour;
  final DateTime? viewedAt;
  final int viewCount;

  const RecentTourItem({
    required this.tour,
    this.viewedAt,
    this.viewCount = 0,
  });

  RecentTourItem copyWith({
    TourSummary? tour,
    DateTime? viewedAt,
    int? viewCount,
  }) {
    return RecentTourItem(
      tour: tour ?? this.tour,
      viewedAt: viewedAt ?? this.viewedAt,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  factory RecentTourItem.fromSummary(
    TourSummary summary, {
    DateTime? viewedAt,
    int viewCount = 1,
  }) {
    return RecentTourItem(
      tour: summary,
      viewedAt: viewedAt,
      viewCount: viewCount,
    );
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'viewed_at': viewedAt?.toIso8601String(),
      'view_count': viewCount,
      'tour': {
        'id': tour.id,
        'title': tour.title,
        'destination': tour.destination,
        'duration': tour.duration,
      'priceFrom': tour.priceFrom,
      'base_price': tour.priceFrom,
      'price_after_discount': tour.priceAfterDiscount,
        'rating_avg': tour.ratingAvg,
        'reviews_count': tour.reviewsCount,
        'media': tour.mediaCover != null ? [tour.mediaCover] : const [],
        'thumbnail_url': tour.mediaCover,
        'bookings_count': tour.bookingsCount,
        'tags': tour.tags,
        'type': tour.type,
        'child_age_limit': tour.childAgeLimit,
        'requires_passport': tour.requiresPassport,
        'requires_visa': tour.requiresVisa,
      },
    };
  }

  factory RecentTourItem.fromStorageJson(Map<String, dynamic> json) {
    final tourData = json['tour'];
    if (tourData is! Map) {
      throw const FormatException('Invalid tour data');
    }
    final viewedAt = json['viewed_at']?.toString();
    final viewCount = json['view_count'];
    return RecentTourItem(
      tour: TourSummary.fromJson(Map<String, dynamic>.from(tourData)),
      viewedAt:
          viewedAt == null || viewedAt.isEmpty
              ? null
              : DateTime.tryParse(viewedAt),
      viewCount:
          viewCount is num
              ? viewCount.toInt()
              : int.tryParse(viewCount?.toString() ?? '') ?? 0,
    );
  }
}

class RecommendationItem {
  RecommendationItem({
    required this.tourId,
    required this.score,
    required this.reasons,
    required this.tour,
  });

  final String tourId;
  final double score;
  final List<String> reasons;
  final TourSummary tour;

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    final reasons =
        (json['reasons'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final score =
        json['score'] is num
            ? (json['score'] as num).toDouble()
            : double.tryParse(json['score']?.toString() ?? '') ?? 0;

    Map<String, dynamic> tourMap = {};
    if (json['tour'] is Map) {
      tourMap = Map<String, dynamic>.from(json['tour'] as Map);
    }
    final resolvedId =
        (tourMap['id'] ?? json['tour_id'] ?? json['id'] ?? '').toString();
    if (resolvedId.isNotEmpty) tourMap['id'] = resolvedId;
    tourMap.putIfAbsent('title', () => json['title'] ?? 'Tour gợi ý');
    tourMap.putIfAbsent('destination', () => json['destination'] ?? '');
    if (!tourMap.containsKey('duration') && json['duration'] != null) {
      tourMap['duration'] = json['duration'];
    }
    if (!tourMap.containsKey('base_price') && json['base_price'] != null) {
      tourMap['base_price'] = json['base_price'];
    }
    if (!tourMap.containsKey('media') && json['media'] is List) {
      tourMap['media'] = json['media'];
    }

    final summary = TourSummary.fromJson(tourMap);

    return RecommendationItem(
      tourId: summary.id,
      score: score,
      reasons: reasons,
      tour: summary,
    );
  }

  List<String> reasonBadges({int limit = 2}) {
    final badges = <String>[];
    for (final reason in reasons) {
      final label = _mapReason(reason);
      if (label != null && !badges.contains(label)) {
        badges.add(label);
      }
      if (badges.length >= limit) break;
    }
    return badges;
  }

  static String? _mapReason(String raw) {
    if (raw.isEmpty) return null;
    final normalized = raw.toLowerCase();
    if (normalized.contains('ml_collaborative_filtering')) {
      return 'Dựa trên các tour bạn đã lựa chọn';
    }
    if (normalized.contains('content_match')) {
      return 'Nội dung tương đồng với tour bạn từng thích';
    }
    if (normalized.contains('popular')) {
      return 'Được nhiều người đặt';
    }
    if (normalized.contains('shared_tag')) {
      return 'Chung chủ đề';
    }
    if (normalized.contains('same_destination')) {
      return 'Cùng điểm đến';
    }
    if (normalized.contains('same_type')) {
      return 'Cùng loại hình';
    }
    return null;
  }
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
    categories:
        (j['categories'] as List?)
            ?.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    promotions:
        (j['promotions'] as List?)
            ?.map((e) => PromotionItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    rawTrending: (j['trending'] as List?) ?? const [],
  );
}

class DestinationHighlight {
  final String name;
  final String imageUrl;

  const DestinationHighlight({required this.name, required this.imageUrl});
}

class ChatbotSource {
  const ChatbotSource({
    required this.title,
    this.url,
    this.type,
    this.snippet,
  });

  final String title;
  final String? url;
  final String? type;
  final String? snippet;

  factory ChatbotSource.fromJson(Map<String, dynamic> json) {
    String resolve(dynamic value) {
      if (value == null) return '';
      final text = value.toString().trim();
      return text;
    }

    final resolvedTitle = [
      resolve(json['title']),
      resolve(json['name']),
      resolve(json['code']),
      resolve(json['type']),
    ].firstWhere((value) => value.isNotEmpty, orElse: () => 'Nguồn tham khảo');

    return ChatbotSource(
      title: resolvedTitle,
      url: resolve(json['url']).isEmpty ? null : resolve(json['url']),
      type: resolve(json['type']).isEmpty ? null : resolve(json['type']),
      snippet: resolve(json['snippet']).isEmpty ? null : resolve(json['snippet']),
    );
  }
}

class ChatbotReply {
  ChatbotReply({
    required this.reply,
    required this.language,
    List<ChatbotSource> sources = const [],
  }) : sources = List.unmodifiable(sources);

  final String reply;
  final String language;
  final List<ChatbotSource> sources;

  factory ChatbotReply.fromJson(Map<String, dynamic> json) {
    final replyText =
        json['reply']?.toString() ??
        json['response']?.toString() ??
        json['message']?.toString() ??
        '';
    final language = json['language']?.toString() ?? 'vi';
    final rawSources = json['sources'];
    final sources =
        (rawSources is List)
            ? rawSources
                .whereType<Map>()
                .map((item) => ChatbotSource.fromJson(
                      Map<String, dynamic>.from(item),
                    ))
                .toList()
            : const <ChatbotSource>[];

    return ChatbotReply(
      reply: replyText,
      language: language,
      sources: sources,
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.createdAt,
    List<ChatbotSource> sources = const [],
  }) : sources = List.unmodifiable(sources);

  final String id;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final List<ChatbotSource> sources;

  factory ChatMessage.user(String content) {
    final now = DateTime.now();
    return ChatMessage(
      id: 'user_${now.microsecondsSinceEpoch}',
      content: content,
      isUser: true,
      createdAt: now,
    );
  }

  factory ChatMessage.bot(
    String content, {
    List<ChatbotSource> sources = const [],
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: 'bot_${now.microsecondsSinceEpoch}',
      content: content,
      isUser: false,
      createdAt: now,
      sources: sources,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? createdAt,
    List<ChatbotSource>? sources,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      sources: sources ?? this.sources,
    );
  }
}
