import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/notes_repository.dart';
import '../../../domain/models/note.dart';
import 'trash_state.dart';

class TrashCubit extends Cubit<TrashState> {
  final NotesRepository _repo;
  static const int _pageSize = 20;
  int _offset = 0;

  TrashCubit(this._repo) : super(const TrashState());

  void setQuery(String q) => emit(state.copyWith(query: q));

  Future<void> bootstrap() async {
    emit(state.copyWith(status: TrashStatus.loading, hasMore: true));
    try {
      _offset = 0;
      final page = await _repo.listTrashed(limit: _pageSize, offset: _offset);
      _offset += page.length;
      emit(state.copyWith(
        status: TrashStatus.ready,
        items: page,
        hasMore: page.length == _pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(status: TrashStatus.error, error: '$e'));
    }
  }

  Future<void> refresh() async => bootstrap();

  Future<void> fetchMore() async {
    if (state.isFetchingMore || !state.hasMore) return;
    emit(state.copyWith(isFetchingMore: true));
    try {
      final page = await _repo.listTrashed(limit: _pageSize, offset: _offset);
      _offset += page.length;

      final byId = {for (final n in state.items) n.id: n};
      for (final n in page) {
        byId[n.id] = n;
      }
      final merged = byId.values.toList();

      emit(state.copyWith(
        items: merged,
        isFetchingMore: false,
        hasMore: page.length == _pageSize,
      ));
    } catch (_) {
      emit(state.copyWith(isFetchingMore: false));
    }
  }

  Future<void> restore(Note n) async {
    final ok = await _repo.restore(n.id);
    if (ok) {
      emit(state.copyWith(items: state.items.where((x) => x.id != n.id).toList()));
    }
  }

  Future<void> hardDelete(Note n) async {
    final ok = await _repo.hardDelete(n.id);
    if (ok) {
      emit(state.copyWith(items: state.items.where((x) => x.id != n.id).toList()));
    }
  }

  /// Toplu kalıcı silme (RPC yoksa tek tek siler)
  Future<void> emptyTrash() async {
    if (state.items.isEmpty) return;
    // İsteğe bağlı: küçük bir optimistik boşaltma
    final prev = state.items;
    emit(state.copyWith(items: []));
    try {
      for (final n in prev) {
        await _repo.hardDelete(n.id);
      }
      // bitti
    } catch (e) {
      // hata olursa geri yükle
      emit(state.copyWith(items: prev, error: '$e'));
    }
  }
}
