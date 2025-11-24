// lib/presentation/pages/notes/notes_page.dart
// ignore_for_file: deprecated_member_use, unnecessary_underscores, use_build_context_synchronously, unused_local_variable

import 'package:app_to_note/presentation/cubits/auth/auth_cubit.dart';
import 'package:app_to_note/presentation/cubits/offline/offline_queqe_cubit.dart';
import 'package:app_to_note/presentation/cubits/offline/offline_queqe_state.dart';
import 'package:app_to_note/presentation/pages/notes/ai_search_page.dart';
import 'package:app_to_note/presentation/pages/notes/note_card.dart';
import 'package:app_to_note/presentation/pages/notes/note_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../cubits/notes/notes_cubit.dart';
import '../../cubits/notes/notes_state.dart';
import '../../../domain/models/note.dart';
import '../../widgets/sync_indicator.dart';
import 'note_editor_sheet.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

// AppBar overflow menüsü için aksiyon tipleri
enum _NotesMenuAction { aiSearch, search, togglePinned, openTrash }

class _NotesPageState extends State<NotesPage> {
  final _scrollCtrl = ScrollController();
  int _lastQueue = 0;

  // Çoklu seçim
  bool _selectMode = false;
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();

    _scrollCtrl.addListener(() {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      final cur = _scrollCtrl.position.pixels;
      if (max - cur < 300) {
        try {
          context.read<NotesCubit>().fetchMore();
        } catch (_) {}
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final cubit = context.read<NotesCubit>();
        final st = cubit.state;
        final shouldBootstrap =
            st.status != NotesStatus.loading && st.visibleNotes.isEmpty;
        if (shouldBootstrap) {
          try {
            cubit.bootstrap();
          } catch (_) {
            cubit.refresh();
          }
        } else {
          cubit.refresh();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _enterSelectMode([String? id]) {
    setState(() {
      _selectMode = true;
      _selected.clear();
      if (id != null) _selected.add(id);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  void _toggleOne(String id) {
    setState(() {
      if (_selected.remove(id)) {
        if (_selected.isEmpty) _selectMode = false;
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll(List<Note> list) {
    setState(() {
      _selectMode = true;
      _selected
        ..clear()
        ..addAll(list.map((e) => e.id));
    });
  }

  Future<void> _bulkDelete(NotesCubit cubit) async {
    if (_selected.isEmpty) return;
    final ids = _selected.toList();
    for (final id in ids) {
      await cubit.softDelete(id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${ids.length} not çöp kutusuna taşındı')),
    );
    _exitSelectMode();
  }

  // ---------------- APP BAR ----------------

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    NotesState state,
    NotesCubit cubit,
    List<Note> visibleList,
  ) {
    if (_selectMode) {
      final selectedCount = _selected.length;
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectMode,
        ),
        title: Text('$selectedCount seçildi'),
        actions: [
          TextButton.icon(
            onPressed: () => _selectAll(visibleList),
            icon: const Icon(Icons.select_all),
            label: const Text('Tümünü Seç'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _bulkDelete(cubit),
          ),
        ],
      );
    }

    final noteCountText = visibleList.isEmpty
        ? 'Not yok'
        : '${visibleList.length} not';

    return AppBar(
      titleSpacing: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
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
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
          ),
        ],
      ),
      actionsIconTheme: const IconThemeData(color: Colors.black54, size: 20),

      // Başlık + ikon
      title: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset('assets/logo.png', width: 21, height: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notlar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  noteCountText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),

      // Sağ ikonlar: (X) Temizle + Menü + Çıkış + Sync
      actions: [
        if (state.query.isNotEmpty)
          _compactIcon(
            tooltip: 'Temizle',
            icon: Icons.clear,
            onTap: () => cubit.setQuery(''),
          ),
        PopupMenuButton<_NotesMenuAction>(
          tooltip: 'Menü',
          icon: Row(
            children: const [
              Icon(Icons.arrow_drop_down_circle_outlined, size: 19),
              SizedBox(width: 4),
              Text('Menü', style: TextStyle(fontSize: 19)),
            ],
          ),
          onSelected: (action) async {
            switch (action) {
              case _NotesMenuAction.aiSearch:
                final selectedTitle = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const AISearchPage()),
                );
                if (!context.mounted) return;
                if (selectedTitle != null && selectedTitle.trim().isNotEmpty) {
                  context.read<NotesCubit>().setQuery(selectedTitle.trim());
                }
                break;

              case _NotesMenuAction.search:
                final result = await showSearch<String?>(
                  context: context,
                  delegate: NoteSearchDelegate(
                    state.notes,
                    initial: state.query,
                  ),
                );
                cubit.setQuery(result ?? '');
                break;

              case _NotesMenuAction.togglePinned:
                cubit.togglePinnedOnly();
                break;

              case _NotesMenuAction.openTrash:
                Navigator.of(context).pushNamed('/trash');
                break;
            }
          },
          itemBuilder: (context) {
            final items = <PopupMenuEntry<_NotesMenuAction>>[];

            items.add(
              const PopupMenuItem(
                value: _NotesMenuAction.aiSearch,
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14),
                    SizedBox(width: 8),
                    Text('Yapay zeka ile ara', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            );
            items.add(
              const PopupMenuItem(
                value: _NotesMenuAction.search,
                child: Row(
                  children: [
                    Icon(Icons.search, size: 14),
                    SizedBox(width: 8),
                    Text('Notlarda ara', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            );
            items.add(
              PopupMenuItem(
                value: _NotesMenuAction.togglePinned,
                child: Row(
                  children: [
                    Icon(
                      state.pinnedOnly
                          ? Icons.push_pin_outlined
                          : Icons.push_pin,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.pinnedOnly
                          ? 'Tüm notları göster'
                          : 'Sadece sabitli notlar',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
            items.add(
              const PopupMenuItem(
                value: _NotesMenuAction.openTrash,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 14),
                    SizedBox(width: 8),
                    Text('Çöp kutusu', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            );

            return items;
          },
        ),
        const SizedBox(width: 4),
        _compactIcon(
          tooltip: 'Çıkış Yap',
          icon: Icons.logout,
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Çıkış yapılsın mı?'),
                content: const Text(
                  'Hesabınızdan çıkış yapılacak. Emin misiniz?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Vazgeç'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Çıkış'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await context.read<NotesCubit>().clearForSignOut();
              await context.read<AuthCubit>().logout();
            }
          },
        ),
        const Padding(
          padding: EdgeInsets.only(right: 6),
          child: SyncIndicator(),
        ),
      ],
    );
  }

  // Küçük ve sıkı ikon butonu
  Widget _compactIcon({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: Colors.white.withOpacity(0.28),
        shape: BoxShape.rectangle,
        backgroundBlendMode: BlendMode.softLight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.10),
        child: Tooltip(
          message: tooltip,
          child: IconButton(
            icon: Icon(icon, size: 19),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  // ---------------- SWIPE BACKGROUND + NOTE ITEM ----------------

  Widget _buildSwipeBackground(BuildContext context, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.delete_outline,
        color: Colors.redAccent.withOpacity(0.9),
      ),
    );
  }

  Widget _buildNoteItem({
    required BuildContext context,
    required Note note,
    required NotesCubit cubit,
  }) {
    Future<void> handleDelete() async {
      final removed = await cubit.softDelete(note.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silindi'),
          action: SnackBarAction(
            label: 'GERİ AL',
            onPressed: () => cubit.restore(note.id, fallback: removed),
          ),
        ),
      );
    }

    return Dismissible(
      key: ValueKey(note.id),
      direction: _selectMode
          ? DismissDirection.none
          : DismissDirection.horizontal,
      background: _buildSwipeBackground(context, Alignment.centerLeft),
      secondaryBackground: _buildSwipeBackground(
        context,
        Alignment.centerRight,
      ),
      onDismissed: (_) => handleDelete(),
      child: NoteCard(
        note: note,
        selectMode: _selectMode,
        selected: _selected.contains(note.id),
        onLongPressSelect: () => _enterSelectMode(note.id),
        onToggleSelect: () => _toggleOne(note.id),
        onUpdatePinned: (val) => cubit.update(note, pinned: val),
        onDelete: handleDelete,
        onEdit: (title, content) =>
            cubit.update(note, title: title, content: content),
      ),
    );
  }

  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineQueueCubit, OfflineQueueState>(
      listenWhen: (p, n) =>
          p.queue.length != n.queue.length || p.online != n.online,
      listener: (context, s) {
        if (_lastQueue > 0 && s.queue.isEmpty && s.online) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tüm değişiklikler senkronize edildi ✅'),
            ),
          );
        }
        _lastQueue = s.queue.length;
      },
      child: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          final cubit = context.read<NotesCubit>();
          final list = state.visibleNotes;
          final pinned = list.where((n) => n.pinned).toList();
          final others = list.where((n) => !n.pinned).toList();
          final offline = context.select<OfflineQueueCubit, bool>(
            (c) => !c.state.online,
          );

          Future<void> handleRefresh() async {
            try {
              await context.read<OfflineQueueCubit>().processAll();
            } catch (_) {}
            await cubit.refresh();
            await Future<void>.delayed(const Duration(milliseconds: 80));
          }

          final Widget contentChild;
          if (list.isEmpty) {
            contentChild = ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: const [
                SizedBox(height: 240),
                Center(child: Text('Henüz not yok')),
                SizedBox(height: 80),
              ],
            );
          } else {
            contentChild = ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: (pinned.isNotEmpty
                  ? 1 +
                        pinned.length +
                        (others.isNotEmpty ? 1 + others.length : 0)
                  : others.length),
              itemBuilder: (context, index) {
                int i = 0;
                if (pinned.isNotEmpty) {
                  if (index == i) {
                    return const _SectionHeader('Sabitlenmiş Notlar');
                  }
                  i++;
                  if (index < i + pinned.length) {
                    final n = pinned[index - i];
                    return _buildNoteItem(
                      context: context,
                      note: n,
                      cubit: cubit,
                    );
                  }
                  i += pinned.length;
                  if (others.isNotEmpty) {
                    if (index == i) {
                      return const _SectionHeader('Tüm notlar');
                    }
                    i++;
                    final n = others[index - i];
                    return _buildNoteItem(
                      context: context,
                      note: n,
                      cubit: cubit,
                    );
                  }
                } else {
                  final n = others[index];
                  return _buildNoteItem(
                    context: context,
                    note: n,
                    cubit: cubit,
                  );
                }
                return const SizedBox.shrink();
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
            );
          }

          return Scaffold(
            appBar: _buildAppBar(context, state, cubit, list),
            body: Container(
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
              child: Column(
                children: [
                  if (offline)
                    MaterialBanner(
                      elevation: 0,
                      backgroundColor: Colors.orange.withOpacity(.12),
                      contentTextStyle: const TextStyle(color: Colors.black54),
                      content: const Text(
                        'Çevrimdışı: Değişiklikler kuyruğa alınacak ve bağlantı gelince senkronize edilecek.',
                      ),
                      actions: const [SizedBox.shrink()],
                    ),
                  Expanded(
                    child: LiquidPullToRefresh(
                      onRefresh: handleRefresh,
                      showChildOpacityTransition: false,
                      child: contentChild,
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: _selectMode
                ? null
                : FloatingActionButton(
                    onPressed: () async {
                      final res = await showNoteEditorBottomSheet(context);
                      if (res != null) {
                        await cubit.create(res.$1, res.$2);
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
