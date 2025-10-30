class Tour {
  final String id;
  final String title;
  final String destination;
  final int durationDays;
  final num priceFrom;
  final num? ratingAvg;

  const Tour({
    required this.id,
    required this.title,
    required this.destination,
    required this.durationDays,
    required this.priceFrom,
    this.ratingAvg,
  });
}
