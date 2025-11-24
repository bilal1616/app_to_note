import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackendApi {
  BackendApi._();
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.get('BACKEND_BASE_URL'),
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  /// Supabase JWT + X-API-Key header’larını ekle
  static Future<Response<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    final supaJwt = session?.accessToken;
    final key = dotenv.get('INTERNAL_API_KEY', fallback: '');
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: query,
      options: Options(headers: {
        if (supaJwt != null) 'Authorization': 'Bearer $supaJwt',
        if (key.isNotEmpty) 'X-API-Key': key,
      }),
    );
  }

  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    final supaJwt = session?.accessToken;
    final key = dotenv.get('INTERNAL_API_KEY', fallback: '');
    return _dio.get<T>(
      path,
      queryParameters: query,
      options: Options(headers: {
        if (supaJwt != null) 'Authorization': 'Bearer $supaJwt',
        if (key.isNotEmpty) 'X-API-Key': key,
      }),
    );
  }
}
