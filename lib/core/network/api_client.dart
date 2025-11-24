import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/env.dart';

class ApiClient {
  ApiClient._();
  static final Dio dio = Dio(BaseOptions(
    baseUrl: Env.backendBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'X-API-Key': Env.internalApiKey},
  ))
    ..interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) async {
        final session = Supabase.instance.client.auth.currentSession;
        final tok = session?.accessToken;
        if (tok != null && tok.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $tok';
        }
        handler.next(options);
      }),
    );
}
