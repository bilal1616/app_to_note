// lib/presentation/cubits/offline/offline_queqe_cubit.dart
import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../../data/repositories/notes_repository.dart';
import 'offline_queqe_state.dart';

class OfflineQueueCubit extends HydratedCubit<OfflineQueueState> {
  final NotesRepository _repo;
  OfflineQueueCubit(this._repo) : super(const OfflineQueueState());

  void setOnline(bool online) => emit(state.copyWith(online: online));

  // ---- Enqueue API
  void enqueueCreate({required String title, required String content}) {
    final next = List<OfflineAction>.from(state.queue)
      ..add(
        OfflineAction(
          type: OfflineActionType.create,
          payload: {'title': title, 'content': content},
        ),
      );
    emit(state.copyWith(queue: next));
  }

  void enqueueUpdate({
    required String noteId,
    String? title,
    String? content,
    bool? pinned,
  }) {
    final payload = <String, dynamic>{'noteId': noteId};
    if (title != null) payload['title'] = title;
    if (content != null) payload['content'] = content;
    if (pinned != null) payload['pinned'] = pinned;

    final next = List<OfflineAction>.from(state.queue)
      ..add(OfflineAction(type: OfflineActionType.update, payload: payload));
    emit(state.copyWith(queue: next));
  }

  void enqueueSoftDelete({required String noteId}) {
    final next = List<OfflineAction>.from(state.queue)
      ..add(
        OfflineAction(
          type: OfflineActionType.softDelete,
          payload: {'noteId': noteId},
        ),
      );
    emit(state.copyWith(queue: next));
  }

  /// Online olunca tüm kuyruğu çalıştır — parametresiz çağrılabilir ✅
  Future<void> processAll([NotesRepository? repo]) async {
    final r = repo ?? _repo;
    if (!state.online || state.queue.isEmpty) return;

    final work = List<OfflineAction>.from(state.queue);
    for (final a in work) {
      try {
        switch (a.type) {
          case OfflineActionType.create:
            await r.create(
              title: a.payload['title'] as String,
              content: a.payload['content'] as String,
            );
            break;

          case OfflineActionType.update:
            final id = a.payload['noteId'] as String;
            final fields = <String, dynamic>{};
            if (a.payload.containsKey('title')) {
              fields['title'] = a.payload['title'];
            }
            if (a.payload.containsKey('content')) {
              fields['content'] = a.payload['content'];
            }
            if (a.payload.containsKey('pinned')) {
              fields['pinned'] = a.payload['pinned'];
            }
            if (fields.isNotEmpty) {
              fields['updated_at'] = DateTime.now().toUtc().toIso8601String();
              await r.updateFields(id, fields);
            }
            break;

          case OfflineActionType.softDelete:
            final id = a.payload['noteId'] as String;
            await r.softDelete(id);
            break;
        }

        // Başarılı → kuyruğun başındakini düş
        final left = List<OfflineAction>.from(state.queue)..removeAt(0);
        emit(state.copyWith(queue: left));
      } catch (_) {
        // Hata olursa bırak; sonra tekrar denenecek
        break;
      }
    }
  }

  // Hydrated (state kısmın zaten ayrı dosyada)
  @override
  OfflineQueueState? fromJson(Map<String, dynamic> json) =>
      OfflineQueueState.fromJson(json);
  @override
  Map<String, dynamic>? toJson(OfflineQueueState state) => state.toJson();
}
