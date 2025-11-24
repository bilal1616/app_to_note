import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/note.dart';

class NotesRepository {
  final SupabaseClient client;
  NotesRepository(this.client);

  Future<List<Note>> list({int limit = 100, int offset = 0}) async {
    final rows = await client
        .from('notes')
        .select()
        .isFilter('deleted_at', null)
        .order('pinned', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map((e) => Note.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Note>> listTrashed({int limit = 100, int offset = 0}) async {
    final rows = await client
        .from('notes')
        .select()
        .not('deleted_at', 'is', null)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map((e) => Note.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Note?> getById(String id) async {
    final row = await client.from('notes').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Note.fromJson(row);
  }

  Future<Note> create({required String title, required String content}) async {
    final uid = client.auth.currentUser!.id;
    final res = await client
        .from('notes')
        .insert({'title': title, 'content': content, 'user_id': uid})
        .select()
        .single();
    return Note.fromJson(res);
  }

  Future<Note> update(Note n) async {
    final res = await client
        .from('notes')
        .update({
          'title': n.title,
          'content': n.content,
          'pinned': n.pinned,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'ai_summary': n.aiSummary,
          'ai_tags': n.aiTags,
          'ai_meta': n.aiMeta,
        })
        .eq('id', n.id)
        .select()
        .single();
    return Note.fromJson(res);
  }

  Future<void> updateFields(String id, Map<String, dynamic> fields) async {
    await client.from('notes').update(fields).eq('id', id);
  }

  /// Çöpe at (soft delete)
  Future<bool> softDelete(String id) async {
    final ok =
        await client.rpc('notes_soft_delete', params: {'_note_id': id})
            as bool?;
    return ok ?? false;
  }

  /// Çöpten geri al
  Future<bool> restore(String id) async {
    final ok =
        await client.rpc('notes_restore', params: {'_note_id': id}) as bool?;
    return ok ?? false;
  }

  /// Çöpten kalıcı sil
  Future<bool> hardDelete(String id) async {
    final ok =
        await client.rpc('notes_hard_delete', params: {'_note_id': id})
            as bool?;
    return ok ?? false;
  }

  Future<void> updateAIFields({
    required String id,
    required String summary,
    required List<String> tags,
    required Map<String, dynamic> meta,
    required List<double> embedding,
  }) async {
    await updateFields(id, {
      'ai_summary': summary,
      'ai_tags': tags,
      'ai_meta': meta,
      'ai_embedding': embedding,
    });
  }
}
