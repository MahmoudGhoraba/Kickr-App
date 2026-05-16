import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static String get supabaseUrl {
    final v = dotenv.env['SUPABASE_URL'] ?? '';
    if (v.isEmpty) throw StateError('SUPABASE_URL is missing from .env');
    return v;
  }

  static String get supabaseAnonKey {
    final v = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (v.isEmpty) throw StateError('SUPABASE_ANON_KEY is missing from .env');
    return v;
  }
}
