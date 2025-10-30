import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/features/home/presenter/home_presenter.dart';

import 'widgets/category_section.dart';
import 'widgets/destination_carousel.dart';
import 'widgets/promotions_section.dart';
import 'widgets/suggestion_tab_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final presenter = context.read<HomePresenter>();
      if (presenter.tours.isEmpty) {
        presenter.fetchHome();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<HomePresenter>();

    return RefreshIndicator(
      onRefresh: presenter.fetchHome,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CategorySection(),
            PromotionsSection(promotions: presenter.promotions),
            const SizedBox(height: 16),
            const DestinationCarousel(title: 'Bạn muốn đi đâu chơi?'),
            const SizedBox(height: 24),
            SuggestionTabSection(presenter: presenter),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
