import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env.dart';

class DioClient {
  DioClient._();
  static final DioClient _i = DioClient._();
  factory DioClient() => _i;

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: Env.backendBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': Env.internalApiKey,
      },
    ),
  )..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Supabase session token'ı Authorization header’a ekle
        final session = Supabase.instance.client.auth.currentSession;
        final tok = session?.accessToken;
        if (tok != null && tok.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $tok';
        }
        handler.next(options);
      },
    ));
}
