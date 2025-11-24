import 'package:equatable/equatable.dart';
import '../../../domain/models/note.dart';

enum TrashStatus { idle, loading, ready, error }

class TrashState extends Equatable {
  final TrashStatus status;
  final List<Note> items;
  final String? error;
  final String query;

  // pagination
  final bool isFetchingMore;
  final bool hasMore;

  const TrashState({
    this.status = TrashStatus.idle,
    this.items = const [],
    this.error,
    this.query = '',
    this.isFetchingMore = false,
    this.hasMore = true,
  });

  TrashState copyWith({
    TrashStatus? status,
    List<Note>? items,
    String? error,
    String? query,
    bool? isFetchingMore,
    bool? hasMore,
  }) {
    return TrashState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error,
      query: query ?? this.query,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  List<Note> get visible {
    final q = query.trim().toLowerCase();
    final out = items.where((n) {
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
    return out;
  }

  @override
  List<Object?> get props => [status, items, error, query, isFetchingMore, hasMore];
}
