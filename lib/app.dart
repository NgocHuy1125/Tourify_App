import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'package:tourify_app/features/auth/view/auth_screen.dart';
import 'package:tourify_app/main_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _brand = Color(0xFFFF5B00);

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light();
    final scheme = ColorScheme.fromSeed(seedColor: _brand);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tourify App',
      theme: base.copyWith(
        useMaterial3: true,
        colorScheme: scheme,
        primaryColor: _brand,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: _brand),
          titleTextStyle: const TextStyle(
            color: _brand,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _brand,
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _brand),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: Colors.white,
          selectedColor: _brand.withOpacity(0.12),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
        textTheme: base.textTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
        iconTheme: const IconThemeData(color: _brand),
      ),
      home: Consumer<AuthNotifier>(
        builder:
            (_, auth, __) =>
                auth.isLoggedIn ? const MainScreen() : const AuthScreen(),
      ),
    );
  }
}
