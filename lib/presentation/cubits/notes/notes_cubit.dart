// lib/presentation/cubits/notes/notes_cubit.dart
import 'dart:async';

import 'package:app_to_note/presentation/cubits/offline/offline_queqe_cubit.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/notes_repository.dart';
import '../../../data/services/ai_service.dart';
import '../../../domain/models/note.dart';
import 'notes_state.dart';

class NotesCubit extends HydratedCubit<NotesState> {
  final NotesRepository _repo;
  final OfflineQueueCubit _queue;
  final AIService _ai = AIService();

  RealtimeChannel? _channel;

  int _page = 0;
  final int _pageSize = 25;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  NotesCubit(this._repo, this._queue) : super(const NotesState());

  // ------- UI helpers
  void setQuery(String q) => emit(state.copyWith(query: q));

  void togglePinnedOnly() =>
      emit(state.copyWith(pinnedOnly: !state.pinnedOnly));

  void removeLocal(String id) => emit(
    state.copyWith(notes: state.notes.where((e) => e.id != id).toList()),
  );

  // ------- Seed
  Future<void> seed(int count) async {
    final now = DateTime.now();
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local';
    final List<Note> added = List.generate(count, (i) {
      final id = 'local_${now.microsecondsSinceEpoch}_$i';
      return Note(
        id: id,
        userId: uid,
        title: 'Seed ${i + 1}',
        content: 'demo note $i',
        pinned: false,
        createdAt: now.add(Duration(milliseconds: i)),
        updatedAt: now.add(Duration(milliseconds: i)),
        deletedAt: null,
      );
    });

    final merged = <String, Note>{
      for (final n in [...added, ...state.notes]) n.id: n,
    }.values.toList();
    emit(state.copyWith(notes: merged, status: NotesStatus.ready));

    if (_queue.state.online) {
      for (final n in added) {
        try {
          await _repo.create(title: n.title, content: n.content);
        } catch (_) {}
      }
    } else {
      for (final n in added) {
        _queue.enqueueCreate(title: n.title, content: n.content);
      }
    }
  }

  // ------- Load / Refresh / Pagination
  Future<void> bootstrap() async {
    emit(state.copyWith(status: NotesStatus.loading));
    _page = 0;
    _hasMore = true;
    try {
      final items = await _repo.list(limit: _pageSize, offset: 0);
      _page = 1;
      _hasMore = items.length == _pageSize;
      emit(
        state.copyWith(status: NotesStatus.ready, notes: items, error: null),
      );
      _attachRealtime();
    } catch (e) {
      if (state.notes.isNotEmpty) {
        emit(state.copyWith(status: NotesStatus.ready, error: '$e'));
      } else {
        emit(state.copyWith(status: NotesStatus.error, error: '$e'));
      }
    }
  }

  Future<void> refresh() async {
    try {
      _page = 1;
      final items = await _repo.list(limit: _pageSize, offset: 0);
      _hasMore = items.length == _pageSize;
      emit(
        state.copyWith(status: NotesStatus.ready, notes: items, error: null),
      );
    } catch (e) {
      if (state.notes.isNotEmpty) {
        emit(state.copyWith(status: NotesStatus.ready, error: '$e'));
      } else {
        emit(state.copyWith(status: NotesStatus.error, error: '$e'));
      }
    }
  }

