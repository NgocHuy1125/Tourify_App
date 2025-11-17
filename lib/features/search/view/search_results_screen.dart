import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/features/home/model/home_repository.dart';
import 'package:tourify_app/features/home/presenter/home_presenter.dart';
import 'package:tourify_app/features/search/model/tour_search_filters.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';
import 'package:tourify_app/features/tour/view/tour_detail_page.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, this.initialKeyword = ''});

  final String initialKeyword;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TourSearchFilters _filters;
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  List<TourSummary> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _filters = TourSearchFilters(
      keyword: widget.initialKeyword,
      perPage: 30,
    );
    _searchController.text = widget.initialKeyword;
    _loadTours();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTours() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<HomeRepository>();
      final data = await repo.searchTours(_filters);
      if (!mounted) return;
      setState(() => _results = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _formatError(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatError(Object error) {
    final raw = error.toString();
    const prefix = 'Exception: ';
    return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
  }

  void _applyKeyword(String keyword) {
    final value = keyword.trim();
    _updateFilters((filters) => filters.copyWith(keyword: value.isEmpty ? null : value));
  }

  void _updateFilters(
    TourSearchFilters Function(TourSearchFilters current) transformer,
  ) {
    setState(() => _filters = transformer(_filters));
    _loadTours();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Tìm tour hoặc điểm đến...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            if (value.trim().isEmpty) return;
            _applyKeyword(value);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _openAdvancedFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _FilterChipsBar(
            filters: _filters,
            onOpenDestinations: _openDestinationSheet,
            onOpenDate: _openDateSheet,
            onOpenPrice: _openPriceSheet,
            onOpenDuration: _openDurationSheet,
            onChangeDepartureQuick: (value) {
              _updateFilters((current) => current.copyWith(departure: value));
            },
            onChangeSort: (value) {
              _updateFilters((current) => current.copyWith(sort: value));
            },
            onChangeStatsDays: (value) {
              _updateFilters((current) => current.copyWith(statsDays: value));
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTours,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ErrorState(message: _error!, onRetry: _loadTours)
                      : _results.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final tour = _results[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == _results.length - 1 ? 0 : 16,
                                  ),
                                  child: _SearchResultCard(
                                    tour: tour,
                                    currency: _currency,
                                    onTap: () async {
                                      if (tour.id.isEmpty) return;
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TourDetailPage(id: tour.id),
                                        ),
                                      );
                                      if (!mounted) return;
                                      context.read<HomePresenter>().refreshRecentTours();
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDestinationSheet() async {
    final controller = TextEditingController(text: _filters.destinations.join('\n'));
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập điểm đến mong muốn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('Gõ mỗi điểm trên một dòng hoặc dùng dấu phẩy để phân tách.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Đà Nẵng\nPhú Quốc\nTP. Hồ Chí Minh',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(controller.text),
                    child: const Text('Áp dụng'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (result == null) return;
    final destinations = result
        .split(RegExp(r'[,\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    _updateFilters((current) => current.copyWith(destinations: destinations));
  }

  Future<void> _openDateSheet() async {
    DateTime? departureDate = _filters.departureDate;
    DateTime? startDate = _filters.startDate;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ngày khởi hành',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Khởi hành vào ngày'),
                    subtitle: Text(
                      departureDate == null
                          ? 'Không chọn'
                          : DateFormat('dd/MM/yyyy').format(departureDate!),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: departureDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => departureDate = picked);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tìm tour sau ngày'),
                    subtitle: Text(
                      startDate == null
                          ? 'Không chọn'
                          : DateFormat('dd/MM/yyyy').format(startDate!),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          departureDate = null;
                          startDate = null;
                          setState(() {});
                        },
                        child: const Text('Xóa'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Áp dụng'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (applied != true) return;
    _updateFilters(
      (current) => current.copyWith(
        departureDate: departureDate,
        startDate: startDate,
      ),
    );
  }

  Future<void> _openPriceSheet() async {
    const maxMillions = 50.0;
    final initialMin =
        _filters.priceMin == null
            ? 0.0
            : (_filters.priceMin! / 1000000)
                .clamp(0, maxMillions)
                .toDouble();
    final initialMax =
        _filters.priceMax == null
            ? maxMillions
            : (_filters.priceMax! / 1000000)
                .clamp(0, maxMillions)
                .toDouble();
    RangeValues values = RangeValues(initialMin, initialMax);
    final applied = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khoảng giá (triệu đồng)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                RangeSlider(
                  values: values,
                  min: 0.0,
                  max: maxMillions,
                  divisions: maxMillions.toInt(),
                  labels: RangeLabels(
                    values.start.toStringAsFixed(0),
                    values.end.toStringAsFixed(0),
                  ),
                  onChanged: (newValues) => setState(() => values = newValues),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${values.start.toStringAsFixed(0)} triệu'),
                    Text('${values.end.toStringAsFixed(0)} triệu'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Xóa'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
    if (applied == null) return;
    final minValue = applied ? values.start : 0;
    final maxValue = applied ? values.end : maxMillions;
    _updateFilters(
      (current) => current.copyWith(
        priceMin: minValue <= 0 ? null : minValue * 1000000,
        priceMax: maxValue >= maxMillions ? null : maxValue * 1000000,
      ),
    );
  }

  Future<void> _openDurationSheet() async {
    const maxDays = 20.0;
    RangeValues values = RangeValues(
      (_filters.durationMin ?? 1).toDouble(),
      (_filters.durationMax ?? maxDays.toInt()).toDouble(),
    );
    final applied = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thời lượng chuyến đi (ngày)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                RangeSlider(
                  values: values,
                  min: 1.0,
                  max: maxDays,
                  divisions: maxDays.toInt() - 1,
                  labels: RangeLabels(
                    values.start.toStringAsFixed(0),
                    values.end.toStringAsFixed(0),
                  ),
                  onChanged: (newValues) => setState(() => values = newValues),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${values.start.toStringAsFixed(0)} ngày'),
                    Text('${values.end.toStringAsFixed(0)} ngày'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Xóa'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
    if (applied == null) return;
    _updateFilters(
      (current) => current.copyWith(
        durationMin: applied ? values.start.round() : null,
        durationMax: applied ? values.end.round() : null,
      ),
    );
  }

  Future<void> _openAdvancedFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bộ lọc nâng cao',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _FilterActionChip(
                    label: 'Điểm đến',
                    active: _filters.destinations.isNotEmpty,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openDestinationSheet();
                    },
                  ),
                  _FilterActionChip(
                    label: 'Ngày khởi hành',
                    active:
                        _filters.departureDate != null || _filters.startDate != null,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openDateSheet();
                    },
                  ),
                  _FilterActionChip(
                    label: 'Khoảng giá',
                    active: _filters.priceMin != null || _filters.priceMax != null,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openPriceSheet();
                    },
                  ),
                  _FilterActionChip(
                    label: 'Thời lượng',
                    active:
                        _filters.durationMin != null || _filters.durationMax != null,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openDurationSheet();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Sắp xếp theo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButton<TourSortOption>(
                value: _filters.sort,
                isExpanded: true,
                items: TourSortOption.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    Navigator.of(context).pop();
                    _updateFilters((current) => current.copyWith(sort: value));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipsBar extends StatelessWidget {
  const _FilterChipsBar({
    required this.filters,
    required this.onOpenDestinations,
    required this.onOpenDate,
    required this.onOpenPrice,
    required this.onOpenDuration,
    required this.onChangeDepartureQuick,
    required this.onChangeSort,
    required this.onChangeStatsDays,
  });

  final TourSearchFilters filters;
  final VoidCallback onOpenDestinations;
  final VoidCallback onOpenDate;
  final VoidCallback onOpenPrice;
  final VoidCallback onOpenDuration;
  final ValueChanged<DepartureQuickFilter> onChangeDepartureQuick;
  final ValueChanged<TourSortOption> onChangeSort;
  final ValueChanged<int?> onChangeStatsDays;

  @override
  Widget build(BuildContext context) {
    final hasDestination = filters.destinations.isNotEmpty;
    final hasPrice = filters.priceMin != null || filters.priceMax != null;
    final hasDuration = filters.durationMin != null || filters.durationMax != null;
    final hasDate = filters.departureDate != null || filters.startDate != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterActionChip(
                label: hasDestination
                    ? 'Điểm đến (${filters.destinations.length})'
                    : 'Điểm đến',
                active: hasDestination,
                onPressed: onOpenDestinations,
              ),
              _FilterActionChip(
                label: hasDate ? 'Ngày khởi hành đã chọn' : 'Ngày khởi hành',
                active: hasDate,
                onPressed: onOpenDate,
              ),
              _FilterActionChip(
                label: hasPrice ? 'Khoảng giá đã chọn' : 'Khoảng giá',
                active: hasPrice,
                onPressed: onOpenPrice,
              ),
              _FilterActionChip(
                label: hasDuration ? 'Thời lượng đã chọn' : 'Thời lượng',
                active: hasDuration,
                onPressed: onOpenDuration,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Center(child: Text('Khởi hành')),
                ),
                ...DepartureQuickFilter.values.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_departureLabel(option)),
                      selected: filters.departure == option,
                      onSelected: (_) => onChangeDepartureQuick(option),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TourSortOption>(
                  value: filters.sort,
                  decoration: const InputDecoration(
                    labelText: 'Sắp xếp theo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: TourSortOption.values
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onChangeSort(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: filters.statsDays,
                  decoration: const InputDecoration(
                    labelText: 'Thống kê (ngày)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Mặc định')),
                    DropdownMenuItem(value: 30, child: Text('30 ngày')),
                    DropdownMenuItem(value: 60, child: Text('60 ngày')),
                    DropdownMenuItem(value: 90, child: Text('90 ngày')),
                  ],
                  onChanged: onChangeStatsDays,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _departureLabel(DepartureQuickFilter filter) {
    switch (filter) {
      case DepartureQuickFilter.any:
        return 'Bất kỳ';
      case DepartureQuickFilter.today:
        return 'Hôm nay';
      case DepartureQuickFilter.tomorrow:
        return 'Ngày mai';
    }
  }
}

class _FilterActionChip extends StatelessWidget {
  const _FilterActionChip({
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: active ? const Color(0xFFFF5B00) : null,
        fontWeight: active ? FontWeight.w600 : null,
      ),
      avatar: Icon(
        Icons.filter_alt_outlined,
        size: 18,
        color: active ? const Color(0xFFFF5B00) : Colors.grey.shade600,
      ),
      onPressed: onPressed,
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.tour,
    required this.currency,
    required this.onTap,
  });

  final TourSummary tour;
  final NumberFormat currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = tour.displayPrice < tour.priceFrom;
    final badges = <Widget>[];
    if ((tour.bookingsCount ?? 0) >= 20) {
      badges.add(_Badge(label: 'Đặt nhiều nhất', color: const Color(0xFFFF5B00)));
    }
    if ((tour.ratingAvg ?? 0) >= 4.5 && tour.reviewsCount >= 5) {
      badges.add(_Badge(label: 'Ưa thích nhất', color: const Color(0xFF2ECC71)));
    }
    if (tour.hasAutoPromotion) {
      badges.add(_Badge(label: 'Khuyến mãi', color: const Color(0xFF6C63FF)));
    }

    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    tour.mediaCover ?? 'https://via.placeholder.com/600x400?text=Tour',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                if (badges.isNotEmpty)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: badges,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${tour.destination} · ${tour.duration}N',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(tour.displayPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF5B00),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasDiscount)
                        Text(
                          currency.format(tour.priceFrom),
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.black45,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Color(0xFFFFB400)),
                      const SizedBox(width: 4),
                      Text(
                        '${(tour.ratingAvg ?? 0).toStringAsFixed(1)} (${tour.reviewsCount})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.people_alt_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${tour.bookingsCount ?? 0} lượt đặt',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Không tìm thấy tour phù hợp. Hãy thử điều chỉnh bộ lọc khác nhé!',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
