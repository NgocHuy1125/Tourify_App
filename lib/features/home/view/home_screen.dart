import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'package:tourify_app/features/home/presenter/home_presenter.dart';
import 'package:tourify_app/features/notifications/presenter/notification_presenter.dart';

import 'widgets/category_section.dart';
import 'widgets/destination_carousel.dart';
import 'widgets/chatbot_launcher.dart';
import 'widgets/personalized_recommendation_section.dart';
import 'widgets/promotions_section.dart';
import 'widgets/recent_tours_section.dart';
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
      final auth = context.read<AuthNotifier>();
      if (auth.isLoggedIn) {
        context.read<NotificationPresenter>().refreshUnreadCount();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<HomePresenter>();

    final content = RefreshIndicator(
      onRefresh: presenter.fetchHome,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategorySection(
              categories: presenter.categories,
              isLoading: presenter.state == HomeState.loading,
            ),
            PromotionsSection(promotions: presenter.promotions),
            const SizedBox(height: 16),
            DestinationCarousel(
              title: 'Bạn muốn đi đâu chơi?',
              destinations: presenter.destinations,
              isLoading: presenter.state == HomeState.loading,
            ),
            const SizedBox(height: 24),
            RecentToursSection(
              items: presenter.recentTours,
              isLoading: presenter.recentToursLoading,
              message: presenter.recentToursMessage,
            ),
            const SizedBox(height: 24),
            SuggestionTabSection(presenter: presenter),
            const SizedBox(height: 24),
            PersonalizedRecommendationSection(presenter: presenter),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        const Positioned(
          right: 16,
          bottom: 16,
          child: ChatbotLauncher(),
        ),
      ],
    );
  }
}
