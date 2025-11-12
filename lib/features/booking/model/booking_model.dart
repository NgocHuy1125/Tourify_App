import 'package:intl/intl.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class BookingRequest {
  BookingRequest({
    required this.tourId,
    required this.scheduleId,
    required this.packageId,
    required this.adults,
    required this.children,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.paymentMethod,
    required this.notes,
    required this.passengers,
    this.promotionCode,
  });

  final String tourId;
  final String? scheduleId;
  final String packageId;
  final int adults;
  final int children;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String paymentMethod;
  final String notes;
  final List<BookingPassenger> passengers;
  final String? promotionCode;

  Map<String, dynamic> toJson() {
    return {
      'tour_id': tourId,
      if (scheduleId != null && scheduleId!.isNotEmpty)
        'schedule_id': scheduleId,
      'package_id': packageId,
      'adults': adults,
      'children': children,
      'contact_name': contactName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'payment_method': paymentMethod,
      'notes': notes,
      if (promotionCode != null && promotionCode!.trim().isNotEmpty)
        'promotion_code': promotionCode,
      'passengers': passengers.map((e) => e.toJson()).toList(),
    };
  }
}

class BookingPassenger {
  final String type; // adult | child
  final String fullName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? documentNumber;

  BookingPassenger({
    required this.type,
    required this.fullName,
    this.gender,
    this.dateOfBirth,
    this.documentNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'full_name': fullName,
      if (gender != null && gender!.isNotEmpty) 'gender': gender,
      if (dateOfBirth != null)
        'date_of_birth': DateFormat('yyyy-MM-dd').format(dateOfBirth!),
      if (documentNumber != null && documentNumber!.isNotEmpty)
        'document_number': documentNumber,
    };
  }
}

class BookingResponse {
  BookingResponse({
    required this.id,
    required this.status,
    required this.message,
    this.paymentUrl,
    this.paymentQrUrl,
    this.totalPrice,
    this.discountTotal,
    this.promotions = const [],
  });

  final String id;
  final String status;
  final String message;
  final String? paymentUrl;
  final String? paymentQrUrl;
  final double? totalPrice;
  final double? discountTotal;
  final List<AppliedPromotion> promotions;

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    final bookingRaw = json['booking'];
    final booking =
        bookingRaw is Map<String, dynamic>
            ? Map<String, dynamic>.from(bookingRaw)
            : bookingRaw is Map
                ? Map<String, dynamic>.from(bookingRaw.cast())
                : <String, dynamic>{};
    if (booking.isEmpty) {
      booking.addAll(json);
    }

    final paymentRaw = booking['payment'];
    final payment =
        paymentRaw is Map<String, dynamic>
            ? Map<String, dynamic>.from(paymentRaw)
            : paymentRaw is Map
                ? Map<String, dynamic>.from(paymentRaw.cast())
                : <String, dynamic>{};

    String? _stringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    final resolvedPaymentUrl = _stringOrNull(
      json['payment_url'] ??
          booking['payment_url'] ??
          payment['redirect_url'] ??
          payment['pay_url'] ??
          payment['url'],
    );

    final resolvedPaymentQrUrl = _stringOrNull(
      json['payment_qr_url'] ??
          booking['payment_qr_url'] ??
          payment['qr_url'] ??
          payment['qr_image'] ??
          payment['qr'],
    );

    final promotionsRaw =
        booking['promotions'] ??
        json['promotions'] ??
        booking['applied_promotions'] ??
        json['applied_promotions'];
    final parsedPromotions =
        (promotionsRaw is List)
            ? promotionsRaw
                .whereType<Map>()
                .map((e) => AppliedPromotion.fromJson(
                      Map<String, dynamic>.from(e),
                    ))
                .toList()
            : const <AppliedPromotion>[];

