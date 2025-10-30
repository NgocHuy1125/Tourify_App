import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  static String supabaseUrl = '';

  static String supabaseAnonKey = '';

  // Keep API async so callers don't need change; dotenv.load() is synchronous
  // for the installed `dotenv` package, so call it directly.
  static Future<void> load() async {
    // Read the .env file bundled as an asset (pubspec.yaml includes - .env).
    // This avoids depending on an external dotenv API and works inside Flutter.
    String content;
    try {
      content = await rootBundle.loadString('.env');
    } catch (e) {
      throw Exception('Could not load .env asset: $e');
    }

    final Map<String, String> vars = {};
    for (final raw in content.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final idx = line.indexOf('=');
      if (idx <= 0) continue;
      final k = line.substring(0, idx).trim();
      var v = line.substring(idx + 1).trim();
      if ((v.startsWith('\"') && v.endsWith('\"')) ||
          (v.startsWith("'") && v.endsWith("'"))) {
        v = v.substring(1, v.length - 1);
      }
      vars[k] = v;
    }

    supabaseUrl = vars['SUPABASE_URL'] ?? 'fallback_url';
    supabaseAnonKey = vars['SUPABASE_ANON_KEY'] ?? 'fallback_key';

    if (supabaseUrl == 'fallback_url' || supabaseAnonKey == 'fallback_key') {
      throw Exception(
        'Could not load environment variables from .env file. '
        'Please ensure the file exists and contains SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }
}
