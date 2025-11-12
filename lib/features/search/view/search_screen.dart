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
  List<SearchSuggestion> _defaultSuggestions = [];
  List<String> _historyList = [];

  Timer? _debounce;
  bool _loading = false;
  bool _defaultLoading = false;
  String? _defaultError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadDefaultSuggestions();
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
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

  Future<void> _loadDefaultSuggestions() async {
    setState(() {
      _defaultLoading = true;
      _defaultError = null;
    });
    try {
      final data = await _repo.suggestions('');
      if (!mounted) return;
      setState(() {
        _defaultSuggestions = data;
        _defaultLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _defaultLoading = false;
        _defaultError = e.toString();
      });
    }
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
      try {
        final res = await _repo.suggestions(q);
        if (!mounted) return;
        setState(() {
          _suggestions = res;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _loading = false;
        });
      }
    });
  }

  void _addToHistory(String keyword) async {
    if (keyword.isEmpty) return;
    await _history.add(keyword);
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    const popular = [
      'Đà Nẵng',
      'Thành phố Hồ Chí Minh',
      'Phú Quốc',
      'Hà Nội',
      'Sa Pa',
      'Hội An',
      'Nha Trang',
      'Hạ Long',
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
              hintText: 'Tìm điểm đến, tour, dịch vụ...',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 11,
                horizontal: 10,
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => _addToHistory(value.trim()),
          ),
        ),
      ),
      body:
          _controller.text.isEmpty
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
              const Text(
                'Lịch sử tìm kiếm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () async {
                  await _history.clear();
                  _loadHistory();
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _historyList
                    .map(
                      (e) => ActionChip(
                        label: Text(e),
                        onPressed: () {
                          _controller.text = e;
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: e.length),
                          );
                          _onChanged();
                        },
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Mọi người đang tìm kiếm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              popular
                  .map(
                    (e) => ActionChip(
                      label: Text(e),
                      onPressed: () {
                        _controller.text = e;
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: e.length),
                        );
                        _onChanged();
                      },
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Gợi ý cho bạn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_defaultLoading)
          const Center(child: CircularProgressIndicator())
        else if (_defaultError != null)
          Text(_defaultError!, style: const TextStyle(color: Colors.redAccent))
        else if (_defaultSuggestions.isEmpty)
          const Text('Không có gợi ý nào. Hãy thử nhập từ khóa để tìm kiếm.'),
        if (_defaultSuggestions.isNotEmpty)
          ..._defaultSuggestions.map(
            (s) => ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(s.title),
              subtitle: Text(s.destination),
              onTap: () {
                _controller.text = s.title;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: s.title.length),
                );
                _addToHistory(s.title);
                _onChanged();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestions() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_suggestions.isEmpty) {
      return const Center(child: Text('Không có gợi ý phù hợp.'));
    }
    return ListView.separated(
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(suggestion.title),
          subtitle: Text(suggestion.destination),
          onTap: () {
            _addToHistory(suggestion.title);
            // TODO: định hướng tới trang chi tiết/kết quả tìm kiếm
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: _suggestions.length,
    );
  }
}
