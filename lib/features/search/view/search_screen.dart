import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tourify_app/features/search/model/search_history_storage.dart';
import 'package:tourify_app/features/search/model/search_repository.dart';
import 'package:tourify_app/features/search/model/search_suggestion.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _repo = SearchRepository();
  final _history = SearchHistoryStorage();

  List<SearchSuggestion> _suggestions = [];
  List<String> _historyList = [];
  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _controller.addListener(_onChanged);
    // autofocus when enter
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final data = await _history.get();
    setState(() => _historyList = data);
  }

  void _onChanged() {
    final q = _controller.text.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      if (q.isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      setState(() => _loading = true);
      final res = await _repo.suggestions(q);
      if (!mounted) return;
      setState(() {
        _suggestions = res;
        _loading = false;
      });
    });
  }

  void _addToHistory(String k) async {
    await _history.add(k);
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final popular = const [
      'Đà Nẵng',
      'Thành phố Hồ Chí Minh',
      'Phú Quốc',
      'Hà Nội',
      'Sa Pa',
      'Hội An',
      'Nha Trang',
      'Thành phố Hạ Long',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          margin: const EdgeInsets.only(right: 12),
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: 'Tìm điểm đến',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 10),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => _addToHistory(v.trim()),
          ),
        ),
      ),
      body: _controller.text.isEmpty
          ? _buildEmptyState(popular)
          : _buildSuggestions(),
    );
  }

  Widget _buildEmptyState(List<String> popular) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_historyList.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lịch sử tìm kiếm', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () async {
                  await _history.clear();
                  _loadHistory();
                },
                icon: const Icon(Icons.delete_outline),
              )
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _historyList
                .map((e) => ActionChip(label: Text(e), onPressed: () {
                      _controller.text = e;
                      _controller.selection = TextSelection.fromPosition(TextPosition(offset: e.length));
                      _onChanged();
                    }))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text('Mọi người đang tìm kiếm', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popular
              .map((e) => ActionChip(label: Text(e), onPressed: () {
                    _controller.text = e;
                    _controller.selection = TextSelection.fromPosition(TextPosition(offset: e.length));
                    _onChanged();
                  }))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_suggestions.isEmpty) {
      return const Center(child: Text('Không có gợi ý'));
    }
    return ListView.separated(
      itemBuilder: (context, index) {
        final s = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(s.title),
          subtitle: Text(s.destination),
          onTap: () {
            _addToHistory(s.title);
            // TODO: điều hướng tới trang kết quả tìm kiếm nếu có
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: _suggestions.length,
    );
  }
}

