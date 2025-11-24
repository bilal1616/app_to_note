// lib/presentation/pages/trash/trash_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../domain/models/note.dart';

class TrashCard extends StatelessWidget {
  final Note note;

  // seçim modu API
  final bool selectMode;
  final bool selected;
  final VoidCallback onLongPressSelect;
  final VoidCallback onToggleSelect;

  // aksiyonlar
  final VoidCallback onRestore;
  final VoidCallback onHardDelete;

  const TrashCard({
    super.key,
    required this.note,
    required this.selectMode,
    required this.selected,
    required this.onLongPressSelect,
    required this.onToggleSelect,
    required this.onRestore,
    required this.onHardDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // NoteCard’daki cam efektine yakın arka plan
    final glassColor = isDark
        ? const Color.fromARGB(255, 207, 207, 207)
        : Colors.white70;

    // --- AI alanları / özet & tag’ler ---
    final hasAiSummary =
        note.aiSummary != null && note.aiSummary!.trim().isNotEmpty;
    final previewText = hasAiSummary
        ? note.aiSummary!.trim()
        : note.content.trim();
    final tags = note.aiTags;

    final meta = note.aiMeta ?? {};
    final String? aiMode = meta['mode'] as String?;
    final String? sentiment = meta['sentiment'] as String?;

    // Sentiment rozeti
    Color? sentimentColor;
    String? sentimentLabel;
    if (sentiment != null) {
      switch (sentiment.toLowerCase()) {
        case 'positive':
        case 'pozitif':
          sentimentColor = Colors.green;
          sentimentLabel = 'Pozitif';
          break;
        case 'negative':
        case 'negatif':
          sentimentColor = Colors.redAccent;
          sentimentLabel = 'Negatif';
          break;
        default:
          sentimentColor = Colors.blueGrey;
          sentimentLabel = 'Nötr';
      }
    }

    // AI mode label
    String? aiModeLabel;
    if (aiMode != null && aiMode.isNotEmpty) {
      switch (aiMode) {
        case 'suggest_fix':
          aiModeLabel = 'Düzenleme önerisi';
          break;
        case 'auto_expand':
          aiModeLabel = 'Genişletilmiş içerik';
          break;
        case 'title_only':
          aiModeLabel = 'Başlıktan oluşturuldu';
          break;
        default:
          aiModeLabel = null;
      }
    }

    // Devamını gör gösterilsin mi? (basit karakter sayısı heuristiği)
    final bool showReadMore = previewText.length > 140;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: glassColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CONTENT TARAFI
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? '(untitled)' : note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // AI özeti + sentiment + mode chipleri
                  if (hasAiSummary ||
                      sentimentLabel != null ||
                      aiModeLabel != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasAiSummary) ...[
                          Icon(
                            Icons.bolt,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI özeti',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (sentimentLabel != null &&
                            sentimentColor != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: sentimentColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: sentimentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sentimentLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: sentimentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (aiModeLabel != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              aiModeLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                  if (hasAiSummary ||
                      sentimentLabel != null ||
                      aiModeLabel != null)
                    const SizedBox(height: 6),

                  // Özet / içerik preview
                  Text(
                    previewText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: hasAiSummary
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: hasAiSummary ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Devamını gör
                  if (showReadMore) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: selectMode
                            ? null
                            : () => _showTrashNotePreviewBottomSheet(
                                context,
                                note,
                              ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Devamını gör'),
                      ),
                    ),
                  ],

                  // Tag chipleri
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags.take(4).map((t) {
                        return Chip(
                          label: Text(t, style: theme.textTheme.labelSmall),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 0,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: colorScheme.secondary.withOpacity(
                            0.06,
                          ),
                          side: BorderSide(
                            color: colorScheme.secondary.withOpacity(0.18),
                            width: 0.6,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // SAĞ AKSİYON BUTONLARI (restore / kalıcı sil)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    iconSize: 20,
                    icon: const Icon(Icons.restore),
                    tooltip: 'Geri Yükle',
                    onPressed: selectMode ? null : onRestore,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    iconSize: 20,
                    icon: const Icon(Icons.delete_forever_outlined),
                    tooltip: 'Kalıcı olarak sil',
                    onPressed: selectMode ? null : onHardDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onLongPress: onLongPressSelect,
      onTap: selectMode ? onToggleSelect : null,
      child: Stack(
        children: [
          card,
          if (selectMode && selected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.check_circle, size: 20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Çöp kutusundaki not için tam metin önizleme bottom sheet’i.
Future<void> _showTrashNotePreviewBottomSheet(BuildContext context, Note note) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  final fullText = (note.aiSummary != null && note.aiSummary!.trim().isNotEmpty)
      ? note.aiSummary!.trim()
      : note.content.trim();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.55, // ⬅️ Başlangıçta yarım ekran
        minChildSize: 0.40, // ⬅️ Daha da küçülebilir
        maxChildSize: 0.95, // ⬅️ Neredeyse tam ekran açılabilir
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cs.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title + Close
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? '(untitled)' : note.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Kapat',
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // AI Summary label
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bolt, size: 18, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'AI özeti (tam metin)',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Scrollable content (controller bağlı)
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Text(fullText, style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
