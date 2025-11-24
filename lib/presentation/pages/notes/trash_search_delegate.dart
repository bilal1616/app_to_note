// ignore_for_file: deprecated_member_use, unnecessary_underscores

import 'package:flutter/material.dart';
import '../../../domain/models/note.dart';

/// TrashPage için, NotesPage ile aynı renk paletini kullanan SearchDelegate
class TrashSearchDelegate extends SearchDelegate<String?> {
  final List<Note> items;

  TrashSearchDelegate(this.items, {String initial = ''}) {
    query = initial;
  }

  @override
  String get searchFieldLabel => 'Search';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, query),
      );

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final s = query.toLowerCase();
    final suggestions = s.isEmpty
        ? items
        : items.where(
            (n) =>
                n.title.toLowerCase().contains(s) ||
                n.content.toLowerCase().contains(s),
          );

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
          return _SearchTrashCard(
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

class _SearchTrashCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _SearchTrashCard({
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outline.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
              Text(
                note.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
