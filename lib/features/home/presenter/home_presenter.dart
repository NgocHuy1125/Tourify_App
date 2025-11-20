import 'package:flutter/foundation.dart';
import 'package:tourify_app/core/analytics/analytics_repository.dart';
import '/features/tour/model/tour_model.dart';
import '/features/home/model/home_models.dart';
import '/features/home/model/home_repository.dart';
import '/features/home/model/recent_tour_storage.dart';

enum HomeState { initial, loading, success, error }

class HomePresenter with ChangeNotifier {
  final HomeRepository _repository;
  final AnalyticsRepository _analyticsRepository;
  final RecentTourStorage _recentStorage;

  HomePresenter(
    this._repository,
    this._analyticsRepository, {
    RecentTourStorage? recentStorage,
  }) : _recentStorage = recentStorage ?? RecentTourStorage();

  HomeState _state = HomeState.initial;
  HomeState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<TourSummary> _tours = [];
  List<TourSummary> get tours => _tours;

  List<PromotionItem> _promotions = [];
  List<PromotionItem> get promotions => _promotions;

  List<TourSummary> _trendingTours = [];
  List<TourSummary> get trendingTours => _trendingTours;

  List<CategoryItem> _categories = [];
  List<CategoryItem> get categories => _categories;

  List<DestinationHighlight> _destinations = [];
  List<DestinationHighlight> get destinations => _destinations;

  List<RecommendationItem> _recommendations = [];
  List<RecommendationItem> get recommendations => _recommendations;

  List<RecentTourItem> _recentTours = [];
  List<RecentTourItem> get recentTours => _recentTours;

  bool _recentToursLoading = false;
  bool get recentToursLoading => _recentToursLoading;

  String _recentToursMessage = '';
  String get recentToursMessage => _recentToursMessage;

  bool _recommendationsLoading = false;
  bool get recommendationsLoading => _recommendationsLoading;

  String _recommendationsMessage = '';
  String get recommendationsMessage => _recommendationsMessage;
  RecommendationMeta _recommendationsMeta = const RecommendationMeta();
  RecommendationMeta get recommendationsMeta => _recommendationsMeta;

  List<ChatMessage> _chatMessages = const [];
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  bool _isSendingChat = false;
  bool get isSendingChat => _isSendingChat;

  String _chatError = '';
  String get chatError => _chatError;

  String _chatLanguage = 'vi';
  String get chatLanguage => _chatLanguage;

  Future<void> fetchHome() async {
    _state = HomeState.loading;
    _errorMessage = '';
    _recommendations = [];
    _recommendationsMessage = '';
    _recommendationsMeta = const RecommendationMeta();
    _recommendationsLoading = true;
    _recentTours = [];
    _recentToursLoading = true;
    _recentToursMessage = '';
    notifyListeners();

    try {
      _promotions = await _repository.fetchActivePromotions(limit: 6);
    } catch (_) {
      _promotions = [];
    }

    try {
      _categories = await _repository.fetchHighlightCategories(limit: 6);
    } catch (_) {
      _categories = [];
    }

    try {
      _destinations = await _repository.fetchDestinationHighlights(limit: 12);
    } catch (_) {
      _destinations = [];
    }

    await _loadRecentTours(silent: true);

    try {
      _tours = await _repository.fetchAllTours();
    } catch (e) {
      _errorMessage = e.toString();
      _state = HomeState.error;
      _recommendationsLoading = false;
      notifyListeners();
      return;
    }

    try {
      _trendingTours = await _repository.fetchTrendingTours(limit: 8, days: 30);
    } catch (_) {
      _trendingTours = [];
    }

    await _loadRecommendations();

    _state = HomeState.success;
    notifyListeners();
  }

  Future<void> refreshRecentTours() async {
    await _loadRecentTours();
  }

  Future<void> _loadRecommendations() async {
    try {
      final result = await _repository.fetchRecommendations(limit: 8);
      _recommendations = result.items;
      _recommendationsMeta = result.meta;
      _recommendationsMessage = _buildRecommendationMessage(result.meta);
    } catch (_) {
      _recommendations = [];
      _recommendationsMeta = const RecommendationMeta();
      _recommendationsMessage = 'Không thể tải gợi ý. Vui lòng thử lại sau.';
    } finally {
      _recommendationsLoading = false;
    }
  }

  String _buildRecommendationMessage(RecommendationMeta meta) {
    if (meta.count > 0 && _recommendations.isNotEmpty) return '';
    if (!meta.hasPersonalizedSignals) {
      return 'Tour sẽ được gợi ý sau vài thao tác (xem/lưu/đặt tour…).';
    }
    if (meta.hasPersonalizedSignals && meta.count == 0) {
      return 'Chưa có gợi ý phù hợp. Hãy khám phá thêm để Tourify hiểu bạn hơn.';
    }
    return '';
  }

