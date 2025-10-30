import 'package:flutter/material.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/tour/view/widgets/tour_card.dart';
import 'section_header.dart';

class TourCarousel extends StatelessWidget {
  final String title;
  final List<TourSummary> tours;

  const TourCarousel({super.key, required this.title, required this.tours});

  @override
  Widget build(BuildContext context) {
    if (tours.isEmpty) {
      // Không hiển thị gì nếu không có dữ liệu
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Sử dụng SectionHeader để có tiêu đề và nút "Xem thêm"
        SectionHeader(
          title: title,
          onSeeMore: () {
            print('Tapped See more for $title');
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170, // Chiều cao phù hợp cho TourCard nhỏ
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: tours.length,
            itemBuilder: (context, index) {
              return TourCard(tour: tours[index]);
            },
          ),
        ),
      ],
    );
  }
}
