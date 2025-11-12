class Tour {
  final String id;
  final String title;
  final String destination;
  final int durationDays;
  final num priceFrom;
  final num? priceAfterDiscount;
  final num? ratingAvg;

  num get displayPrice => priceAfterDiscount ?? priceFrom;

  const Tour({
    required this.id,
    required this.title,
    required this.destination,
    required this.durationDays,
    required this.priceFrom,
    this.priceAfterDiscount,
    this.ratingAvg,
  });
}
