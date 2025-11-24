import 'package:equatable/equatable.dart';
import '../../../domain/models/note.dart';

enum NotesStatus { idle, loading, ready, error }

class NotesState extends Equatable {
  final NotesStatus status;
  final List<Note> notes; // server + cache
  final String? error;

  // Filtreler
  final String query;
  final bool pinnedOnly;

  const NotesState({
    this.status = NotesStatus.idle,
    this.notes = const [],
    this.error,
    this.query = '',
    this.pinnedOnly = false,
  });

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? notes,
    String? error,
    String? query,
    bool? pinnedOnly,
  }) =>
      NotesState(
        status: status ?? this.status,
        notes: notes ?? this.notes,
        error: error,
        query: query ?? this.query,
        pinnedOnly: pinnedOnly ?? this.pinnedOnly,
      );

  List<Note> get visibleNotes {
    final q = query.trim().toLowerCase();
    final filtered = notes.where((n) {
      if (pinnedOnly && !n.pinned) return false;
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q);
    }).toList();

    filtered.sort((a, b) {
      if (a.pinned == b.pinned) {
        return b.createdAt.compareTo(a.createdAt);
      }
      return a.pinned ? -1 : 1;
    });
    return filtered;
  }

  // ---- Hydrated serialization ----
  factory NotesState.fromMap(Map<String, dynamic> map) {
    return NotesState(
      status: NotesStatus.values[map['status'] as int],
      notes: (map['notes'] as List).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList(),
      error: map['error'] as String?,
      query: (map['query'] ?? '') as String,
      pinnedOnly: (map['pinnedOnly'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.index,
        'notes': notes.map((e) => e.toJson()).toList(),
        'error': error,
        'query': query,
        'pinnedOnly': pinnedOnly,
      };

  @override
  List<Object?> get props => [status, notes, error, query, pinnedOnly];
}