  Future<void> fetchMore() async {
    if (!_hasMore || _isFetchingMore || state.status == NotesStatus.loading) {
      return;
    }
    _isFetchingMore = true;
    try {
      final more = await _repo.list(
        limit: _pageSize,
        offset: _page * _pageSize,
      );
      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _page += 1;
        final mergedMap = <String, Note>{for (final n in state.notes) n.id: n};
        for (final m in more) {
          mergedMap[m.id] = m;
        }
        emit(state.copyWith(notes: mergedMap.values.toList()));
        _hasMore = more.length == _pageSize;
      }
    } catch (_) {
      // offline iken fetchMore denemeyiz
    } finally {
      _isFetchingMore = false;
    }
  }

  // ------- Realtime
  void _attachRealtime() {
    final sb = Supabase.instance.client;
    _channel?.unsubscribe();
    _channel = sb.channel('public:notes');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
          callback: (payload) {
            try {
              final data = payload.newRecord.isNotEmpty
                  ? payload.newRecord
                  : payload.oldRecord;

              final note = Note.fromJson(data);

              var next = List<Note>.from(state.notes);
              final idx = next.indexWhere((n) => n.id == note.id);

              switch (payload.eventType) {
                case PostgresChangeEvent.insert:
                  if (!note.isDeleted) {
                    if (idx >= 0) {
                      next[idx] = note;
                    } else {
                      next = [note, ...next];
                    }
                  }
                  break;
                case PostgresChangeEvent.update:
                  if (note.isDeleted) {
                    if (idx >= 0) next.removeAt(idx);
                  } else {
                    if (idx >= 0) {
                      next[idx] = note;
                    } else {
                      next = [note, ...next];
                    }
                  }
                  break;
                case PostgresChangeEvent.delete:
                  if (idx >= 0) next.removeAt(idx);
                  break;
                default:
                  break;
              }
              final dedup = <String, Note>{
                for (final n in next) n.id: n,
              }.values.toList();
              emit(state.copyWith(notes: dedup));
            } catch (_) {}
          },
        )
        .subscribe();
  }

  Future<void> _runAIForNote(Note base) async {
    try {
      final text = '${base.title}\n\n${base.content}'.trim();
      if (text.isEmpty) return;

      final processed = await _ai.processNote(text);

      await _repo.updateFields(base.id, {
        'ai_summary': processed.summary,
        'ai_tags': processed.tags,
        'ai_meta': processed.aiMeta,
        'ai_embedding': processed.embedding,
      });

      final updated = await _repo.getById(base.id);
      if (updated == null) return;

      final list = state.notes
          .map((n) => n.id == updated.id ? updated : n)
          .toList();
      emit(state.copyWith(notes: list));
    } catch (_) {}
  }

  // ------- CRUD
  Future<void> create(String title, String content) async {
    if (_queue.state.online) {
      final created = await _repo.create(title: title, content: content);

      final base = [created, ...state.notes];
      final merged = <String, Note>{
        for (final n in base) n.id: n,
      }.values.toList();
      emit(state.copyWith(notes: merged));

      unawaited(_runAIForNote(created));
    } else {
      final local = Note(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}',
        userId: Supabase.instance.client.auth.currentUser?.id ?? 'local',
        title: title,
        content: content,
        pinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
      );
      emit(state.copyWith(notes: [local, ...state.notes]));
      _queue.enqueueCreate(title: title, content: content);
    }
  }

  Future<void> update(
    Note n, {
    String? title,
    String? content,
    bool? pinned,
  }) async {
    final next = n.copyWith(
      title: title ?? n.title,
      content: content ?? n.content,
      pinned: pinned ?? n.pinned,
    );

    final bool textChanged =
        (title != null && title != n.title) ||
        (content != null && content != n.content);

    if (_queue.state.online) {
      final saved = await _repo.update(next);

      final replaced = state.notes
          .map((x) => x.id == saved.id ? saved : x)
          .toList();
      emit(state.copyWith(notes: replaced));

      if (textChanged) {
        unawaited(_runAIForNote(saved));
      }
    } else {
      final replaced = state.notes.map((x) => x.id == n.id ? next : x).toList();
      emit(state.copyWith(notes: replaced));
      _queue.enqueueUpdate(
        noteId: n.id,
        title: title,
        content: content,
        pinned: pinned,
      );
    }
  }

  /// SOFT DELETE: Notu Çöp Kutusu'na taşı
  Future<Note?> softDelete(String id) async {
    // 1. Mevcut notu bul
    final existingIndex = state.notes.indexWhere((e) => e.id == id);
    if (existingIndex == -1) {
      return null;
    }
    final existing = state.notes[existingIndex];

    // 2. Optimistic olarak listeden kaldır
    final before = state.notes;
    emit(state.copyWith(notes: before.where((e) => e.id != id).toList()));

    // 3. Online ise RPC ile soft delete, offline ise kuyruğa
    if (_queue.state.online) {
      try {
        final ok = await _repo.softDelete(id);
        if (!ok) {
          // Başarısız → UI'da geri al
          final restored = [existing, ...state.notes];
          emit(state.copyWith(notes: restored));
          return null;
        }
      } catch (_) {
        // Hata → geri al
        final restored = [existing, ...state.notes];
        emit(state.copyWith(notes: restored));
        return null;
      }
    } else {
      _queue.enqueueSoftDelete(noteId: id);
    }

    // 4. Başarılı → TrashPage DB'den deleted_at NOT NULL olarak görecek
    return existing;
  }

  Future<void> restore(String id, {Note? fallback}) async {
    try {
      final ok = await _repo.restore(id);
      if (!ok) return;

      final exists = state.notes.any((e) => e.id == id);
      if (!exists) {
        final fromDb = await _repo.getById(id);
        final back = fromDb ?? fallback;
        if (back != null && !back.isDeleted) {
          final base = [back, ...state.notes];
          final merged = <String, Note>{
            for (final n in base) n.id: n,
          }.values.toList();
          emit(state.copyWith(notes: merged));
        }
      }
    } catch (_) {}
  }

  Future<void> clearForSignOut() async {
    _channel?.unsubscribe();
    _channel = null;
    emit(const NotesState());
  }

  @override
  Future<void> close() {
    _channel?.unsubscribe();
    return super.close();
  }

  // ------- Hydrated
  @override
  NotesState? fromJson(Map<String, dynamic> json) {
    try {
      final List<Note> list = (json['notes'] as List<dynamic>? ?? [])
          .map(
            (e) => Note(
              id: e['id'] as String,
              userId: e['user_id'] as String,
              title: e['title'] as String? ?? '',
              content: e['content'] as String? ?? '',
              pinned: e['pinned'] as bool? ?? false,
              createdAt: DateTime.parse(e['created_at'] as String),
              updatedAt: DateTime.parse(e['updated_at'] as String),
              deletedAt: (e['deleted_at'] as String?) != null
                  ? DateTime.parse(e['deleted_at'] as String)
                  : null,
              aiSummary: e['ai_summary'] as String?,
              aiTags: (e['ai_tags'] as List<dynamic>? ?? const [])
                  .map((t) => t.toString())
                  .toList(),
              aiMeta: e['ai_meta'] is Map<String, dynamic>
                  ? e['ai_meta'] as Map<String, dynamic>
                  : <String, dynamic>{},
            ),
          )
          .toList();

      return NotesState(
        status: NotesStatus.values[json['status'] as int? ?? 0],
        notes: list,
        error: json['error'] as String?,
        query: json['query'] as String? ?? '',
        pinnedOnly: json['pinnedOnly'] as bool? ?? false,
      );
    } catch (_) {
      return const NotesState();
    }
  }

  @override
  Map<String, dynamic>? toJson(NotesState state) => {
    'status': state.status.index,
    'notes': state.notes
        .map(
          (n) => {
            'id': n.id,
            'user_id': n.userId,
            'title': n.title,
            'content': n.content,
            'pinned': n.pinned,
            'created_at': n.createdAt.toIso8601String(),
            'updated_at': n.updatedAt.toIso8601String(),
            'deleted_at': n.deletedAt?.toIso8601String(),
            'ai_summary': n.aiSummary,
            'ai_tags': n.aiTags,
            'ai_meta': n.aiMeta,
          },
        )
        .toList(),
    'error': state.error,
    'query': state.query,
    'pinnedOnly': state.pinnedOnly,
  };
}
