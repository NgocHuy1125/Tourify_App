// lib/features/home/view/widgets/suggestion_tab_section.dart
import 'package:flutter/material.dart';
import 'package:tourify_app/features/home/presenter/home_presenter.dart';
import 'package:tourify_app/features/home/view/all_tours_screen.dart';
import 'package:tourify_app/features/home/view/widgets/tour_card_large.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/tour/view/tour_detail_page.dart';

class SuggestionTabSection extends StatelessWidget {
  final HomePresenter presenter;
  const SuggestionTabSection({super.key, required this.presenter});

  @override
  Widget build(BuildContext context) {
    final trending =
        presenter.trendingTours.isNotEmpty
            ? presenter.trendingTours
            : presenter.tours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Đề xuất dành cho bạn',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        _buildContent(context, trending),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AllToursScreen()),
              );
            },
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('Xem tất cả tour'),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, List<TourSummary> tours) {
    final state = presenter.state;

    if (state == HomeState.loading && tours.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state == HomeState.error && tours.isEmpty) {
      final message =
          presenter.errorMessage.isNotEmpty
              ? presenter.errorMessage
              : 'Không thể tải dữ liệu tour. Vui lòng thử lại.';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (tours.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: Text(
            'Chưa có tour nào được hiển thị.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 320,
      ),
      itemCount: tours.length,
      itemBuilder: (context, index) {
        final tour = tours[index];
        return TourCardLarge(
          tour: tour,
          onTap: () => _openDetail(context, tour),
        );
      },
    );
  }

  void _openDetail(BuildContext context, TourSummary tour) {
    if (tour.id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TourDetailPage(id: tour.id)),
    );
  }
}
