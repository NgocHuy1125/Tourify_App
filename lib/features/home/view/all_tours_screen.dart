import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/features/home/model/home_models.dart';
import 'package:tourify_app/features/home/model/home_repository.dart';
import 'package:tourify_app/features/home/presenter/home_presenter.dart';
import 'package:tourify_app/features/home/view/widgets/tour_card_large.dart';
import 'package:tourify_app/features/search/model/tour_search_filters.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/tour/view/tour_detail_page.dart';

class AllToursScreen extends StatefulWidget {
  const AllToursScreen({super.key, this.category, this.destination});

  final CategoryItem? category;
  final String? destination;

  @override
  State<AllToursScreen> createState() => _AllToursScreenState();
}

class _AllToursScreenState extends State<AllToursScreen> {
  final HomeRepository _repository = HomeRepositoryImpl();
  late Future<List<TourSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadTours();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadTours();
    });
    await _future;
  }

  Future<List<TourSummary>> _loadTours() {
    final destination = widget.destination?.trim();
    if (destination != null && destination.isNotEmpty) {
      return _repository.searchTours(
        TourSearchFilters(destinations: [destination], perPage: 100),
      );
    }
    final category = widget.category;
    if (category != null) {
      final tagKeyword =
          (category.slug?.trim().isNotEmpty == true
                  ? category.slug!
                  : category.name)
              .trim()
              .toLowerCase();
      return _repository.fetchAllTours(limit: 200).then((tours) {
        if (tagKeyword.isEmpty) return tours;
        final filtered =
            tours.where((tour) {
              final tags = tour.tags.map((t) => t.toLowerCase()).toList();
              final inTags = tags.any((t) => t.contains(tagKeyword));
              final inText =
                  tour.title.toLowerCase().contains(tagKeyword) ||
                  tour.destination.toLowerCase().contains(tagKeyword);
              return inTags || inText;
            }).toList();
        return filtered.isNotEmpty ? filtered : tours;
      });
    }
    return _repository.fetchAllTours(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle())),
      body: FutureBuilder<List<TourSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorMessage(
              message: 'Không thể tải danh sách tour.\n${snapshot.error ?? ''}',
              onRetry: _reload,
            );
          }

          final tours = snapshot.data ?? [];
          if (tours.isEmpty) {
            return const _EmptyMessage(
              message: 'Chưa có tour nào được hiển thị.',
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 360,
              ),
              itemCount: tours.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final tour = tours[index];
                return TourCardLarge(
                  tour: tour,
                  onTap: () async {
                    if (tour.id.isEmpty) return;
                    final presenter = context.read<HomePresenter>();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TourDetailPage(id: tour.id),
                      ),
                    );
                    await presenter.refreshRecentTours();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _appBarTitle() {
    final destination = widget.destination?.trim();
    if (destination != null && destination.isNotEmpty) {
      return 'Tour tại $destination';
    }
    final category = widget.category;
    if (category != null && category.name.isNotEmpty) {
      return 'Tour theo: ${category.name}';
    }

    return 'Tất cả tour';
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),

            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
