import 'package:tourify_app/features/tour/model/tour_model.dart';

const _cartBaseHost = 'https://travel-backend-heov.onrender.com';

String _resolveCartUrl(String value) {
  if (value.isEmpty) return value;
  if (value.startsWith('http')) return value;
  if (value.startsWith('/')) return '$_cartBaseHost$value';
  return '$_cartBaseHost/$value';
}

class CartItem {
  final String id;
  final String title;
  final String subTitle;
  final String note;
  final String imageUrl;
  final int quantity;
  final String quantityLabel;
  final double price;
  final String scheduleText;
  final int adults;
  final int children;
  final String scheduleId;
  final String packageId;
  final String packageName;
  final double adultSubtotal;
  final double childSubtotal;
  final TourSummary? tour;

  CartItem({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.note,
    required this.imageUrl,
    required this.quantity,
    required this.quantityLabel,
    required this.price,
    required this.scheduleText,
    required this.adults,
    required this.children,
    required this.scheduleId,
    required this.packageId,
    required this.packageName,
    required this.adultSubtotal,
    required this.childSubtotal,
    this.tour,
  });

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(dynamic value) => value?.toString() ?? '';

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    TourSummary? parsedTour;
    final tourSource = map['tour'];
    if (tourSource is Map<String, dynamic>) {
      parsedTour = TourSummary.fromJson(tourSource);
    }

    String scheduleText = _asString(
      map['schedule_text'] ?? map['date_text'] ?? map['date'] ?? '',
    );
    String scheduleId = _asString(map['schedule_id'] ?? map['scheduleId']);
    if (scheduleText.isEmpty && map['schedule'] is Map<String, dynamic>) {
      final scheduleMap = Map<String, dynamic>.from(map['schedule']);
      scheduleId =
          scheduleId.isNotEmpty
              ? scheduleId
              : _asString(scheduleMap['id'] ?? scheduleMap['uuid']);
      final start = _asString(
        scheduleMap['start_date'] ?? scheduleMap['startDate'] ?? '',
      );
      final end = _asString(
        scheduleMap['end_date'] ?? scheduleMap['endDate'] ?? '',
      );
      if (start.isNotEmpty && end.isNotEmpty) {
        scheduleText = '$start - $end';
      } else if (start.isNotEmpty) {
        scheduleText = start;
      }
    }

    String packageId = _asString(map['package_id'] ?? map['packageId']);
    String packageName = _asString(
      map['package_name'] ?? map['packageName'] ?? '',
    );
    Map<String, dynamic>? packageMap;
    if (map['package'] is Map<String, dynamic>) {
      packageMap = Map<String, dynamic>.from(map['package']);
      if (packageName.isEmpty) {
        packageId =
            packageId.isNotEmpty
                ? packageId
                : _asString(packageMap['id'] ?? packageMap['uuid']);
        packageName = _asString(packageMap['name'] ?? '');
      }
    }

    final quantityRaw = _asInt(map['quantity'] ?? map['count'] ?? 0);
    final adults = _asInt(
      map['adult_quantity'] ?? map['adults'] ?? map['adult_count'],
    );
    final children = _asInt(
      map['child_quantity'] ?? map['children'] ?? map['child_count'],
    );

    final resolvedQuantity =
        quantityRaw != 0
            ? quantityRaw
            : (adults + children > 0 ? adults + children : 1);

    final description = _asString(map['description']);
    final resolvedSubTitle =
        description.isNotEmpty
            ? description
            : (packageName.isNotEmpty
                ? packageName
                : (parsedTour?.destination ?? ''));

    final imageUrl = _resolveCartUrl(
      _asString(
        map['image_url'] ??
            map['thumbnail'] ??
            map['image'] ??
            parsedTour?.mediaCover ??
            '',
      ),
    );

