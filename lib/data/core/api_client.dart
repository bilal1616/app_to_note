import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  static ApiClient create() {
    final baseUrl = dotenv.get('BACKEND_BASE_URL');
    final internalKey = dotenv.get('INTERNAL_API_KEY', fallback: '');
    final d = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10)));

    // Interceptor: her isteğe en güncel Supabase access token’ı ekle
    d.interceptors.add(InterceptorsWrapper(onRequest: (o, handler) async {
      final session = Supabase.instance.client.auth.currentSession;
      final accessToken = session?.accessToken;

      if (accessToken != null && accessToken.isNotEmpty) {
        o.headers['Authorization'] = 'Bearer $accessToken';
      }
      if (internalKey.isNotEmpty) {
        o.headers['X-API-Key'] = internalKey; // backend guard
      }
      return handler.next(o);
    }));

    return ApiClient._(d);
  }
}