    return BookingResponse(
      id: _stringOrNull(booking['id']) ?? '',
      status: _stringOrNull(booking['status']) ?? '',
      message: _stringOrNull(json['message']) ??
          _stringOrNull(booking['message']) ??
          '',
      paymentUrl: resolvedPaymentUrl,
      paymentQrUrl: resolvedPaymentQrUrl,
      totalPrice: _parseDouble(
        booking['total_price'] ?? booking['total'] ?? booking['grand_total'],
      ),
      discountTotal: _parseDouble(
        booking['discount_total'] ?? booking['discount'] ?? booking['discounts'],
      ),
      promotions: parsedPromotions,
    );
  }
}

class BookingSummary {
  BookingSummary({
    required this.id,
    required this.status,
    this.reference,
    this.tour,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.totalAmount,
    this.amountPaid,
    this.balanceDue,
    this.adults = 0,
    this.children = 0,
    this.paymentStatus,
    this.review,
    this.totalPrice,
    this.discountTotal,
    this.promotions = const [],
    this.refundRequests = const [],
    this.invoice,
  });

  final String id;
  final String status;
  final String? reference;
  final TourSummary? tour;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final double? totalAmount;
  final double? amountPaid;
  final double? balanceDue;
  final int adults;
  final int children;
  final String? paymentStatus;
  final TourReview? review;
  final double? totalPrice;
  final double? discountTotal;
  final List<AppliedPromotion> promotions;
  final List<RefundRequest> refundRequests;
  final BookingInvoice? invoice;

  int get totalGuests => adults + children;

  bool get canReview {
    final normalized = status.toLowerCase();
    return normalized.contains('complete') && review == null;
  }

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    Map<String, dynamic>? tourMap;
    final tourData = json['tour'] ?? json['tour_data'] ?? json['tour_info'];
    if (tourData is Map) {
      tourMap = Map<String, dynamic>.from(tourData);
    }
    tourMap ??= {};
    tourMap.putIfAbsent('id', () => json['tour_id']);
    tourMap.putIfAbsent('title', () => json['tour_title']);

    final reference =
        (json['code'] ??
                json['reference'] ??
                json['booking_code'] ??
                json['number'] ??
                '')
            .toString()
            .trim();

    final paymentInfo = json['payment'] is Map ? json['payment'] as Map : null;

    TourReview? review;
    final reviewData = json['review'] ?? json['latest_review'];
    if (reviewData is Map) {
      review = TourReview.fromJson(Map<String, dynamic>.from(reviewData));
    }

    final promotionsRaw =
        json['promotions'] ??
        json['applied_promotions'] ??
        json['discounts'] ??
        json['promotion_items'];

    final parsedPromotions =
        (promotionsRaw is List)
            ? promotionsRaw
                .whereType<Map>()
                .map((e) => AppliedPromotion.fromJson(
                      Map<String, dynamic>.from(e),
                    ))
                .toList()
            : const <AppliedPromotion>[];

    final refundRaw = json['refund_requests'];
    final refundRequests =
        (refundRaw is List)
            ? refundRaw
                .whereType<Map>()
                .map((item) => RefundRequest.fromJson(
                      Map<String, dynamic>.from(item),
                    ))
                .toList()
            : const <RefundRequest>[];

    BookingInvoice? invoice;
    final invoiceRaw = json['invoice'] ?? json['invoice_request'];
    if (invoiceRaw is Map) {
      invoice = BookingInvoice.fromJson(
        Map<String, dynamic>.from(invoiceRaw),
      );
    }

