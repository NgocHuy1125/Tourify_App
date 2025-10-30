const _tourBaseHost = 'https://travel-backend-heov.onrender.com';

String? _normalizeMediaUrl(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  if (str.startsWith('http')) return str;
  if (str.startsWith('//')) return 'https:$str';

  final base = Uri.parse(_tourBaseHost.endsWith('/')
      ? _tourBaseHost
      : '$_tourBaseHost/');
  final resolved = base.resolve(str.startsWith('/') ? str.substring(1) : str);
  return resolved.toString();
}

class TourSummary {
  final String id;
  final String title;
  final String destination;
  final int duration;
  final double priceFrom;
  final double? ratingAvg;
  final int reviewsCount;
  final String? mediaCover;
  final List<String> tags;
  final int? bookingsCount;

  TourSummary({
    required this.id,
    required this.title,
    required this.destination,
    required this.duration,
    required this.priceFrom,
    this.ratingAvg,
    this.reviewsCount = 0,
    this.mediaCover,
    this.tags = const [],
    this.bookingsCount,
  });

  factory TourSummary.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    String? cover;
    final media = map['media'];
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map) {
        final firstMap = Map<String, dynamic>.from(first);
        cover =
            (firstMap['url'] ?? firstMap['src'] ?? firstMap['path'])
                ?.toString();
      } else if (first is String) {
        cover = first;
      }
    }
    cover ??=
        (map['thumbnail_url'] ??
                map['thumbnail'] ??
                map['image'] ??
                map['cover'])
            ?.toString();

    cover = _normalizeMediaUrl(cover);

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final ratingCandidate =
        map['rating_avg'] ?? map['rating_average'] ?? map['average_rating'];
    final reviewsCandidate =
        map['reviews_count'] ?? map['rating_count'] ?? map['review_count'];

    return TourSummary(
      id: (map['id'] ?? map['uuid'] ?? map['slug'] ?? '').toString(),
      title: (map['title'] ?? map['name'] ?? 'Tour').toString(),
      destination:
          (map['destination'] ?? map['location'] ?? map['city'] ?? '')
              .toString(),
      duration: parseInt(map['duration'] ?? map['duration_days'] ?? 0),
      priceFrom: parseDouble(
        map['priceFrom'] ?? map['base_price'] ?? map['season_price'] ?? 0,
      ),
      mediaCover: cover ?? 'https://via.placeholder.com/400x300?text=Tour',
      ratingAvg: ratingCandidate != null ? parseDouble(ratingCandidate) : null,
      reviewsCount: parseInt(reviewsCandidate),
      tags:
          (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      bookingsCount:
          map['bookings_count'] != null
              ? parseInt(map['bookings_count'])
              : null,
    );
  }
}

class TourSchedule {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int seatsTotal;
  final int seatsAvailable;
  final double? seasonPrice;

  TourSchedule({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.seatsTotal,
    required this.seatsAvailable,
    this.seasonPrice,
  });

  factory TourSchedule.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return TourSchedule(
      id: json['id']?.toString() ?? '',
      startDate: parseDate(json['start_date'] ?? json['startDate']),
      endDate: parseDate(json['end_date'] ?? json['endDate']),
      seatsTotal: parseInt(json['seats_total'] ?? json['seatsTotal']),
      seatsAvailable: parseInt(
        json['seats_available'] ?? json['seatsAvailable'],
      ),
      seasonPrice: parseDouble(json['season_price'] ?? json['seasonPrice']),
    );
  }
}

class ReviewItem {
  final String id;
  final String userId;
  final String userName;
  final String comment;
  final int rating;
  final DateTime createdAt;

  ReviewItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
    id: json['id']?.toString() ?? '',
    userId:
        json['user'] is Map
            ? json['user']['id']?.toString() ?? ''
            : json['user'][' id']?.toString() ?? '',
    userName:
        json['user'] is Map
            ? json['user']['name']?.toString() ?? ''
            : json['user']['name']?.toString() ?? '',
    comment: json['comment']?.toString() ?? '',
    rating: (json['rating'] as num? ?? 0).toInt(),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
  );
}

class TourDetail {
  final String id;
  final String title;
  final String description;
  final String destination;
  final String policy;
  final int duration;
  final double basePrice;
  final List<String> media;
  final List<String> tags;
  final List<dynamic> itinerary;
  final double? ratingAvg;
  final int reviewsCount;
  final int? bookingsCount;
  final List<TourSchedule> schedules;
  final List<ReviewItem> reviews;
  final List<TourPackage> packages;

  TourDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.destination,
    required this.policy,
    required this.duration,
    required this.basePrice,
    required this.media,
    required this.tags,
    required this.itinerary,
    this.ratingAvg,
    this.reviewsCount = 0,
    this.bookingsCount,
    this.schedules = const [],
    this.reviews = const [],
    this.packages = const [],
  });

  factory TourDetail.fromJson(Map<String, dynamic> json) {
    final tags =
        (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    final mediaSet = <String>{};
    void addMedia(dynamic value) {
      final url = _normalizeMediaUrl(value);
      if (url != null) mediaSet.add(url);
    }

    addMedia(json['thumbnail_url']);
    addMedia(json['thumbnail']);
    addMedia(json['image']);
    addMedia(json['cover']);
    if (json['media'] is List) {
      for (final item in json['media']) {
        addMedia(item);
      }
    }
    if (json['gallery'] is List) {
      for (final item in json['gallery']) {
        addMedia(item);
      }
    }
    final media =
        mediaSet.isEmpty
            ? ['https://via.placeholder.com/500x320?text=Tour']
            : mediaSet.toList();

    final rawItinerary = json['itinerary'];
    List<dynamic> itinerary = const [];
    if (rawItinerary is List) {
      itinerary = rawItinerary;
    } else if (rawItinerary is Map) {
      itinerary =
          rawItinerary.entries
              .map(
                (entry) => {
                  'title': entry.key.toString(),
                  'description': entry.value?.toString() ?? '',
                },
              )
              .toList();
    } else if (rawItinerary != null) {
      itinerary = [rawItinerary.toString()];
    }

    double? ratingAverage;
    final ratingSource =
        json['rating_avg'] ?? json['rating_average'] ?? json['average_rating'];
    if (ratingSource is num) {
      ratingAverage = ratingSource.toDouble();
    } else if (ratingSource != null) {
      ratingAverage = double.tryParse(ratingSource.toString());
    }

    final reviewsSource =
        json['reviews_count'] ?? json['rating_count'] ?? json['review_count'];
    final bookingsSource = json['bookings_count'] ?? json['bookings'];

    return TourDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      policy: json['policy']?.toString() ?? '',
      duration: (json['duration'] as num? ?? 0).toInt(),
      basePrice: (json['base_price'] as num? ?? 0).toDouble(),
      media: media,
      tags: tags,
      itinerary: itinerary,
      ratingAvg: ratingAverage,
      reviewsCount:
          reviewsSource is num
              ? reviewsSource.toInt()
              : int.tryParse(reviewsSource?.toString() ?? '') ?? 0,
      bookingsCount:
          bookingsSource is num
              ? bookingsSource.toInt()
              : int.tryParse(bookingsSource?.toString() ?? ''),
      schedules:
          (json['schedules'] as List?)
              ?.whereType<Map>()
              .map(
                (e) => TourSchedule.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          const [],
      reviews:
          (json['reviews'] as List?)
              ?.whereType<Map>()
              .map(
                (e) => ReviewItem.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          const [],
      packages:
          (json['packages'] as List?)
              ?.whereType<Map>()
              .map(
                (e) => TourPackage.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          const [],
    );
  }
}

class TourPackage {
  final String id;
  final String name;
  final String description;
  final double adultPrice;
  final double? childPrice;
  final bool isActive;

  TourPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.adultPrice,
    this.childPrice,
    this.isActive = true,
  });

  factory TourPackage.fromJson(Map<String, dynamic> json) {
    return TourPackage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Gói dịch vụ',
      description: json['description']?.toString() ?? '',
      adultPrice: (json['adult_price'] as num? ?? 0).toDouble(),
      childPrice: (json['child_price'] as num?)?.toDouble(),
      isActive: json['is_active'] == null ? true : json['is_active'] == true,
    );
  }
}

class TourReview {
  final String id;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final String userName;
  final String? scheduleText;

  TourReview({
    required this.id,
    required this.rating,
    required this.comment,
    this.createdAt,
    required this.userName,
    this.scheduleText,
  });

  factory TourReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map?;
    final schedule = json['tour_schedule'] as Map?;
    return TourReview(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as num? ?? 0).toInt(),
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      userName: user?['name']?.toString() ?? 'Người dùng ẩn danh',
      scheduleText: schedule?['start_date']?.toString(),
    );
  }
}

class TourReviewsResponse {
  final List<TourReview> reviews;
  final double average;
  final int count;

  TourReviewsResponse({
    required this.reviews,
    required this.average,
    required this.count,
  });
}
