import 'package:flutter/material.dart';

class BookingDetailPage extends StatelessWidget {
  final String id;
  const BookingDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đơn #$id')),
      body: const Center(child: Text('Booking detail (placeholder)')),
    );
  }
}
