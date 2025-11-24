// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../data/repositories/ai_search_repository.dart';
import '../../../domain/models/note.dart';

class AISearchPage extends StatefulWidget {
  const AISearchPage({super.key});

  @override
  State<AISearchPage> createState() => _AISearchPageState();
}

class _AISearchPageState extends State<AISearchPage> {
  final _queryCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  final _repo = AISearchRepository();

  bool _loading = false;
  String? _error;
  List<Note> _results = <Note>[];

  /// Sadece UI için: son kullanılan sorgular & tag’ler (session-level)
  final List<String> _recentQueries = <String>[];
  final List<String> _recentTags = <String>[];

  @override
  void dispose() {
    _queryCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _updateRecents({required String query, String? tag}) {
    String q = query.trim();
    String? t = tag?.trim();

    void push(List<String> list, String value) {
      if (value.isEmpty) return;
      // aynı değeri (case-insensitive) varsa sil → en başa ekle
      list.removeWhere((e) => e.toLowerCase() == value.toLowerCase());
      list.insert(0, value);
      if (list.length > 6) {
        list.removeRange(6, list.length);
      }
    }

    push(_recentQueries, q);
    if (t != null && t.isNotEmpty) {
      push(_recentTags, t);
    }
  }

  Future<void> _runSearch() async {
    final query = _queryCtrl.text.trim();
    final rawTag = _tagCtrl.text.trim();
    final tag = rawTag.isEmpty ? null : rawTag;

    // 🔹 Hem query hem tag boşsa: hata
    if (query.isEmpty && tag == null) {
      setState(() {
        _error = 'Bir sorgu ve/veya tag yazıp "AI ile ara" butonuna bas.';
        _results = <Note>[];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notes = await _repo.searchNotes(
        queryText: query, // boş string olabilir
        tagFilter: tag,
        limit: 30,
      );

      setState(() {
        _results = notes;
        _updateRecents(query: query, tag: tag);
      });
    } catch (e) {
      setState(() {
        _error = 'AI arama başarısız oldu: $e';
        _results = <Note>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _buildShimmerList(ThemeData theme, ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Shimmer.fromColors(
            baseColor: cs.surfaceVariant.withOpacity(0.4),
            highlightColor: cs.surface.withOpacity(0.9),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 140,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                        child: Container(
                          height: 22,
                          width: 70,
                          decoration: BoxDecoration(
                            color: cs.surfaceVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultList(ThemeData theme, ColorScheme cs) {
    if (_results.isEmpty) {
      return Center(
        child: Text(
          _loading
              ? 'AI arama yapılıyor...'
              : 'Henüz sonuç yok. Bir sorgu ve/veya tag yazıp "AI ile ara" butonuna bas.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final n = _results[index];

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // 🔹 NotesPage'e geri dön ve seçilen notun başlığını gönder
            Navigator.of(context).pop<String>(n.title);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if ((n.aiSummary ?? '').isNotEmpty)
                    Text(
                      n.aiSummary!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      n.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  if (n.aiTags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: n.aiTags
                          .take(8)
                          .map(
                            (t) => Chip(
                              label: Text(t, style: theme.textTheme.labelSmall),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI ile not ara')),
      body: SafeArea(
        child: Column(
          children: [
            // Üst kısım: query + tag filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sorgu cümlesi', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _queryCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Örn: Supabase entegrasyonu ile ilgili notlar',
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _runSearch(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tag filtresi (opsiyonel)',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Örn: Supabase, AI Entegrasyonu...',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _runSearch(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _runSearch,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('AI ile ara'),
                    ),
                  ),

                  // ---- Son aramalar & Önerilen tag'ler ----
                  if (_recentQueries.isNotEmpty || _recentTags.isNotEmpty)
                    const SizedBox(height: 12),
                  if (_recentQueries.isNotEmpty) ...[
                    Text(
                      'Son aramalar',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _recentQueries
                          .map(
                            (q) => ActionChip(
                              label: Text(q),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onPressed: () {
                                _queryCtrl.text = q;
                                _queryCtrl.selection = TextSelection.collapsed(
                                  offset: q.length,
                                );
                                _runSearch();
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_recentTags.isNotEmpty) ...[
                    Text(
                      'Önerilen tag\'ler',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _recentTags
                          .map(
                            (t) => ActionChip(
                              label: Text(t),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onPressed: () {
                                _tagCtrl.text = t;
                                _tagCtrl.selection = TextSelection.collapsed(
                                  offset: t.length,
                                );
                                _runSearch();
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (_loading) const LinearProgressIndicator(),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Sonuç / shimmer listesi
            Expanded(
              child: _loading && _results.isEmpty
                  ? _buildShimmerList(theme, cs)
                  : _buildResultList(theme, cs),
            ),
          ],
        ),
      ),
    );
  }
}
