import 'package:intl/intl.dart';

class BookingRequest {
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
  });

  Map<String, dynamic> toJson() {
    return {
      'tour_id': tourId,
      if (scheduleId != null && scheduleId!.isNotEmpty) 'schedule_id': scheduleId,
      'package_id': packageId,
      'adults': adults,
      'children': children,
      'contact_name': contactName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'payment_method': paymentMethod,
      'notes': notes,
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
  final String id;
  final String status;
  final String message;
  final String? paymentUrl;

  BookingResponse({
    required this.id,
    required this.status,
    required this.message,
    this.paymentUrl,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map? ?? json;
    return BookingResponse(
      id: booking['id']?.toString() ?? '',
      status: booking['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      paymentUrl: json['payment_url']?.toString(),
    );
  }
}