    double price = _asDouble(
      map['price'] ??
          map['total_price'] ??
          map['total_amount'] ??
          map['amount'] ??
          0,
    );
    double adultSubtotal = _asDouble(
      map['adult_subtotal'] ?? map['adult_total'] ?? map['adult_amount'] ?? 0,
    );
    double childSubtotal = _asDouble(
      map['child_subtotal'] ?? map['child_total'] ?? map['child_amount'] ?? 0,
    );

    if (price == 0 && packageMap != null) {
      price = _asDouble(
        packageMap['total_price'] ??
            packageMap['price'] ??
            packageMap['adult_price'] ??
            0,
      );
    }

    final pricing = map['pricing'];
    if (pricing is Map) {
      final pricingMap = Map<String, dynamic>.from(pricing);
      price =
          price != 0
              ? price
              : _asDouble(
                pricingMap['total'] ??
                    pricingMap['total_price'] ??
                    pricingMap['grand_total'] ??
                    pricingMap['amount'] ??
                    0,
              );
      adultSubtotal =
          adultSubtotal != 0
              ? adultSubtotal
              : _asDouble(
                pricingMap['adult_total'] ??
                    pricingMap['adult_amount'] ??
                    pricingMap['adult_subtotal'] ??
                    0,
              );
      childSubtotal =
          childSubtotal != 0
              ? childSubtotal
              : _asDouble(
                pricingMap['child_total'] ??
                    pricingMap['child_amount'] ??
                    pricingMap['child_subtotal'] ??
                    0,
              );
    }
    if (adultSubtotal == 0 && packageMap != null) {
      adultSubtotal = _asDouble(
        packageMap['adult_total'] ??
            packageMap['adult_amount'] ??
            packageMap['adult_subtotal'] ??
            0,
      );
    }
    if (childSubtotal == 0 && packageMap != null) {
      childSubtotal = _asDouble(
        packageMap['child_total'] ??
            packageMap['child_amount'] ??
            packageMap['child_subtotal'] ??
            0,
      );
    }

    final quantityLabel =
        resolvedQuantity > 1 ? '$resolvedQuantity vé' : '1 vé';

    return CartItem(
      id: _asString(map['id'] ?? map['item_id'] ?? map['cart_item_id'] ?? ''),
      title: _asString(
        map['title'] ?? map['tour_title'] ?? parsedTour?.title ?? '',
      ),
      subTitle: resolvedSubTitle,
      note: _asString(map['note'] ?? map['extra'] ?? ''),
      imageUrl: imageUrl,
      quantity: resolvedQuantity,
      quantityLabel: quantityLabel,
      price: price,
      scheduleText: scheduleText,
      adults: adults,
      children: children,
      scheduleId: scheduleId,
      packageId: packageId,
      packageName: packageName,
      adultSubtotal: adultSubtotal,
      childSubtotal: childSubtotal,
      tour: parsedTour,
    );
  }
}

class CartData {
  final List<CartItem> items;
  final double totalPrice;
  final int totalQuantity;

