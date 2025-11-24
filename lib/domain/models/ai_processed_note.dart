// lib/domain/models/ai_processed_note.dart

class AIProcessedNote {
  /// Kısa özet (UI'de kart üstünde gösteriyoruz)
  final String summary;

  /// Önerilen etiketler
  final List<String> tags;

  /// AI meta bilgisi (keywords, sentiment, importance vs.)
  final Map<String, dynamic> aiMeta;

  /// Embedding vektörü (semantic search vs. için)
  final List<double> embedding;

  /// Kullanıcıya sunulacak TAM düzenlenmiş içerik / öneri metni.
  /// - Madde madde notlar varsa toparlanmış ve düzeltilmiş versiyon
  /// - İçerik boş, sadece başlık varsa başlığa göre üretilmiş metin
  final String? suggestedContent;

  const AIProcessedNote({
    required this.summary,
    required this.tags,
    required this.aiMeta,
    required this.embedding,
    this.suggestedContent,
  });

  factory AIProcessedNote.fromJson(Map<String, dynamic> json) {
    final meta =
        (json['ai_meta'] as Map<String, dynamic>? ?? <String, dynamic>{});

    // Edge function sadece ai_meta.suggested_content döndürüyor,
    // ama ileride top-level suggested_content gelirse onu da destekleyelim.
    final String? suggested =
        (json['suggested_content'] as String?) ??
        (meta['suggested_content'] as String?);

    return AIProcessedNote(
      summary: (json['summary'] as String?) ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      aiMeta: meta,
      embedding: (json['embedding'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(),
      suggestedContent: suggested,
    );
  }
}
