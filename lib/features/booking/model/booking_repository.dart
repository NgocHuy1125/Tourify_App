import 'package:tourify_app/features/booking/model/booking_model.dart';

abstract class BookingRepository {
  Future<BookingResponse> createBooking(BookingRequest request);
}
