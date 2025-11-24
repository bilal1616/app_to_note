// lib/presentation/pages/notes/note_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../domain/models/note.dart';
import 'note_editor_sheet.dart'; // <-- bottom sheet UI'yi kullan

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inDays >= 1) return '${diff.inDays}d';
  if (diff.inHours >= 1) return '${diff.inHours}h';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
  return 'now';
}

class NoteCard extends StatefulWidget {
  final Note note;
  final bool selectMode;
  final bool selected;
  final VoidCallback onLongPressSelect;
  final VoidCallback onToggleSelect;
  final ValueChanged<bool> onUpdatePinned;
  final VoidCallback onDelete;
  final Future<void> Function(String, String)? onEdit;

  const NoteCard({
    super.key,
    required this.note,
    required this.selectMode,
    required this.selected,
    required this.onLongPressSelect,
    required this.onToggleSelect,
    required this.onUpdatePinned,
    required this.onDelete,
    this.onEdit,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d) => _anim.forward();
  void _onTapUp(TapUpDetails d) => _anim.reverse();
  void _onTapCancel() => _anim.reverse();

  Future<void> _confirmAndDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: const Text('Not çöp kutusuna taşınacak. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) widget.onDelete();
  }

  // --- YENİ: Tam metni tam ekran alt sayfada gösteren helper ---
  void _showFullTextSheet({
    required String title,
    required String fullText,
    required bool isAiSummary,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
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
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // drag handle
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title.isEmpty ? '(untitled)' : title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    if (isAiSummary)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bolt, size: 16, color: cs.primary),
                            const SizedBox(width: 6),
                            Text(
                              'AI özeti (tam metin)',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    const Divider(height: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Text(
                            fullText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final n = widget.note;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color.fromARGB(255, 207, 207, 207)
        : Colors.white70;
    final scale = 1.0 - _anim.value;

    // ---- AI alanları ----
    final hasAiSummary = n.aiSummary != null && n.aiSummary!.trim().isNotEmpty;

    // Tam metin (AI özeti varsa onu kullan, yoksa not içeriği)
    final String fullText = hasAiSummary
        ? n.aiSummary!.trim()
        : n.content.trim();

    // Kart içinde gösterilen preview metni
    final previewText = fullText;

    // preview çok uzunsa "Devamını gör" göstereceğiz
    final bool canShowReadMore =
        fullText.length > 140 || '\n'.allMatches(fullText).length >= 2;

    final tags = n.aiTags;

    // ai_meta içinden ekstra alanlar
    final meta = n.aiMeta ?? {};
    final String? aiMode = meta['mode'] as String?;
    final String? suggestedContent = meta['suggested_content'] as String?;

    // Sentiment rozeti için basit mapping
    final sentiment = n.aiMeta?['sentiment'] as String?;
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

    // mode için ufak bir label (görsel bilgi)
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

    Widget card = Transform.scale(
      scale: scale,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (n.pinned)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Chip(
                          label: Text(
                            'Sabitlendi',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          avatar: Icon(
                            Icons.push_pin,
                            size: 16,
                            color: colorScheme.onPrimary,
                          ),
                          backgroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 0,
                          ),
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.title.isEmpty ? '(untitled)' : n.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(n.updatedAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // AI özeti etiketi + sentiment + mode etiketi
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

                    // Özet veya içerik preview
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

                    // --- YENİ: Devamını gör butonu ---
                    if (canShowReadMore)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showFullTextSheet(
                            title: n.title,
                            fullText: fullText,
                            isAiSummary: hasAiSummary,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Devamını gör'),
                        ),
                      ),

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

                    // --- AI ÖNERİSİNİ UYGULA BUTONU ---
                    if (suggestedContent != null &&
                        suggestedContent.isNotEmpty &&
                        widget.onEdit != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.auto_fix_high, size: 18),
                          label: const Text('AI önerisini uygula'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            textStyle: theme.textTheme.labelLarge,
                          ),
                          onPressed: () async {
                            // Başlık aynı kalsın, içerik AI'ın önerdiği tam metin olsun
                            await widget.onEdit!(n.title, suggestedContent);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                      icon: Icon(
                        n.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                      ),
                      tooltip: n.pinned ? 'Sabitlemeyi kaldır' : 'Sabitle',
                      onPressed: () => widget.onUpdatePinned(!n.pinned),
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
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Sil',
                      onPressed: _confirmAndDelete,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.selectMode
          ? widget.onToggleSelect
          : () async {
              // NOT DÜZENLE → Artık aynı bottom sheet UI
              if (widget.onEdit != null) {
                final res = await showNoteEditorBottomSheet(
                  context,
                  initialTitle: n.title,
                  initialContent: n.content,
                );
                if (res != null) {
                  await widget.onEdit!(res.$1, res.$2);
                }
              }
            },
      onLongPress: widget.onLongPressSelect,
      child: Stack(
        children: [
          card,
          if (widget.selectMode && widget.selected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 2.0,
                      horizontal: 11.0,
                    ),
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
