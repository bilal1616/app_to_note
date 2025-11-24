// ignore_for_file: deprecated_member_use, unnecessary_underscores

import 'package:flutter/material.dart';
import '../../../domain/models/note.dart';

/// NotesPage ile aynı renk ve kart yapısını kullanan SearchDelegate
class NoteSearchDelegate extends SearchDelegate<String?> {
  final List<Note> items;

  NoteSearchDelegate(this.items, {String initial = ''}) {
    query = initial;
  }

  @override
  String get searchFieldLabel => 'Search';

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, query),
  );

  @override
  Widget buildResults(BuildContext context) {
    // sonuç seçildiğinde sadece query ile geri dönüyoruz
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final s = query.toLowerCase();
    final suggestions = s.isEmpty
        ? items
        : items.where((n) {
            final title = n.title.toLowerCase();
            final content = n.content.toLowerCase();
            final summary = (n.aiSummary ?? '').toLowerCase();
            final tags = (n.aiTags).map((t) => t.toLowerCase()).toList();

            final inTags = tags.any((t) => t.contains(s));

            return title.contains(s) ||
                content.contains(s) ||
                summary.contains(s) ||
                inTags;
          });

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(70, 238, 180, 34),
            Color.fromARGB(160, 220, 210, 200),
            Color.fromARGB(70, 238, 180, 34),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final n = suggestions.elementAt(i);
          return _SearchNoteCard(
            note: n,
            onTap: () {
              query = n.title;
              close(context, query);
            },
          );
        },
      ),
    );
  }
}

class _SearchNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _SearchNoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color.fromARGB(255, 207, 207, 207)
        : Colors.white70;

    final hasAiSummary =
        note.aiSummary != null && note.aiSummary!.trim().isNotEmpty;
    final previewText = hasAiSummary
        ? note.aiSummary!.trim()
        : note.content.trim();

    final tags = note.aiTags;

    return GestureDetector(
      onTap: onTap,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isEmpty ? '(untitled)' : note.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (hasAiSummary)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'AI özeti',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                previewText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: hasAiSummary ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
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
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: colorScheme.primary.withOpacity(0.08),
                      side: BorderSide(
                        color: colorScheme.primary.withOpacity(0.18),
                        width: 0.6,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
