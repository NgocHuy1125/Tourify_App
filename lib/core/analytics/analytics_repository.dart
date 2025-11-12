import 'package:http/http.dart' as http;

import 'package:tourify_app/core/api/http_client.dart';
import 'package:tourify_app/core/services/secure_storage_service.dart';

class AnalyticsEvent {
  AnalyticsEvent({
    required this.eventName,
    required this.entityType,
    required this.entityId,
    this.occurredAt,
    this.deviceId,
    this.sessionId,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? context,
  }) : metadata = metadata ?? const <String, dynamic>{},
       context = context ?? const <String, dynamic>{};

  final String eventName;
  final String entityType;
  final String entityId;
  final DateTime? occurredAt;
  final String? deviceId;
  final String? sessionId;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson({String? fallbackDeviceId}) {
    final map = <String, dynamic>{
      'event_name': eventName,
      'entity_type': entityType,
      'entity_id': entityId,
      if (occurredAt != null) 'occurred_at': occurredAt!.toIso8601String(),
      if (sessionId != null && sessionId!.isNotEmpty) 'session_id': sessionId,
      if (metadata.isNotEmpty) 'metadata': metadata,
      if (context.isNotEmpty) 'context': context,
    };
    final resolvedDeviceId = deviceId ?? fallbackDeviceId;
    if (resolvedDeviceId != null && resolvedDeviceId.isNotEmpty) {
      map['device_id'] = resolvedDeviceId;
    }
    return map;
  }
}

class AnalyticsRepository {
  AnalyticsRepository()
    : _storage = SecureStorageService(),
      _http = HttpClient(http.Client(), SecureStorageService());

  final SecureStorageService _storage;
  final HttpClient _http;

  Future<void> logEvents(List<AnalyticsEvent> events) async {
    if (events.isEmpty) return;
    try {
      final deviceId = await _storage.ensureDeviceId();
      await _http.post(
        '/api/analytics/events',
        body: {
          'events':
              events
                  .map((event) => event.toJson(fallbackDeviceId: deviceId))
                  .toList(),
        },
      );
    } catch (_) {
      // Silently ignore analytics failures; should not break primary flows.
    }
  }
}
