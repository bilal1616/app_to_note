import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String content;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // 🔹 AI alanları
  final String? aiSummary; // Kısa özet (ai_summary)
  final List<String> aiTags; // Etiketler (ai_tags)
  final Map<String, dynamic>? aiMeta; // Ek metadata (ai_meta)

  const Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.pinned,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    this.aiSummary,
    this.aiTags = const [],
    this.aiMeta,
  });

  bool get isDeleted => deletedAt != null;

  factory Note.fromJson(Map<String, dynamic> m) {
    return Note(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      title: (m['title'] ?? '') as String,
      content: (m['content'] ?? '') as String,
      pinned: (m['pinned'] ?? false) as bool,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
      deletedAt: m['deleted_at'] == null
          ? null
          : DateTime.parse(m['deleted_at'] as String),

      // 🔹 Supabase kolon adları ile eşleştir
      aiSummary: m['ai_summary'] as String?,
      aiTags:
          (m['ai_tags'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      aiMeta: m['ai_meta'] is Map<String, dynamic>
          ? m['ai_meta'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'user_id': userId,
    'title': title,
    'content': content,
    'pinned': pinned,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),

    // 🔹 AI alanları
    'ai_summary': aiSummary,
    'ai_tags': aiTags,
    'ai_meta': aiMeta,
  };

  Note copyWith({
    String? title,
    String? content,
    bool? pinned,
    DateTime? updatedAt,
    DateTime? deletedAt,

    // 🔹 AI için copyWith alanları
    String? aiSummary,
    List<String>? aiTags,
    Map<String, dynamic>? aiMeta,
  }) {
    return Note(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      aiSummary: aiSummary ?? this.aiSummary,
      aiTags: aiTags ?? this.aiTags,
      aiMeta: aiMeta ?? this.aiMeta,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    title,
    content,
    pinned,
    createdAt,
    updatedAt,
    deletedAt,
    aiSummary,
    aiTags,
    aiMeta,
  ];
}
