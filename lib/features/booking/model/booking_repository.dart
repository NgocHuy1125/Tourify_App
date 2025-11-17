import 'package:tourify_app/features/booking/model/booking_model.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

abstract class BookingRepository {
  Future<BookingResponse> createBooking(BookingRequest request);
  Future<List<BookingSummary>> fetchBookings({String? status});
  Future<TourReview> createReview({
    required String bookingId,
    required int rating,
    String? comment,
  });
  Future<TourReview> updateReview(
    String reviewId, {
    int? rating,
    String? comment,
  });
  Future<void> deleteReview(String reviewId);
  Future<BookingPaymentIntent> createPayLater(String bookingId);
  Future<BookingPaymentIntent> fetchPaymentStatus(String bookingId);
  Future<RefundRequest> submitRefundRequest(
    String bookingId, {
      required String bankAccountName,
      required String bankAccountNumber,
      required String bankName,
      required String bankBranch,
      double? amount,
      String currency,
      String? customerMessage,
    });
  Future<void> confirmRefundRequest(String refundRequestId);
  Future<BookingInvoice?> fetchInvoice(String bookingId);
  Future<BookingInvoice> requestInvoice(
    String bookingId, {
      required String customerName,
      required String taxCode,
      required String address,
      required String email,
      required String deliveryMethod,
    });
  Future<BookingCancellationResult> cancelBooking(String bookingId);
}
