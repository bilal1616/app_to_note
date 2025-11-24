import 'dart:convert';

enum OfflineOp { create, update, softDelete }

class OfflineTask {
  final String id;               // uuid v4
  final OfflineOp op;
  final DateTime createdAt;
  final int retries;

  // payload
  final String? noteId;          // update/softDelete için
  final String? title;           // create/update için
  final String? content;         // create/update için
  final bool? pinned;            // update için

  const OfflineTask({
    required this.id,
    required this.op,
    required this.createdAt,
    this.retries = 0,
    this.noteId,
    this.title,
    this.content,
    this.pinned,
  });

  OfflineTask copyWith({int? retries}) =>
      OfflineTask(
        id: id,
        op: op,
        createdAt: createdAt,
        retries: retries ?? this.retries,
        noteId: noteId,
        title: title,
        content: content,
        pinned: pinned,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'op': op.name,
    'createdAt': createdAt.toIso8601String(),
    'retries': retries,
    'noteId': noteId,
    'title': title,
    'content': content,
    'pinned': pinned,
  };

  static OfflineTask fromJson(Map<String, dynamic> j) => OfflineTask(
    id: j['id'] as String,
    op: OfflineOp.values.firstWhere((e) => e.name == j['op']),
    createdAt: DateTime.parse(j['createdAt'] as String),
    retries: (j['retries'] ?? 0) as int,
    noteId: j['noteId'] as String?,
    title: j['title'] as String?,
    content: j['content'] as String?,
    pinned: j['pinned'] as bool?,
  );

  @override
  String toString() => jsonEncode(toJson());
}