  Future<void> trackRecommendationClick(RecommendationItem item) async {
    try {
      await _analyticsRepository.logEvents([
        AnalyticsEvent(
          eventName: 'recommendation_clicked',
          entityType: 'tour',
          entityId: item.tourId,
          metadata: {
            'score': item.score,
            if (item.reasons.isNotEmpty) 'reasons': item.reasons,
          },
        ),
      ]);
    } catch (_) {
      // Ignore analytics failures
    }
  }

  Future<void> _loadRecentTours({bool silent = false}) async {
    if (!silent) {
      _recentToursLoading = true;
      notifyListeners();
    } else {
      _recentToursLoading = true;
    }

    try {
      final remoteItems = await _repository.fetchRecentTours(limit: 10);
      if (remoteItems.isNotEmpty) {
        await _recentStorage.replaceAll(remoteItems);
      }
      final localItems = await _recentStorage.getAll();
      _recentTours = _mergeRecentTours(remoteItems, localItems);
      _recentToursMessage =
          _recentTours.isEmpty
              ? 'Bạn chưa xem tour nào. Khám phá thêm để lưu vào đây nhé!'
              : '';
    } on UnauthorizedHomeException catch (e) {
      final localItems = await _recentStorage.getAll();
      if (localItems.isNotEmpty) {
        _recentTours = localItems;
        _recentToursMessage = '';
      } else {
        _recentTours = [];
        _recentToursMessage = e.message ??
            'Bạn cần đăng nhập để xem lịch sử tour đã xem gần đây.';
      }
    } catch (error) {
      final localItems = await _recentStorage.getAll();
      if (localItems.isNotEmpty) {
        _recentTours = localItems;
        _recentToursMessage = '';
      } else {
        _recentTours = [];
        _recentToursMessage =
            error.toString().isNotEmpty
                ? error.toString()
                : 'Không thể tải lịch sử tour đã xem. Vui lòng thử lại.';
      }
    } finally {
      _recentToursLoading = false;
      if (!silent) notifyListeners();
    }
  }

  List<RecentTourItem> _mergeRecentTours(
    List<RecentTourItem> remote,
    List<RecentTourItem> local, {
    int limit = 10,
  }) {
    final seen = <String>{};
    final result = <RecentTourItem>[];

    void addItem(RecentTourItem item) {
      if (item.tour.id.isEmpty) return;
      if (seen.add(item.tour.id)) {
        result.add(item);
      }
    }

    for (final item in remote) {
      addItem(item);
    }
    for (final item in local) {
      addItem(item);
    }

    result.sort(
      (a, b) {
        final aDate = a.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      },
    );

    return result.take(limit).toList();
  }

  void updateChatLanguage(String language) {
    final resolved = language.trim().isEmpty ? 'vi' : language.trim();
    if (_chatLanguage == resolved) return;
    _chatLanguage = resolved;
    notifyListeners();
  }

  void clearChatSession() {
    if (_chatMessages.isEmpty && _chatError.isEmpty) return;
    _chatMessages = const [];
    _chatError = '';
    notifyListeners();
  }

  Future<void> sendChatMessage(String message, {String? language}) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _isSendingChat) return;

    final lang = (language ?? _chatLanguage).trim().isEmpty
        ? 'vi'
        : (language ?? _chatLanguage).trim();

    final userMessage = ChatMessage.user(trimmed);
    _chatMessages = [..._chatMessages, userMessage];
    _chatError = '';
    _isSendingChat = true;
    notifyListeners();

    try {
      final reply = await _repository.sendChatbotMessage(trimmed, language: lang);
      final responseText = reply.reply.isNotEmpty
          ? reply.reply
          : 'Mình tạm thời chưa có câu trả lời. Bạn thử diễn đạt khác nhé!';
      final botMessage = ChatMessage.bot(
        responseText,
        sources: reply.sources,
      );
      _chatMessages = [..._chatMessages, botMessage];
    } on ChatbotRateLimitException catch (error) {
      _chatError =
          error.message ??
          'Bạn đang hỏi quá nhanh. Vui lòng thử lại sau ít phút.';
    } catch (error) {
      final messageText = error.toString();
      _chatError =
          messageText.isNotEmpty
              ? messageText
              : 'Không thể kết nối chatbot. Vui lòng thử lại.';
    } finally {
      _isSendingChat = false;
      notifyListeners();
    }
  }
}


