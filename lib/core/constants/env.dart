import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get backendBaseUrl => dotenv.env['BACKEND_BASE_URL'] ?? '';
  static String get internalApiKey => dotenv.env['INTERNAL_API_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static void validate() {
    assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL is missing in .env file');
    assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY is missing in .env file');
    assert(backendBaseUrl.isNotEmpty, 'BACKEND_BASE_URL is missing in .env file');
    assert(internalApiKey.isNotEmpty, 'INTERNAL_API_KEY is missing in .env file');
    assert(geminiApiKey.isNotEmpty, 'GEMINI_API_KEY is missing in .env file');
  }
}
