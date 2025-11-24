// ignore_for_file: prefer_iterable_wheretype

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/note.dart';

class AISearchRepository {
  final SupabaseClient _client;

  AISearchRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Kurallar:
  /// - query VAR, tag boş → semantic arama
  /// - query VAR, tag VAR → semantic + tag filtreli arama
  /// - query boş, tag VAR → SADECE tag araması
  /// - query boş, tag boş → hata (UI tarafında tutuluyor)
  Future<List<Note>> searchNotes({
    required String queryText,
    String? tagFilter,
    int limit = 20,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('AI arama için oturum açmış kullanıcı bulunamadı.');
    }

    final res = await _client.functions.invoke(
      'ai-search-notes',
      body: <String, dynamic>{
        'query': queryText, // boş string olabilir
        'tag': tagFilter ?? '',
        'limit': limit,
        'user_id': user.id,
      },
    );

    final data = res.data;
    if (data == null) return [];

    if (data is! Map) {
      throw Exception('ai-search-notes invalid response root type');
    }

    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .where((e) => e is Map)
        .cast<Map<String, dynamic>>()
        .toList();

    return items.map(Note.fromJson).toList();
  }
}
