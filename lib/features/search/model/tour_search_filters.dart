import 'package:intl/intl.dart';

enum TourSortOption {
  recommended(''),
  priceLow('price_low'),
  priceHigh('price_high'),
  popular('popular'),
  mostBooked('most_booked'),
  rating('rating'),
  newest('newest');

  const TourSortOption(this.value);
  final String value;

  String get label {
    switch (this) {
      case TourSortOption.recommended:
        return 'Gợi ý';
      case TourSortOption.priceLow:
        return 'Giá thấp';
      case TourSortOption.priceHigh:
        return 'Giá cao';
      case TourSortOption.popular:
        return 'Phổ biến';
      case TourSortOption.mostBooked:
        return 'Đặt nhiều';
      case TourSortOption.rating:
        return 'Đánh giá cao';
      case TourSortOption.newest:
        return 'Mới nhất';
    }
  }

  static TourSortOption fromValue(String? raw) {
    final value = (raw ?? '').toLowerCase();
    switch (value) {
      case 'price':
      case 'price_low':
        return TourSortOption.priceLow;
      case 'price_high':
        return TourSortOption.priceHigh;
      case 'booked':
      case 'most_booked':
      case 'popular':
        return TourSortOption.mostBooked;
      case 'rating':
      case 'top_rated':
        return TourSortOption.rating;
      case 'newest':
      case 'recent':
        return TourSortOption.newest;
      default:
        return TourSortOption.recommended;
    }
  }
}

enum DepartureQuickFilter { any, today, tomorrow }

class TourSearchFilters {
  TourSearchFilters({
    this.keyword,
    List<String>? destinations,
    this.departure = DepartureQuickFilter.any,
    this.departureDate,
    this.startDate,
    this.priceMin,
    this.priceMax,
    this.durationMin,
    this.durationMax,
    this.sort = TourSortOption.recommended,
    this.statsDays,
    this.perPage = 20,
  }) : destinations = destinations ?? const [];

  final String? keyword;
  final List<String> destinations;
  final DepartureQuickFilter departure;
  final DateTime? departureDate;
  final DateTime? startDate;
  final double? priceMin;
  final double? priceMax;
  final int? durationMin;
  final int? durationMax;
  final TourSortOption sort;
  final int? statsDays;
  final int perPage;

  TourSearchFilters copyWith({
    String? keyword,
    List<String>? destinations,
    DepartureQuickFilter? departure,
    DateTime? departureDate,
    DateTime? startDate,
    double? priceMin,
    double? priceMax,
    int? durationMin,
    int? durationMax,
    TourSortOption? sort,
    int? statsDays,
    int? perPage,
  }) {
    return TourSearchFilters(
      keyword: keyword ?? this.keyword,
      destinations: destinations ?? this.destinations,
      departure: departure ?? this.departure,
      departureDate: departureDate ?? this.departureDate,
      startDate: startDate ?? this.startDate,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      durationMin: durationMin ?? this.durationMin,
      durationMax: durationMax ?? this.durationMax,
      sort: sort ?? this.sort,
      statsDays: statsDays ?? this.statsDays,
      perPage: perPage ?? this.perPage,
    );
  }

  String buildQueryString() {
    final formatter = DateFormat('yyyy-MM-dd');
    final entries = <MapEntry<String, String>>[];

    final trimmedKeyword = keyword?.trim();
    if (trimmedKeyword != null && trimmedKeyword.isNotEmpty) {
      entries.add(MapEntry('search', trimmedKeyword));
    }

    final uniqueDestinations = destinations
        .map((e) => e.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    for (final destination in uniqueDestinations) {
      entries.add(MapEntry('destinations[]', destination));
    }
    if (uniqueDestinations.length == 1) {
      entries.add(MapEntry('destination', uniqueDestinations.first));
    }

    if (departure == DepartureQuickFilter.today) {
      entries.add(const MapEntry('departure', 'today'));
    } else if (departure == DepartureQuickFilter.tomorrow) {
      entries.add(const MapEntry('departure', 'tomorrow'));
    }

    if (departureDate != null) {
      entries.add(MapEntry('departure_date', formatter.format(departureDate!)));
    }

    if (startDate != null) {
      entries.add(MapEntry('start_date', formatter.format(startDate!)));
    }

    if (priceMin != null) {
      entries.add(MapEntry('price_min', priceMin!.round().toString()));
    }
    if (priceMax != null) {
      entries.add(MapEntry('price_max', priceMax!.round().toString()));
    }
    if (durationMin != null) {
      entries.add(MapEntry('duration_min', durationMin!.toString()));
    }
    if (durationMax != null) {
      entries.add(MapEntry('duration_max', durationMax!.toString()));
    }

    final sortValue = sort.value;
    if (sortValue.isNotEmpty) {
      entries.add(MapEntry('sort', sortValue));
    }

    if (statsDays != null && statsDays! > 0) {
      entries.add(MapEntry('stats_days', statsDays!.toString()));
    }

    if (perPage > 0) {
      entries.add(MapEntry('per_page', perPage.toString()));
    }

    if (entries.isEmpty) return '';
    final query = entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    return '?$query';
  }
}
