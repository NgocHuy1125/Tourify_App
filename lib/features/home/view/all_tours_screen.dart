import 'package:flutter/material.dart';
import 'package:tourify_app/features/home/model/home_repository.dart';
import 'package:tourify_app/features/home/view/widgets/tour_card_large.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/tour/view/tour_detail_page.dart';

class AllToursScreen extends StatefulWidget {
  const AllToursScreen({super.key});

  @override
  State<AllToursScreen> createState() => _AllToursScreenState();
}

class _AllToursScreenState extends State<AllToursScreen> {
  final HomeRepository _repository = HomeRepositoryImpl();
  late Future<List<TourSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchAllTours(limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tất cả tour')),
      body: FutureBuilder<List<TourSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Không thể tải danh sách tour.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final tours = snapshot.data ?? [];
          if (tours.isEmpty) {
            return const Center(child: Text('Chưa có tour nào.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
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
                onTap: () {
                  if (tour.id.isEmpty) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TourDetailPage(id: tour.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
