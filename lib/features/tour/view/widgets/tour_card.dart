import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class TourCard extends StatelessWidget {
  final TourSummary tour;
  const TourCard({super.key, required this.tour});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final priceText =
        tour.priceFrom > 0
            ? formatter.format(tour.priceFrom)
            : 'Giá đang cập nhật';

    return GestureDetector(
      onTap: () {
        print('Tapped on tour: ${tour.title}');
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),

        child: Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 3,
                child: Image.network(
                  tour.mediaCover ??
                      'https://via.placeholder.com/150x100.png?text=Tourify',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),

              // Cho phép phần text chiếm phần không gian còn lại
              Flexible(
                flex: 2, // Chiếm 2 phần không gian
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    tour.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Text(
                  priceText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFFFF5B00),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