    return BookingSummary(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      reference: reference.isEmpty ? null : reference,
      tour: tourMap.isNotEmpty ? TourSummary.fromJson(tourMap) : null,
      startDate: parseDate(
        json['start_date'] ?? json['startDate'] ?? json['check_in'],
      ),
      endDate: parseDate(
        json['end_date'] ?? json['endDate'] ?? json['check_out'],
      ),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      totalAmount: parseDouble(
        json['total_amount'] ??
            json['grand_total'] ??
            json['total'] ??
            json['amount'],
      ),
      amountPaid: parseDouble(
        json['amount_paid'] ??
            json['paid_amount'] ??
            paymentInfo?['paid_amount'],
      ),
      balanceDue: parseDouble(
        json['balance_due'] ??
            json['amount_due'] ??
            paymentInfo?['balance_due'],
      ),
      adults: parseInt(
        json['adults'] ?? json['adult_quantity'] ?? json['adult_count'],
      ),
      children: parseInt(
        json['children'] ?? json['child_quantity'] ?? json['child_count'],
      ),
      paymentStatus: json['payment_status']?.toString(),
      review: review,
      totalPrice: parseDouble(
        json['total_price'] ?? json['total_after_discount'] ?? json['total'],
      ),
      discountTotal: parseDouble(
        json['discount_total'] ?? json['discount'] ?? json['discounts'],
      ),
      promotions: parsedPromotions,
      refundRequests: refundRequests,
      invoice: invoice,
    );
  }
}

class AppliedPromotion {
  AppliedPromotion({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    required this.discountAmount,
    this.description,
  });

  final String id;
  final String code;
  final String discountType;
  final double value;
  final double discountAmount;
  final String? description;

  factory AppliedPromotion.fromJson(Map<String, dynamic> json) {
    double _double(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return AppliedPromotion(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'percent',
      value: _double(json['value']),
      discountAmount: _double(
        json['discount_amount'] ?? json['amount'] ?? json['discount'],
      ),
      description: json['description']?.toString(),
    );
  }
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class RefundRequest {
  RefundRequest({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankName,
    this.bankBranch,
    this.customerMessage,
    this.partnerMessage,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String status;
  final double amount;
  final String currency;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankBranch;
  final String? customerMessage;
  final String? partnerMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return RefundRequest(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount: parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'VND',
      bankAccountName: json['bank_account_name']?.toString(),
      bankAccountNumber: json['bank_account_number']?.toString(),
      bankName: json['bank_name']?.toString(),
      bankBranch: json['bank_branch']?.toString(),
      customerMessage: json['customer_message']?.toString(),
      partnerMessage: json['partner_message']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

class BookingInvoice {
  BookingInvoice({
    required this.invoiceNumber,
    required this.amount,
    required this.currency,
    required this.deliveryMethod,
    this.downloadUrl,
    this.emailedAt,
  });

  final String invoiceNumber;
  final double amount;
  final String currency;
  final String deliveryMethod;
  final String? downloadUrl;
  final DateTime? emailedAt;

  factory BookingInvoice.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return BookingInvoice(
      invoiceNumber: json['invoice_number']?.toString() ??
          json['number']?.toString() ??
          '',
      amount: parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'VND',
      deliveryMethod: json['delivery_method']?.toString() ?? 'email',
      downloadUrl: json['download_url']?.toString(),
      emailedAt: parseDate(json['emailed_at']),
    );
  }
}

class BookingPaymentIntent {
  BookingPaymentIntent({
    required this.id,
    required this.method,
    required this.status,
    required this.amount,
    this.paymentUrl,
    this.paymentQrUrl,
  });

  final String id;
  final String method;
  final String status;
  final double amount;
  final String? paymentUrl;
  final String? paymentQrUrl;

  factory BookingPaymentIntent.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final payment =
        json['payment'] is Map
            ? Map<String, dynamic>.from(json['payment'] as Map)
            : json;

    return BookingPaymentIntent(
      id: payment['id']?.toString() ?? json['id']?.toString() ?? '',
      method: payment['method']?.toString() ?? json['method']?.toString() ?? '',
      status: payment['status']?.toString() ?? json['status']?.toString() ?? '',
      amount: parseDouble(payment['amount'] ?? json['amount']),
      paymentUrl: json['payment_url']?.toString() ?? payment['payment_url']?.toString(),
      paymentQrUrl: json['payment_qr_url']?.toString() ?? payment['payment_qr_url']?.toString(),
    );
  }
}
