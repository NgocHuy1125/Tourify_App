import 'package:flutter/material.dart';

class AsyncView extends StatelessWidget {
  final bool loading;
  final String? error;
  final Widget child;
  const AsyncView({
    super.key,
    required this.loading,
    this.error,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));
    return child;
  }
}