  CartData({
    required this.items,
    required this.totalPrice,
    required this.totalQuantity,
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    // SỬA ĐỔI: Đơn giản hóa việc tìm item
    // _extractMap trong repository đã đảm bảo `map` là đối tượng giỏ hàng.
    final itemMaps = _findCartItemMaps(map);
    final items =
        itemMaps
            .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    double total = CartItem._asDouble(
      map['total_price'] ?? map['total'] ?? map['grand_total'] ?? 0,
    );
    int quantity = CartItem._asInt(
      map['total_quantity'] ??
          map['quantity'] ??
          map['count'] ??
          items.fold<int>(0, (sum, item) => sum + item.quantity),
    );

    // SỬA ĐỔI: Đơn giản hóa việc tìm summary
    final summary = _findCartSummary(map);
    if (summary != null) {
      total =
          total != 0
              ? total
              : CartItem._asDouble(
                summary['total_price'] ??
                    summary['total'] ??
                    summary['grand_total'] ??
                    summary['total_amount'] ??
                    summary['amount'] ??
                    0,
              );
      quantity =
          quantity != 0
              ? quantity
              : CartItem._asInt(
                summary['total_quantity'] ??
                    summary['quantity'] ??
                    summary['count'] ??
                    summary['items_count'] ??
                    0,
              );
    }

    if (total == 0 && items.isNotEmpty) {
      total = items.fold<double>(
        0,
        (sum, item) =>
            sum +
            (item.price != 0
                ? item.price
                : item.adultSubtotal + item.childSubtotal),
      );
    }

    if (quantity == 0 && items.isNotEmpty) {
      quantity = items.fold<int>(0, (sum, item) => sum + item.quantity);
    }

    return CartData(items: items, totalPrice: total, totalQuantity: quantity);
  }
}

// SỬA ĐỔI: Đơn giản hóa hàm này, không cần đệ quy phức tạp
// Giả định `cartMap` LÀ đối tượng giỏ hàng (từ _extractMap)
List<Map<String, dynamic>> _findCartItemMaps(
  dynamic source, [
  Set<int>? visitedMaps,
]) {
  visitedMaps ??= <int>{};

  if (source is Map) {
    final identity = identityHashCode(source);
    if (!visitedMaps.add(identity)) return const [];

    const keysToProbe = [
      'items',
      'cart_items',
      'cartItems',
      'lines',
      'data',
      'results',
      'list',
      'cart',
    ];

    for (final key in keysToProbe) {
      final value = source[key];
      if (value is List) {
        final maps =
            value
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
        if (maps.isNotEmpty && maps.any(_isLikelyCartItem)) {
          return maps;
        }
        final nested = _findCartItemMaps(value, visitedMaps);
        if (nested.isNotEmpty) return nested;
      } else if (value is Map) {
        final nested = _findCartItemMaps(value, visitedMaps);
        if (nested.isNotEmpty) return nested;
      }
    }

    for (final value in source.values) {
      final nested = _findCartItemMaps(value, visitedMaps);
      if (nested.isNotEmpty) return nested;
    }
  } else if (source is List) {
    final maps =
        source
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    if (maps.isNotEmpty && maps.any(_isLikelyCartItem)) {
      return maps;
    }
    for (final element in source) {
      final nested = _findCartItemMaps(element, visitedMaps);
      if (nested.isNotEmpty) return nested;
    }
  }

  return const [];
}

bool _isLikelyCartItem(Map<String, dynamic> map) {
  return map.containsKey('tour') ||
      map.containsKey('tour_id') ||
      map.containsKey('tourId') ||
      map.containsKey('package_id') ||
      map.containsKey('package') ||
      map.containsKey('quantity');
}

Map<String, dynamic>? _findCartSummary(
  dynamic source, [
  Set<int>? visitedMaps,
]) {
  visitedMaps ??= <int>{};

  if (source is Map) {
    final identity = identityHashCode(source);
    if (!visitedMaps.add(identity)) return null;

    if (_isLikelySummary(source)) {
      return {
        for (final entry in source.entries) entry.key.toString(): entry.value,
      };
    }

    const keysToProbe = [
      'summary',
      'totals',
      'pricing',
      'meta',
      'data',
      'cart',
      'info',
    ];

    for (final key in keysToProbe) {
      final value = source[key];
      if (value is Map) {
        final summary = _findCartSummary(value, visitedMaps);
        if (summary != null) return summary;
      } else if (value is List) {
        final summary = _findCartSummary(value, visitedMaps);
        if (summary != null) return summary;
      }
    }

    for (final value in source.values) {
      final summary = _findCartSummary(value, visitedMaps);
      if (summary != null) return summary;
    }
  } else if (source is List) {
    for (final element in source) {
      final summary = _findCartSummary(element, visitedMaps);
      if (summary != null) return summary;
    }
  }

  return null;
}

bool _isLikelySummary(Map map) {
  return map.containsKey('total_price') ||
      map.containsKey('total') ||
      map.containsKey('grand_total') ||
      map.containsKey('items_count') ||
      map.containsKey('total_quantity');
}
