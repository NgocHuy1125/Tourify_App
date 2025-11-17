import 'package:intl/intl.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parseData(dynamic source) {
      if (source is Map<String, dynamic>) return source;
      if (source is Map) return Map<String, dynamic>.from(source);
      return const <String, dynamic>{};
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    final data = parseData(json['data']);
    final title =
        (json['title'] ??
                data['title'] ??
                _fallbackTitle(json['type']?.toString()))
            ?.toString() ??
        'Thông báo';
    final message =
        (json['message'] ??
                data['message'] ??
                data['description'] ??
                data['details'])
            ?.toString() ??
        '';

    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      title: title,
      message: message,
      data: data,
      createdAt: parseDate(json['created_at']) ??
          parseDate(json['createdAt']) ??
          DateTime.now(),
      readAt: parseDate(json['read_at']) ?? parseDate(json['readAt']),
    );
  }

  AppNotification markAsRead() {
    if (isRead) return this;
    return copyWith(readAt: DateTime.now());
  }

  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  static String _fallbackTitle(String? rawType) {
    final type = rawType?.toLowerCase() ?? '';
    if (type.contains('voucher')) return 'Voucher mới';
    if (type.contains('refund_request')) return 'Yêu cầu hoàn tiền';
    if (type.contains('refund')) return 'Cập nhật hoàn tiền';
    if (type.contains('invoice')) return 'Hóa đơn đã phát hành';
    if (type.contains('booking')) return 'Cập nhật đặt tour';
    return 'Thông báo';
  }
}

class NotificationPage {
  NotificationPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<AppNotification> items;
  final int page;
  final bool hasMore;
}

class NotificationFormatter {
  const NotificationFormatter();

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
