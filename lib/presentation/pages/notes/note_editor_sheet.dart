// lib/presentation/pages/notes/note_editor_sheet.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../data/services/ai_service.dart';
import '../../../domain/models/ai_processed_note.dart';

/// Not oluşturma / düzenleme için full-screen bottom sheet + AI desteği.
/// DÖNÜŞ: (title, content)
Future<(String, String)?> showNoteEditorBottomSheet(
  BuildContext context, {
  String initialTitle = '',
  String initialContent = '',
}) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _NoteEditorSheet(
        initialTitle: initialTitle,
        initialContent: initialContent,
      );
    },
  );
}

class _NoteEditorSheet extends StatefulWidget {
  final String initialTitle;
  final String initialContent;

  const _NoteEditorSheet({
    required this.initialTitle,
    required this.initialContent,
  });

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  final _formKey = GlobalKey<FormState>();

  AIProcessedNote? _aiPreview;
  bool _loadingAi = false;
  String? _aiError;

  /// 'auto' | 'enhance' | 'list' | 'from_title'
  String _aiMode = 'auto';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _contentCtrl = TextEditingController(text: widget.initialContent);

    // Başlık / içerik değişince X ve çöp ikonlarının enable/disable olması için
    _titleCtrl.addListener(_onTextChanged);
    _contentCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTextChanged);
    _contentCtrl.removeListener(_onTextChanged);
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {
      // sadece ikonların görünürlüğü için rebuild
    });
  }

  Future<void> _clearTitle() async {
    if (_titleCtrl.text.isEmpty) return;
    _titleCtrl.clear();
  }

  Future<void> _clearContentWithConfirm() async {
    if (_contentCtrl.text.trim().isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('İçerik silinsin mi?'),
        content: const Text(
          'Bu notun içeriği tamamen silinecek. Bu içeriği silmek ister misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok == true) {
      _contentCtrl.clear();
    }
  }

  Future<void> _runAiSuggestion() async {
    final rawTitle = _titleCtrl.text.trim();
    final rawContent = _contentCtrl.text.trim();

    String titleForSend = rawTitle;
    String contentForSend = rawContent;

    if (_aiMode == 'from_title') {
      // Başlığa göre metin üretme modu
      contentForSend = '';
    }

    if (titleForSend.isEmpty && contentForSend.isEmpty) {
      setState(() {
        _aiError =
            'AI önerisi için en az başlık veya içerikten birini girmen gerekiyor.';
        _aiPreview = null;
      });
      return;
    }

    setState(() {
      _loadingAi = true;
      _aiError = null;
    });

    try {
      final service = AIService();
      final res = await service.processNoteWithContext(
        title: titleForSend,
        content: contentForSend,
        mode: _aiMode,
      );
      setState(() {
        _aiPreview = res;
      });
    } catch (e) {
      setState(() {
        _aiError = 'AI isteği başarısız oldu: $e';
        _aiPreview = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingAi = false;
        });
      }
    }
  }

  void _applyAiToContent() {
    final p = _aiPreview;
    if (p == null) return;

    // 1. Tercihen backend'in gönderdiği tam düzenlenmiş içerik
    final suggested = p.suggestedContent?.trim();
    if (suggested != null && suggested.isNotEmpty) {
      _contentCtrl.text = suggested;
      _contentCtrl.selection = TextSelection.collapsed(
        offset: suggested.length,
      );
      return;
    }

    // 2. Fallback: Eski davranış – özet + etiketler metne eklenir
    final current = _contentCtrl.text.trim();
    final buffer = StringBuffer();
    if (current.isNotEmpty) {
      buffer.writeln(current);
      buffer.writeln();
    }
    buffer.writeln('---');
    if (p.summary.isNotEmpty) {
      buffer.writeln('AI özeti: ${p.summary}');
    }
    if (p.tags.isNotEmpty) {
      buffer.writeln('AI etiketleri: ${p.tags.join(', ')}');
    }
    _contentCtrl.text = buffer.toString();
  }

  /// ------- Yeni: AI ile başlık üret / kısa özet ekle -------

  /// AI’dan gelen preview yoksa önce _runAiSuggestion çalıştırır,
  /// sonra başlık alanını doldurur.
  Future<void> _generateTitleWithAi() async {
    if (_aiPreview == null) {
      await _runAiSuggestion();
    }
    if (!mounted) return;
    final p = _aiPreview;
    if (p == null) return;

    String? suggestedTitle;

    // 1) aiMeta.suggested_title varsa onu kullan
    final metaTitle = p.aiMeta['suggested_title'];
    if (metaTitle is String && metaTitle.trim().isNotEmpty) {
      suggestedTitle = metaTitle.trim();
    }

    // 2) Yoksa özetin ilk cümlesinden kısa bir başlık çıkar
    if ((suggestedTitle == null || suggestedTitle.isEmpty) &&
        p.summary.isNotEmpty) {
      var s = p.summary.trim();
      final dotIndex = s.indexOf('.');
      if (dotIndex > 0 && dotIndex < 80) {
        s = s.substring(0, dotIndex);
      }
      if (s.length > 80) {
        s = s.substring(0, 80);
      }
      suggestedTitle = s.trim();
    }

    if (suggestedTitle == null || suggestedTitle.isEmpty) {
      return;
    }

    _titleCtrl.text = suggestedTitle;
    _titleCtrl.selection =
        TextSelection.collapsed(offset: suggestedTitle.length);
  }

  /// AI özetini içerik alanının başına ekler.
  Future<void> _insertSummaryWithAi() async {
    if (_aiPreview == null) {
      await _runAiSuggestion();
    }
    if (!mounted) return;
    final p = _aiPreview;
    if (p == null || p.summary.isEmpty) return;

    final current = _contentCtrl.text.trim();
    final buffer = StringBuffer();

    buffer.writeln('Özet: ${p.summary}');
    if (current.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(current);
    }

    final text = buffer.toString();
    _contentCtrl.text = text;
    _contentCtrl.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    final isEdit =
        widget.initialTitle.isNotEmpty || widget.initialContent.isNotEmpty;

    // AI meta'dan keywords çek (varsa)
    final keywords =
        (_aiPreview?.aiMeta['keywords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final modeLabels = <String, String>{
      'auto': 'Otomatik',
      'enhance': 'Düzenle',
      'list': 'Liste',
      'from_title': 'Başlıktan',
    };

    const sheetRadius = Radius.circular(26);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outline.withOpacity(0.4), width: 1),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: sheetRadius),
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        isEdit ? 'Notu Düzenle' : 'Not Oluştur',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Kapat',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------- Başlık ----------
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: InputDecoration(
                            labelText: 'Başlık',
                            border: inputBorder,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: BorderSide(
                                color: cs.primary,
                                width: 1.4,
                              ),
                            ),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withOpacity(
                              0.25,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            // Başlık temizleme butonu (X)
                            suffixIcon: _titleCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    tooltip: 'Başlığı temizle',
                                    onPressed: _clearTitle,
                                  ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),

                        // ---------- İçerik ----------
                        Stack(
                          children: [
                            TextFormField(
                              controller: _contentCtrl,
                              decoration: InputDecoration(
                                labelText: 'İçerik',
                                alignLabelWithHint: true,
                                border: inputBorder,
                                enabledBorder: inputBorder,
                                focusedBorder: inputBorder.copyWith(
                                  borderSide: BorderSide(
                                    color: cs.primary,
                                    width: 1.4,
                                  ),
                                ),
                                filled: true,
                                fillColor: cs.surfaceContainerHighest
                                    .withOpacity(0.2),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                // ÖNEMLİ: suffixIcon YOK, alan daralmıyor
                              ),
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              minLines: 10,
                            ),

                            // Sağ üst köşede küçük çöp ikonu
                            if (_contentCtrl.text.isNotEmpty)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  tooltip: 'İçeriği temizle',
                                  onPressed: _clearContentWithConfirm,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        Divider(
                          thickness: 0.7,
                          color: cs.outline.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),

                        // ---------- AI alanı ----------
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bolt, size: 18, color: cs.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'AI yardımı',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mod seç:'
                                '\n• Otomatik: Duruma göre en uygun öneri'
                                '\n• Düzenle: Yazdığın metni düzelt / zenginleştir'
                                '\n• Liste: Madde madde içerikleri derli toplu hale getir'
                                '\n• Başlıktan: İçerik yazmadan, sadece başlığa göre öneri üret',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.75),
                                ),
                              ),
                              const SizedBox(height: 12),

                              SegmentedButton<String>(
                                segments: modeLabels.entries
                                    .map(
                                      (e) => ButtonSegment<String>(
                                        value: e.key,
                                        label: Text(e.value),
                                      ),
                                    )
                                    .toList(),
                                selected: <String>{_aiMode},
                                showSelectedIcon: false,
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                onSelectionChanged: (set) {
                                  if (set.isEmpty) return;
                                  setState(() {
                                    _aiMode = set.first;
                                  });
                                },
                              ),

                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _loadingAi
                                          ? null
                                          : _runAiSuggestion,
                                      icon: const Icon(
                                        Icons.auto_awesome,
                                        size: 18,
                                      ),
                                      label: const Text('AI önerisi getir'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (_aiPreview != null)
                                    Expanded(
                                      child: TextButton(
                                        onPressed: _applyAiToContent,
                                        child: const Text(
                                          'Öneriyi içeriğe uygula',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              // Yeni satır: Başlık üret + kısa özet ekle
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: _loadingAi
                                          ? null
                                          : _generateTitleWithAi,
                                      icon: const Icon(
                                        Icons.title,
                                        size: 18,
                                      ),
                                      label: const Text('Başlık üret'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: _loadingAi
                                          ? null
                                          : _insertSummaryWithAi,
                                      icon: const Icon(
                                        Icons.short_text,
                                        size: 18,
                                      ),
                                      label: const Text('Kısa özet ekle'),
                                    ),
                                  ),
                                ],
                              ),

                              if (_loadingAi) ...[
                                const SizedBox(height: 12),
                                const LinearProgressIndicator(),
                              ],
                              if (_aiError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _aiError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.error,
                                  ),
                                ),
                              ],

                              // Özet önizleme
                              if (_aiPreview?.summary.isNotEmpty == true) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'AI özet önizleme',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _aiPreview!.summary,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],

                              // Önerilen tam içerik
                              if (_aiPreview?.suggestedContent != null &&
                                  _aiPreview!.suggestedContent!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'AI içerik önerisi',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cs.surface.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _aiPreview!.suggestedContent!.trim(),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],

                              // Tag ve keyword chipleri
                              if ((_aiPreview?.tags.isNotEmpty ?? false) ||
                                  keywords.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'AI etiket & anahtar kelimeler',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    ...(_aiPreview?.tags ?? const <String>[])
                                        .take(8)
                                        .map(
                                          (t) => Chip(
                                            label: Text(
                                              t,
                                              style: theme.textTheme.labelSmall,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                    ...keywords
                                        .take(6)
                                        .map(
                                          (t) => Chip(
                                            label: Text(
                                              t,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(color: cs.primary),
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            side: BorderSide(
                                              color: cs.primary.withOpacity(
                                                0.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Vazgeç'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          final title = _titleCtrl.text.trim();
                          final content = _contentCtrl.text.trim();
                          Navigator.pop(context, (title, content));
                        },
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
