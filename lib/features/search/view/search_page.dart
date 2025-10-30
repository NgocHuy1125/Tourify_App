import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/async_view.dart';
import '../presenter/search_presenter.dart';
import '../../../domain/entities/tour.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchPresenter(context.read())..search(),
      child: Consumer<SearchPresenter>(
        builder: (_, p, __) {
          final s = p.state;
          return Scaffold(
            appBar: AppBar(
              title: TextField(
                decoration: const InputDecoration(
                  hintText: 'Tìm điểm đến / tour...',
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (v) => p.search(q: v),
              ),
            ),
            body: AsyncView(
              loading: s.loading,
              error: s.error,
              child: ListView.separated(
                itemCount: s.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _TourTile(tour: s.items[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TourTile extends StatelessWidget {
  final Tour tour;
  const _TourTile({required this.tour});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(tour.title),
      subtitle: Text('${tour.destination} • ${tour.durationDays}N'),
      trailing: Text('${tour.priceFrom.toStringAsFixed(0)} ₫'),
      onTap: () => context.push('/tour/${tour.id}'),
    );
  }
}
