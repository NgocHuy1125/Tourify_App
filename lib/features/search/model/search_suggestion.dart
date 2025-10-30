class SearchSuggestion {
  final String id;
  final String title;
  final String destination;

  SearchSuggestion({required this.id, required this.title, required this.destination});

  factory SearchSuggestion.fromJson(Map<String, dynamic> j) => SearchSuggestion(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        destination: j['destination']?.toString() ?? '',
      );
}

