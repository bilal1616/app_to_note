// lib/data/services/ai_service.dart
// ignore_for_file: unnecessary_import

import 'package:functions_client/functions_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/ai_processed_note.dart';

class AIService {
  final FunctionsClient _functions;

  AIService({FunctionsClient? functions})
    : _functions = functions ?? Supabase.instance.client.functions;

  /// Eski sade kullanım: sadece text ver
  Future<AIProcessedNote> processNote(String text) async {
    return processNoteWithContext(title: '', content: text, mode: 'auto');
  }

  /// Yeni: başlık + içerik + mod ile not analizi
  Future<AIProcessedNote> processNoteWithContext({
    required String title,
    required String content,
    String mode = 'auto',
  }) async {
    final Map<String, dynamic> body = {
      'title': title,
      'content': content,
      'mode': mode,
    };

    final res = await _functions.invoke(
      'ai-process-note',
      method: HttpMethod.post,
      body: body,
    );

    if (res.data == null) {
      throw Exception('ai-process-note returned no data');
    }

    if (res.data is! Map<String, dynamic>) {
      throw Exception('ai-process-note invalid response type');
    }

    return AIProcessedNote.fromJson(res.data as Map<String, dynamic>);
  }

  /// 🔍 Semantic search için: metni embed'e çevir
  Future<List<double>> embedTextForSearch(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Sorgu metni boş olamaz');
    }

    final res = await _functions.invoke(
      'ai-embed-text',
      method: HttpMethod.post,
      body: {'text': trimmed},
    );

    if (res.data == null) {
      throw Exception('ai-embed-text returned no data');
    }

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('ai-embed-text invalid response type');
    }

    final raw = data['embedding'];
    if (raw is! List) {
      throw Exception('ai-embed-text response has no embedding list');
    }

    return raw.map((e) => (e as num).toDouble()).toList(growable: false);
  }
}
